library IEEE;
use IEEE.STD_LOGIC_1164.ALL;



entity TEST is
    Port ( 
			  key       : IN STD_LOGIC_VECTOR(3 downto 0);
           CLOCK_50  : in STD_LOGIC;                -- podijelimo sa 50 jer je 1MHz = 1us mikrosekunda,
                                                    --  a vrijem senzora u mikrosekundama   
		
          GPIO_0     : inout  STD_LOGIC_VECTOR(0 downto 0);
		GPIO_1  :OUT STD_LOGIC_VECTOR(0 downto 0);
		HEX0	: out std_logic_vector(6 downto 0);    -- displeji, 0 najlaksa, 5 najteza pozicija
		HEX1  : out std_logic_vector(6 downto 0);
		HEX2  : out std_logic_vector(6 downto 0);
		HEX3  : out std_logic_vector(6 downto 0);
		HEX4  : out std_logic_vector(6 downto 0);
		HEX5  : out std_logic_vector(6 downto 0);		
		LEDR  : out std_logic_vector(9 downto 7)  -- sing, ako svijetli onda je minus
		
			
			  );
end TEST;

architecture Behavioral of TEST is

COMPONENT reset_module
port
	(
		-- Input ports
		config_mode	: in  std_logic;--dobija signal enable out sa config_fsm modula
		clk	: in  std_logic;
		button_a : in std_logic;--dugmad sa ploce
		button_b : in std_logic;
		button_c : in std_logic;
		button_d : in std_logic;
		-- Output ports
	--	dioda   : out std_logic;
		reset	: out std_logic--izlaz za reset
	);
END COMPONENT;
COMPONENT WIRE_1_MASTER
	
	PORT(
			  CLOCK_50  : in STD_LOGIC;         
			  DATA_OUT: out STD_LOGIC_VECTOR(15 downto 0);
           IN_OUT_PIN     : inout  STD_LOGIC;
			  power     :in std_logic;
			  precision : in std_logic_vector(1 downto 0)
		);
	END COMPONENT;
COMPONENT configuration_fsm
	
	PORT(
			  -- Input ports
		clk : in std_logic;
		up_next_button	: in  std_logic;
		down_mode_button : in  std_logic;
		set_button : in std_logic;
		reset : in std_logic;
		
		-- Output ports
		output : out std_logic_vector(9 downto 0):="0000000000";--izlaz za 7s displeje
		power : out std_logic;
		interval_out : out std_logic_vector(6 downto 0);
		preciznost_out : out std_logic_vector(1 downto 0);
		enable_out : out std_logic
		);
	END COMPONENT;
	COMPONENT config_7s 
	port
	(
		input7	: in  std_logic_vector(9 downto 0);
		output70	: out std_logic_vector(6 downto 0);
		output71  : out std_logic_vector(6 downto 0);
		output72  : out std_logic_vector(6 downto 0);
		output73  : out std_logic_vector(6 downto 0);
		output74  : out std_logic_vector(6 downto 0);
		output75  : out std_logic_vector(6 downto 0)
		
	);

	END COMPONENT;
 	COMPONENT on_off_ds18xx
	Port (
			 clock_50	: IN	STD_LOGIC;
          enable 	: IN	STD_LOGIC;
			 measure_period: IN std_logic_vector(6 downto 0);    
			 measure :  IN STD_LOGIC;
			 power  :out std_logic;
			 POWER_PIN  :  OUT STD_LOGIC
	 );
	END COMPONENT;
	COMPONENT mux Port ( SEL : in  STD_LOGIC;
          
           A0   : in  STD_LOGIC_VECTOR (6 downto 0);
           A1   : in  STD_LOGIC_VECTOR (6 downto 0);
			  A2   : in  STD_LOGIC_VECTOR (6 downto 0);
			  A3   : in  STD_LOGIC_VECTOR (6 downto 0);
			  A4   : in  STD_LOGIC_VECTOR (6 downto 0);
			  A5   : in  STD_LOGIC_VECTOR (6 downto 0); --izlaz data conv
           B0   : in  STD_LOGIC_VECTOR (6 downto 0); --izlaz iz config
			  B1   : in  STD_LOGIC_VECTOR (6 downto 0);
			  B2   : in  STD_LOGIC_VECTOR (6 downto 0);
			  B3   : in  STD_LOGIC_VECTOR (6 downto 0);
			  B4   : in  STD_LOGIC_VECTOR (6 downto 0);
			  B5   : in  STD_LOGIC_VECTOR (6 downto 0);
           X0   : out STD_LOGIC_VECTOR (6 downto 0);
			  X1   : out STD_LOGIC_VECTOR (6 downto 0);
			  X2   : out STD_LOGIC_VECTOR (6 downto 0);
			  X3   : out STD_LOGIC_VECTOR (6 downto 0);
			  X4   : out STD_LOGIC_VECTOR (6 downto 0);
			  X5   : out STD_LOGIC_VECTOR (6 downto 0);			   
			  point : out STD_LOGIC;
			  minus_input : in STD_LOGIC;
			  minus_output : out STD_LOGIC
	 );
	END COMPONENT;
	COMPONENT data_conv 
	port
	(
		input	: in  std_logic_vector(15 downto 0);
		output0	: out std_logic_vector(6 downto 0);
		output1  : out std_logic_vector(6 downto 0);
		output2  : out std_logic_vector(6 downto 0);
		output3  : out std_logic_vector(6 downto 0);
		output4  : out std_logic_vector(6 downto 0);
		output5  : out std_logic_vector(6 downto 0);
		prec: in std_logic_vector(1 downto 0);
		sign: out std_logic
	);
