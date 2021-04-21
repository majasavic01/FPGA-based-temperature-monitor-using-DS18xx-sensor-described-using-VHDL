library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity DS18xx is
port
(
  clk             : IN STD_LOGIC;
  enable			   : IN		STD_LOGIC;  -- pojavljuje se sa frekvencijom od 1 MHz, tj 1us
  crc_en				: OUT		STD_LOGIC;
  dataOut			: OUT		STD_LOGIC_VECTOR(71 downto 0);
  ds_data_bus		: INOUT	STD_LOGIC;
  config_data     : OUT    STD_LOGIC_VECTOR(7 downto 0);
  precision_input : IN     STD_LOGIC_VECTOR(1 downto 0);
  power           : in     std_logic
);
end DS18xx;

architecture Behavioral of DS18xx is

-- stanja FSM
TYPE STATE_TYPE is (WAIT_CONVERSION_TIME,INITIALIZATION_SEQUENCE, PRESENCE, SEND, WRITE_BYTE, WRITE_LOW, WRITE_HIGH, GET_DATA, READ_BIT,WRITE_TH_TL_CONFIG,WRITE_HIGH_TH_TL_CONFIG,WRITE_LOW_TH_TL_CONFIG);
-- trenutno stanje FSM
SIGNAL state: STATE_TYPE;

-- citanje podataka iz scratchpad memorije  senzora, velicina je 9 bajtova
SIGNAL data	: STD_LOGIC_VECTOR(71 downto 0);

-- reset tajmera
SIGNAL reset_timer	: STD_LOGIC;

-- i broji mikrosekunde
SIGNAL i			: INTEGER RANGE 0 TO 799999;    -- za wait ms

--    instrukcija koja se salje u senzor
SIGNAL write_command : STD_LOGIC_VECTOR(7 downto 0);
SIGNAL insert_in_sensor : STD_LOGIC_VECTOR(23 downto 0);
SIGNAL th_vector : std_logic_vector(7 downto 0);
SIGNAL tl_vector : std_logic_vector(7 downto 0);
SIGNAL config_vector : std_logic_vector(7 downto 0);
SIGNAL old_precision :std_logic_vector(1 downto 0);
 -- signal prisustva senzora na magirstrali
SIGNAL presence_signal		: STD_LOGIC;

SIGNAL WRITE_BYTE_CNT	: INTEGER RANGE 0 TO 8	:= 0;	-- indeks bita koji se upisuje 
SIGNAL write_low_flag	: INTEGER RANGE 0 TO 2	:= 0;	
SIGNAL write_high_flag	: INTEGER RANGE 0 TO 2	:= 0;	
SIGNAL read_bit_flag		: INTEGER RANGE 0 TO 3	:= 0;
SIGNAL GET_DATA_CNT		: INTEGER RANGE 0 TO 72	:= 0;	-- indeks bita koji se cita
SIGNAL WRITE_TH_TL_CONFIG_CNT :INTEGER RANGE 0 TO 24 :=0;-- indeks bita koji se upisuje za th tl config u memoriju senzora
SIGNAL clock_1mhz       :STD_LOGIC_VECTOR(2 downto 0);
SIGNAL power_ds18xx     :STD_LOGIC_VECTOR(2 downto 0); 

