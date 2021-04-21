library IEEE;
use IEEE.STD_LOGIC_1164.ALL;



entity DS18xx_top is
    Port ( 
           CLOCK_50  : in STD_LOGIC;    -- podijelimo sa 50 jer je 1MHz = 1us mikrosekunda,
           Reset      : in    STD_LOGIC;       --  a vrijem senzora u mikrosekundama   
			  --DATA_OUT: out STD_LOGIC_VECTOR(15 downto 0);
           GPIO_0     : inout  STD_LOGIC_VECTOR(0 downto 0);
				--power     :in std_logic;
			  
		HEX0	: out std_logic_vector(6 downto 0);    -- displeji, 0 najlaksa, 5 najteza pozicija
		HEX1  : out std_logic_vector(6 downto 0);
		HEX2  : out std_logic_vector(6 downto 0);
		HEX3  : out std_logic_vector(6 downto 0);
		HEX4  : out std_logic_vector(6 downto 0);
		HEX5  : out std_logic_vector(6 downto 0);
		
		LEDR  : out std_logic_vector(9 downto 0);  -- sing, ako svijetli onda je minus
		SW    : in  std_logic_vector(9 downto 0)  -- za podesavanje preciznosti		
		
			  );
end DS18xx_top;

architecture Behavioral of DS18xx_top is


   COMPONENT DS18xx
	PORT(
  clk             : IN STD_LOGIC;
  enable			   : IN		STD_LOGIC;  -- pojavljuje se sa frekvencijom od 1 MHz, tj 1us
  crc_en				: OUT		STD_LOGIC;
  dataOut			: OUT		STD_LOGIC_VECTOR(71 downto 0);
  ds_data_bus		: INOUT	STD_LOGIC;
  power           : in std_logic;
  config_data     : OUT    STD_LOGIC_VECTOR(7 downto 0);
  precision_input : IN     STD_LOGIC_VECTOR(1 downto 0)
		);
	END COMPONENT;
	
	COMPONENT divider1MHz
	PORT(
		clk_in : IN std_logic;          
		clk_out : OUT std_logic
		);
	END COMPONENT;
	
	COMPONENT CRC
	PORT(
		clk : IN std_logic;
	   enable: IN std_logic;
		data_en : IN std_logic;
		power : in std_logic;
		dataIn : IN std_logic_vector(71 downto 0);          
		dataOut : OUT std_logic_vector(15 downto 0);
		dataValid : OUT std_logic
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
signal REQUEST : STD_LOGIC;
SIGNAL DATA    : STD_LOGIC_VECTOR(71 downto 0);
--SIGNAL SET_PRECISION : STD_LOGIC_VECTOR(1 downto 0) :="11";
SIGNAL TEMPERATURE_REGISTER : STD_LOGIC_VECTOR (15 downto 0);
SIGNAL PREC_OUT : STD_LOGIC_VECTOR(1 downto 0) ;

begin

	--precision_in=>SET_PRECISION;
	U1: DS18xx PORT MAP(
		clk=>CLOCK_50,
		enable => CLK1MHZ,
		crc_en => DOK,
		dataOut => DATA,
		power =>SW(0),
		--precision_input=>precision_in,
		precision_input=>SW(9 downto 8),
		ds_data_bus => GPIO_0(0)
		
	);

	U2: divider1MHz PORT MAP(
		clk_in => CLOCK_50,
		clk_out => CLK1MHZ
	);

	U3: CRC PORT MAP(
		clk=> CLOCK_50,
		enable => CLK1MHZ,
		--clk=>CLK1MHZ,
		data_en => DOK,
		dataIn => DATA,
		power =>SW(0),
		dataOut => TEMPERATURE_REGISTER,
		dataValid =>REQUEST 
	);
	U4: data_conv PORT MAP(
	input=>TEMPERATURE_REGISTER,
	--prec=>precision_in,
	prec => SW(9 downto 8),
	output0=>HEX0,
	output1=>HEX1,
	output2=>HEX2,
	output3=>HEX3,
	output4=>HEX4,
	output5=>HEX5,
	sign=>LEDR(9)
	);
		
end Behavioral;
