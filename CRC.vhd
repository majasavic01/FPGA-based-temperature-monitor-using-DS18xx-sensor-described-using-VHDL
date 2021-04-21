library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity CRC is
    Port (	clk			: IN	STD_LOGIC;
				enable      : IN STD_LOGIC;
				data_en		: IN	STD_LOGIC;
				dataIn 		: IN	STD_LOGIC_VECTOR (71 downto 0);
				dataOut	 	: OUT	STD_LOGIC_VECTOR (15 downto 0);
				dataValid	: OUT STD_LOGIC;
				power       : in std_logic
	 );
end CRC;

architecture Behavioral of CRC is

SIGNAL data : STD_LOGIC_VECTOR(71 downto 0);


TYPE STATE_TYPE IS (IDLE, CRC_CALC, CRC_CHECK);

SIGNAL crc_state: STATE_TYPE;
SIGNAL clock_1mhz : STD_LOGIC_VECTOR(2 downto 0);
signal data_out_old : std_logic_vector(15 downto 0);
begin


	process(clk)
	
	CONSTANT DATA_WIDTH_C	: INTEGER := 72;
	
	VARIABLE i					: integer range 0 to DATA_WIDTH_C := 0;

	VARIABLE CRC_temp			: STD_LOGIC_VECTOR(7 downto 0);
	
	VARIABLE CRC_val			: STD_LOGIC_VECTOR(7 downto 0);
	
	CONSTANT CRC_ERROR_C 		: STD_LOGIC_VECTOR(15 downto 0) := "0111111111111111";

	CONSTANT PRESENCE_ERROR_C 	: STD_LOGIC_VECTOR(15 downto 0) := "0011111111111111";

	CONSTANT PRESENCE_ERROR_DATA_C : STD_LOGIC_VECTOR(71 downto 0) := "101010101010101010101010101010101010101010101010101010101010101010101010";
		
	begin
		
		if (rising_edge(clk)) then
	--	if power='1' then 
				clock_1mhz<=(clock_1mhz(clock_1mhz'left-1 downto 0))& (enable);
			if (clock_1mhz(clock_1mhz'left downto clock_1mhz'left-1)="01") then
				case (crc_state) is
					when IDLE =>											
						dataValid <= '0';									
						if (data_en = '1') then							
							crc_state <= CRC_CALC;
						else 
							dataOut<= data_out_old;   -- ako nije omogucen crc onda drzi staru vrijednost
						end if;

					when CRC_CALC =>										
						if (i < DATA_WIDTH_C) then						
							CRC_temp(7):= dataIn(i) XOR CRC_val(0);
							CRC_temp(2):= CRC_val(3) XOR (dataIn(i) XOR CRC_val(0));
							CRC_temp(3):= CRC_val(4) XOR (dataIn(i) XOR CRC_val(0));
							CRC_val(0) := CRC_val(1);
							CRC_val(1) := CRC_val(2);
							CRC_val(2) := CRC_temp(2);
							CRC_val(3) := CRC_temp(3);
							CRC_val(4) := CRC_val(5);
							CRC_val(5) := CRC_val(6);
							CRC_val(6) := CRC_val(7);
							CRC_val(7) := CRC_temp(7);
							i:=i+1;										
						else
							crc_state <= CRC_CHECK;						
							end if;

					when CRC_CHECK =>										
						if (CRC_val = "00000000") then				
							--dataOut <="0000"& dataIn(23 downto 16)&"0000";
							
							dataOut <= dataIn(15 downto 0);
							--data_out_old<=dataIn(15 downto 0);
						else													
							if (dataIn /= PRESENCE_ERROR_DATA_C) then	
								dataOut <= CRC_ERROR_C; 				
							else
								--dataOut <= PRESENCE_ERROR_C;
									dataOut<=dataIn(15 downto 0);
							end if;
						end if;
						CRC_temp	 := "00000000";						
						CRC_val   := "00000000";						
						i 			 := 0;									
						dataValid <= '1';										
						crc_state <= IDLE;								
				end case;
			end if;
	--	else
		--	dataOut<=data_out_old;  -- da vrati rezultat prethodnog ako nema napajanja;
	--	end if;
		end if;
	end process;

end Behavioral;