begin
	
	process(clk)   -- sa osnovnim klokom 50MHz radi
	
 
	CONSTANT PRESENCE_ERROR_DATA	: STD_LOGIC_VECTOR(71 downto 0):= "101010101010101010101010101010101010101010101010101010101010101010101010";

	VARIABLE bit_cnt	: INTEGER RANGE 0 TO 71;	-- indeks prilikom citanja podataka iz senzora
	VARIABLE flag		: INTEGER RANGE 0 TO 12;	-- da znamo koje je sledeca komanda koja se salje senzoru
	VARIABLE is_th_tl_config : INTEGER :=0;   	-- pokazijue da nije konfigurisan th,th,config
	VARIABLE is_copy_to_EPROM : INTEGER :=0;   	-- pokazijue da nije kopirano u eprom


	begin
	-- 0xy11111 -- ovako mora biti samo x i y se mijenja za preciznost, 00-9, 01-10, 10-11, 11-12													
	config_vector<="0"&precision_input&"11111";
	th_vector<=    "01111000";   --  120  proizvoljno
	tl_vector<=    "00000000";   --  0  
	
	if rising_edge(clk) then
		
		--power_ds18xx<=(power_ds18xx(power_ds18xx'left-1 downto 0))& (power);
		--if (power_ds18xx(power_ds18xx'left downto power_ds18xx'left-1)="01") then -- na rastucu ivicu od power koji salje on_of_ds18xx
		if power='1' then                            -- ako je omoguceno mjerenje, tj ako je senzor upaljen
		
		clock_1mhz<=(clock_1mhz(clock_1mhz'left-1 downto 0))& (enable);
		if (clock_1mhz(clock_1mhz'left downto clock_1mhz'left-1)="01") then
			
			if(old_precision /=precision_input) then     -- provjera da li se desila promjenja preciznosti
				is_th_tl_config:=0;								-- pa da omoguci ulazak u dio koji postavlja preciznost
				is_copy_to_EPROM:=0;								-- i kopira je u eprom
				config_vector<="0"&precision_input&"11111";
				end if;
			
			case	state is
				when INITIALIZATION_SEQUENCE =>																
					reset_timer <= '0';													-- prilikom inicijalizacije 
					if (i = 0) then 
						ds_data_bus <= '0';												--	master salje 485 us nizak logicki nivo
					elsif (i = 485) then 
						ds_data_bus <= 'Z';												-- nakon toga master prima 15-60 us visok nivo, pa 
					elsif (i = 550) then      
						presence_signal <= ds_data_bus;								-- senzor salje signal prisustva (koji traje 60-240 us)
					elsif (i = 1000) then 
						state <= PRESENCE;												-- nakon 1000 us inicijalizacija je zavrsena
					end if;
			
				when PRESENCE =>															
					-- kad je senzor detektovan na magistrali
					if (presence_signal = '0' and ds_data_bus = '1') then		-- senzor je detektovan na magistrali
						reset_timer <= '1';												-- reset brojac vremena
						state	  <= SEND;													-- inicijalizacija zavrsena, prelazimo u SEND
					else																		-- senzor nije detektovan
						reset_timer	<= '1';												-- reset brojac vremena
						dataOut 	<= PRESENCE_ERROR_DATA;								-- salje se indikator greske
						crc_en	<= '1';													-- CRC je omogucen
						state		<= WAIT_CONVERSION_TIME;							-- ceka se 800ms
					end if;

				when SEND =>																-- slanje komande senzoru 
					-- pomocu flag pravim redoslijed sledece operacije
					if (flag = 0) then												   
						flag := 1;
						write_command <="11001100"; 	                        -- prikaz CCh - SKIP ROM 
						state 		  <= WRITE_BYTE;									-- upisujemo (saljemo) komandu u WRITE BYTE
					elsif (flag = 1 and is_th_tl_config=0) then	            -- ako nije konfigurisan th,tl,config onda konfigurisemo												
						old_precision<=precision_input;
						flag := 2;
						write_command <="01001110";    	                     --  4Eh - write comand za tl,th, config
						is_th_tl_config:=1;                                   -- podeseni th tl i congif i ne ulazi ovdje vise
						state <=WRITE_BYTE;
					elsif(flag=2) then
						flag:=12;
						state 		  <= WRITE_TH_TL_CONFIG;                  -- prelazimo u stanje za upis ove komande  				
					elsif(flag=12) then
						flag:=3;
						state <=INITIALIZATION_SEQUENCE;                      -- nakon upisa opet slijedi inicijalizacija
					elsif(flag=3) then
					flag :=4;
					write_command<="11001100" ;                              -- skip ROM ponovo nakon inicijalizacije zbog upisa tl th config
					state			  <= WRITE_BYTE;	
					elsif((flag=1 or flag=4) and is_copy_to_EPROM=0) then    -- kopiranje u EPROM nakod podesavanja parametara da se ne gube pretankom napajanja
						flag :=5;                                            
						is_copy_to_EPROM :=1;
						write_command <="01001000";                           -- 48h- copy scratchpad  
						state<=WRITE_BYTE;
					elsif(flag=5) then 
						flag:=6;
						state <=INITIALIZATION_SEQUENCE;                       -- opet INICIJALIZACIJA nakon kopiranja u EPROM
					elsif(flag=6) then
						flag:=7;
						write_command<="11001100" ;                            -- skip ROM ponovo inicijalizacija kopiranja
						state			  <= WRITE_BYTE;
					elsif (flag = 1 or flag=7) then	 -- nakon podesenih parametara i upisanih u EPROM slijedi mjerenje temperature				
						flag := 8;
						write_command <="01000100";                           --  44h - CONVERT TEMPERATURE
						state 		  <= WRITE_BYTE;									
					elsif (flag = 8) then
						flag := 9;	
						state <= WAIT_CONVERSION_TIME; 								--treba da saceka 100/190/380/750ms nakom 44h (datasheet)
					elsif (flag = 9) then												-- u WAIT odradjena inicijalizacija pa ne treba opet
						flag := 10;
						write_command <="11001100";                           --  CCh - SKIP ROM
						state			  <= WRITE_BYTE;									
					elsif (flag = 10) then				                        -- nakon mjerenja se rezultati citaju  								
						flag := 11;
						write_command <="10111110";                           --  BEh - READ SCRATCHPAD
						state			  <= WRITE_BYTE;									
					elsif (flag = 11) then												-- nakon izdane komande READ potrebno je podatke sa magistrale prihvatiti
						flag := 0;															
						state <= GET_DATA;												-- a to se radi u  GET_DATA, i postupak se ponavlja
					end if;

				when  WAIT_CONVERSION_TIME =>											
					CRC_en <= '0';															--  CRC se onemogucava
					reset_timer <= '0';												
					if (precision_input="00") then
						if(i=100000)  then--  ~= 100ms
							reset_timer <='1';														
							state	  <= INITIALIZATION_SEQUENCE;													
						end if;
					elsif (precision_input="01") then
						if(i=190000) then --  ~= 190ms
							reset_timer <='1';														
							state	  <= INITIALIZATION_SEQUENCE;													
						end if;
					elsif (precision_input="10") then
						if(i=380000) then --  ~= 380ms
							reset_timer <='1';														
							state	  <= INITIALIZATION_SEQUENCE;													
						end if;
					elsif (i = 799999) then --tacno 800ms				         -- nakon isteka resetuje se i prelazi u stanje RESET
						reset_timer <='1';														
						state	  <= INITIALIZATION_SEQUENCE;													
					end if;

				when GET_DATA =>															
					case GET_DATA_CNT is			                              -- BEh - READ SCRATCHPAD  cita 9 bajtova iz										
						when 0 to 71=>														-- memorije uredjaja, tj 72 bita
							ds_data_bus  <= '0';											
							GET_DATA_CNT <= GET_DATA_CNT + 1;						-- pa 72 puta idemo u READ_BIT
							state 		 <= READ_BIT;									
						when 72=>															
							bit_cnt := 0;													
							GET_DATA_CNT <=0;												
							dataOut 	 <= data(71 downto 0);							
							CRC_en 		 <= '1';											
							state 		 <= WAIT_CONVERSION_TIME;					
						when others =>	 													
							read_bit_flag <= 0;											
							GET_DATA_CNT  <= 0; 											
					end case;

				when READ_BIT =>															
				
					case read_bit_flag is												
						when 0=>																
							read_bit_flag <= 1;
						when 1=>																
							ds_data_bus <= 'Z';											
							reset_timer 		<= '0';											
							if (i = 13) then												
								reset_timer		 <= '1';										
								read_bit_flag <= 2;
							end if; 
						when 2=>																
							data(bit_cnt)	<= ds_data_bus;							
							bit_cnt := bit_cnt + 1;										
							read_bit_flag	<= 3;
						when 3=>																
							reset_timer <= '0';												
							if (i = 63) then												
								reset_timer<='1';											
								read_bit_flag <= 0;										
								state 		  <= GET_DATA;								
							end if;
						when others => 													
							read_bit_flag <= 0;											
							bit_cnt		  := 0;											
							GET_DATA_CNT  <= 0;											
							state			  <= INITIALIZATION_SEQUENCE;										
					end case;

				when WRITE_BYTE =>														
					
					case WRITE_BYTE_CNT is												
						when 0 to 7=>														
							if (write_command(WRITE_BYTE_CNT) = '0') then	
								state <= WRITE_LOW; 										
							else																
								state <= WRITE_HIGH;										
							end if;
							WRITE_BYTE_CNT <= WRITE_BYTE_CNT + 1;					
						when 8=>																
							WRITE_BYTE_CNT <= 0;											
                		state				<= SEND;																
						when others=>														
							WRITE_BYTE_CNT  <= 0;										
							write_low_flag  <= 0;										
							write_high_flag <= 0;										
							state <= INITIALIZATION_SEQUENCE;						
						end case;
				
				when WRITE_TH_TL_CONFIG =>  
				
					insert_in_sensor <=config_vector & tl_vector & th_vector;
					case WRITE_TH_TL_CONFIG_CNT is
						
						when 0 to 23 =>  
							if(insert_in_sensor(WRITE_TH_TL_CONFIG_CNT)='0') then   
								state <=WRITE_LOW_TH_TL_CONFIG;
							else
								state <=WRITE_HIGH_TH_TL_CONFIG;
							end if;
							WRITE_TH_TL_CONFIG_CNT<=WRITE_TH_TL_CONFIG_CNT+1;      
						
						when 24 =>
							WRITE_TH_TL_CONFIG_CNT <= 0;
							state <=SEND;              
						when others =>
							WRITE_TH_TL_CONFIG_CNT<=0;
							write_low_flag<=0;
							write_high_flag <=0;
							config_data(5)<='1';
							state <=INITIALIZATION_SEQUENCE;   
					end case;
					
			-------------------------------------
				when WRITE_LOW_TH_TL_CONFIG =>					-- UPIS logicke NULE u th,tl,config registar							
					case write_low_flag is							-- isto kao upis za komande s tim da se ovdje ne vraca					
						when 0=>											-- u WRITE_BYTE vec u	WRITE_TH_TL_CONFIG					
							ds_data_bus <= '0';											
							reset_timer 		<= '0';									
							if (i = 59) then												
								reset_timer		   <='1';								
								write_low_flag <= 1;
							end if;
						when 1=>																
							ds_data_bus <= 'Z';											
							reset_timer 		<= '0';									
							if (i = 3) then												
								reset_timer 		   <= '1';							
								write_low_flag <= 2;
							end if;
						when 2=>																
							write_low_flag <= 0;											
							state 		   <= WRITE_TH_TL_CONFIG;					
						when others=>														
							config_data(7)<='1';
							WRITE_TH_TL_CONFIG_CNT  <= 0;										
							write_low_flag  <= 0;										
							state 		    <= INITIALIZATION_SEQUENCE;								
					end case;	
	-------------------------------------	
	
				when WRITE_HIGH_TH_TL_CONFIG =>	 -- UPIS logicke jedinice u th,tl,config registar
					case write_high_flag is			 -- isto kao upis za komande s tim da se ovdje ne vraca									
						when 0=>							 -- u WRITE_BYTE vec u	WRITE_TH_TL_CONFIG								
							ds_data_bus <= '0';											
							reset_timer <= '0';												
							if (i = 9) then												
								reset_timer 			<= '1';							
								write_high_flag <= 1;
							end if;
						when 1=>																
							ds_data_bus <= 'Z';											
							reset_timer 		<= '0';									
							if (i = 53) then												
								reset_timer			<= '1';								
								write_high_flag <= 2;
							end if;
						when 2=>																
							write_high_flag <= 0;										
							state 			 <= WRITE_TH_TL_CONFIG;					
						when others =>														
							config_data(6)<='1';
							WRITE_TH_TL_CONFIG_CNT  <= 0;								
							write_high_flag <= 0;										
							state 		    <= INITIALIZATION_SEQUENCE;			
					end case;
				
				when WRITE_LOW =>															-- UPISIVANJE LOGICKE NULE (LOW) u DS18xx
					case write_low_flag is												
						when 0=>																-- inicijalizacija upisa LOW bita
							ds_data_bus <= '0';											-- inicijalizacija Master postavlja magistralu nisko
							reset_timer 		<= '0';									-- pocinjemo brojanje vremena od 60 us za Write Slot
							if (i = 60) then												-- cekamo 60 us
								reset_timer	  <='1';										-- resetujemo tajmer 
								write_low_flag <= 1;
							end if;
						when 1=>																
							ds_data_bus <= 'Z';											-- postavljanje magistrale na visok nivo
							reset_timer 		<= '0';									
							if (i = 3) then												-- cekamo 4us da se magistrala stabilicuje( prelazni rezim) 
								reset_timer  <= '1';									   -- reset tajmera
								write_low_flag <= 2;                            -- sad DS18xx odmjerava magistalu(od 15 do 60us) i upisuje 0
							end if;
						when 2=>																-- kraj upisa bita LOW u senzor
							write_low_flag <= 0;											
							state 		   <= WRITE_BYTE;								
						when others=>														
							WRITE_BYTE_CNT  <= 0;										
							write_low_flag  <= 0;										
							state 		    <= INITIALIZATION_SEQUENCE;			-- reset senzor
					end case;
					
				
				when WRITE_HIGH =>														
					case write_high_flag is												
						when 0=>															
							ds_data_bus <= '0';											-- inizijalizacija upisa postavljanjem LOW na magistralu
							reset_timer <= '0';											-- setovanje tajmera
							if (i = 9) then												-- cekanje 10 us
								reset_timer   <= '1';							
								write_high_flag <= 1;
							end if;
						when 1=>																-- postavljanje magistrale na visok nivo
							ds_data_bus <= 'Z';											
							reset_timer 		<= '0';									-- setovanje tajmera
							if (i = 63) then 		-- povecao malo					-- ceka se (60-120 us)
								reset_timer	  <= '1';								
								write_high_flag <= 2;
							end if;
						when 2=>																-- upis HIGH bita zavrsen, reset redoslijed
							write_high_flag <= 0;										-- i povratak u WRITE_BYTE za upis sledeceg bita
							state 			 <= WRITE_BYTE;							-- iz bajta koji se upisuje
						when others =>														
							WRITE_BYTE_CNT  <= 0;										-- reset indeksa bita koji se upisuje 
							write_high_flag <= 0;										-- reset redoslijeda izvrsavanja
							state 		    <= INITIALIZATION_SEQUENCE;			-- reset senzora
					end case;

				when others =>																
					state <= INITIALIZATION_SEQUENCE;								-- reset senzora
					
			end case;
		end if;
	else
		--reset_timer<='0';
		state<=INITIALIZATION_SEQUENCE;
		flag:=0;
	end if;-- end za power
		
	end if;
end process;

	-- postavljanje tajmera, na clk od 1us broji
	process(clk, reset_timer)
	--process(clk)
	
	begin
	if (rising_edge(clk)) then
		if (clock_1mhz(clock_1mhz'left downto clock_1mhz'left-1)="01") then
			if (reset_timer = '1')then		-- ako je reset
				i <= 0;							-- vrati i na 0 	
			else
				i <= i + 1;				      -- na svaku rastucu ivicu clock_1mhz  se uveca i
			end if;
		end if;
	end if;
	end process;

end Behavioral;