library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.ALL;
use ieee.std_logic_unsigned.ALL;

entity data_conv is
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
end data_conv;




architecture comp_arch of data_conv is

	component bcd_decoder
		port
		(
			input : in std_logic_vector(3 downto 0);
			output : out std_logic_vector(6 downto 0)

		);
	end component;
	
	component double_dabble is
   port ( input : in  std_logic_vector (6 downto 0);
           ones : out  std_logic_vector (3 downto 0);
           tens : out  std_logic_vector (3 downto 0)
--           hundreds : out  std_logic_vector (3 downto 0)

          );
	end component;	
	
	signal s1:   std_logic_vector (3 downto 0);
	signal s2:   std_logic_vector (3 downto 0);
	signal s3:   std_logic_vector (3 downto 0);
	signal temp : std_logic_vector (15 downto 0);
	signal temp_in:std_logic_vector (15 downto 0); 
begin
	process(input,prec)
	
	variable s : std_logic_vector(15 downto 0);
	
	begin
	
	if input(15)='1' then
		s:=(not input)+'1';
	
	else
		s:=input;
	
	end if;
	temp_in<=s;
	case prec is
		when "00" =>   temp_in(2 downto 0)<="000";
		when "01" =>   temp_in(1 downto 0)<="00";
		when "10" =>   temp_in(0)<='0';
		when "11" =>   temp_in<=s;
	end case;
	

	end process;--10
	d3: double_dabble
		port map(input => temp_in(10 downto 4), ones => s1, tens => s2);

	   WITH temp_in(3 downto 0) SELECT      
      temp    <=    "0000000000000000" WHEN "0000",--0.0000
                    "0000011000100101" WHEN "0001",--0.0625
						  "0001001001010000" WHEN "0010",--0.125
						  "0001100001110101" WHEN "0011",--0.1875
						  "0010010100000000" WHEN "0100",--0.2500
						  "0011000100100101" WHEN "0101",--0.3125
						  "0011011101010000" WHEN "0110",--0.3750 
						  "0100001101110101" WHEN "0111",--0.4375
						  "0101000000000000" WHEN "1000",--0.500
						  "0101011000100101" WHEN "1001",--0.5625
						  "0110001001010000" WHEN "1010",--0.6250
						  "0110100001110101" WHEN "1011",--0.6875
						  "0111010100000000" WHEN "1100",--0.7500
						  "1000000100100101" WHEN "1101",--0.8125
						  "1000011101010000" WHEN "1110",--0.8750
						  "1001001101110101" WHEN "1111",-- 0.9375
						  "0000000000000000" when others;
	
		u1: bcd_decoder
		port map(input => s1, output => output4);
	   u2: bcd_decoder
		port map(input => s2, output => output5);
     	u3: bcd_decoder
		port map(input => temp(15 downto 12), output => output3);
	   u4: bcd_decoder
		port map(input => temp(11 downto 8), output => output2);            
		u5: bcd_decoder
		port map(input => temp(7 downto 4), output => output1);
	   u6: bcd_decoder
		port map(input => temp(3 downto 0), output => output0);
		sign<=input(15);
	 
end comp_arch;	