end COMPONENT;
	
	
SIGNAL CLK1MHZ	: STD_LOGIC;
SIGNAL DOK   	: STD_LOGIC;
SIGNAL POWER_DS18xx   : STD_LOGIC; 
SIGNAL POWERa_DS18xx   : STD_LOGIC;
SIGNAL DATA    : STD_LOGIC_VECTOR(71 downto 0);
SIGNAL DATA1    : STD_LOGIC_VECTOR(9 downto 0); 

SIGNAL TEMPERATURE_REGISTER : STD_LOGIC_VECTOR (15 downto 0);
SIGNAL Tinterv : STD_LOGIC_VECTOR (6 downto 0);
SIGNAL PREC_OUT : STD_LOGIC_VECTOR(1 downto 0) ;
SIGNAL REGISTERM : STD_LOGIC_VECTOR (15 downto 0);
SIGNAL HEXA0: std_logic_vector(6 downto 0);
SIGNAL HEXA1: std_logic_vector(6 downto 0);
SIGNAL HEXA2: std_logic_vector(6 downto 0);
SIGNAL HEXA3: std_logic_vector(6 downto 0);
SIGNAL HEXA4: std_logic_vector(6 downto 0);
SIGNAL HEXA5: std_logic_vector(6 downto 0);
SIGNAL HEXA70: std_logic_vector(6 downto 0);
SIGNAL HEXA71: std_logic_vector(6 downto 0);
SIGNAL HEXA72: std_logic_vector(6 downto 0);
SIGNAL HEXA73: std_logic_vector(6 downto 0);
SIGNAL HEXA74: std_logic_vector(6 downto 0);
SIGNAL HEXA75: std_logic_vector(6 downto 0);
SIGNAL SIGN_SIGNAL: STD_LOGIC;
SIGNAL RESET_SIGNAL :STD_LOGIC;

begin

U6: reset_module PORT MAP(

		config_mode	=>DOK,--dobija signal enable out sa config_fsm modula
		clk =>CLOCK_50,
		button_a => key(0),--dugmad sa ploce
		button_b => key(1),
		button_c => key(2),
		button_d => key(3),
		--dioda   =>ledr(0),
		-- Output ports
		reset	=> RESET_SIGNAL
);

U8:  on_off_ds18xx PORT MAP(
		
		CLOCK_50=>CLOCK_50,
		enable=> POWER_DS18xx,     
		measure_period=>Tinterv,  
		measure =>key(3),
		power => POWERa_DS18xx,   
		POWER_PIN=>GPIO_1(0)
		);
		
U7:  configuration_fsm PORT MAP(
		-- Input ports
		clk => CLOCK_50, 
		up_next_button	=>key(0),
		down_mode_button =>key(1),
		set_button =>key(2),
		reset => RESET_SIGNAL,
		
		-- Output ports
		output =>DATA1 ,--izlaz za 7s displeje
		power =>POWER_DS18xx,
		interval_out =>Tinterv , --POTREBNO ZA ON_OFF
		preciznost_out =>PREC_OUT,
		enable_out =>DOK -- DA LI CE BITI SA CONFIG ILI TEMP
		
		);	
U5: WIRE_1_MASTER PORT MAP(
		CLOCK_50=>CLOCK_50,
		power=>POWERa_DS18xx,   
		precision=>PREC_OUT , 	
		DATA_OUT=>TEMPERATURE_REGISTER,
		IN_OUT_PIN=>GPIO_0(0)		
		);	

	U4: data_conv PORT MAP(
	input=>TEMPERATURE_REGISTER,             
	prec => PREC_OUT, 
	output0=>HEXA0,
	output1=>HEXA1,
	output2=>HEXA2,
	output3=>HEXA3,
	output4=>HEXA4,
	output5=>HEXA5,
	sign=>SIGN_SIGNAL
	);	
U10: config_7s PORT MAP(
	input7=>DATA1,             
	output70=>HEXA70,
	output71=>HEXA71,
	output72=>HEXA72,
	output73=>HEXA73,
	output74=>HEXA74,
	output75=>HEXA75
	
	);	
	U9:  mux PORT MAP(
		SEL=>DOK, 
      A0 => HEXA0,
           
           A1   => HEXA1,
			  A2   => HEXA2,
			  A3  => HEXA3,
			  A4   => HEXA4,
			  A5   => HEXA5,--izlaz data conv
           B0   =>HEXA70, --izlaz iz config
			  B1  =>HEXA71,
			  B2  =>HEXA72,
			  B3 =>HEXA73,
			  B4 =>HEXA74,
			  B5 =>HEXA75,
           X0   => HEX0,
			  X1   => HEX1,
			  X2   => HEX2,
			  X3   => HEX3,
			  X4   => HEX4,
			  X5   => HEX5,
			  minus_input =>SIGN_SIGNAL,
			  minus_output =>ledr(9),
			  point =>ledr(7)
		
	);
	
end Behavioral;
