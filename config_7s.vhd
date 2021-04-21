library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.ALL;
use ieee.std_logic_unsigned.ALL;

entity config_7s is
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
end config_7s;




architecture comp_arch of config_7s is

	component bcd7_decoder
		port
		(
			input : in std_logic_vector(3 downto 0);
			output : out std_logic_vector(6 downto 0)

		);
	end component;
	
	component doublee_dabble is
   port ( input : in  std_logic_vector (6 downto 0);
           ones : out  std_logic_vector (3 downto 0);
           tens : out  std_logic_vector (3 downto 0)
          );
	end component;	
	
	signal s1:   std_logic_vector (3 downto 0);
	signal s2:   std_logic_vector (3 downto 0);
	signal s3:   std_logic_vector (3 downto 0);
	signal s4:   std_logic_vector (3 downto 0);
	signal s5:   std_logic_vector (3 downto 0);
	signal s6:   std_logic_vector (3 downto 0);
begin
	
	
	with input7(9 downto 7) select
	s3 <= "1110" when "000",--'e'- idle
			"1011" when "100",--'i'
			"1100" when "011",--'p'
			"1101" when "010",--'c'
			"1111" when others;
	
	d3: doublee_dabble
		port map(input => input7(6 downto 0), ones => s1, tens => s2);
			
	 
	 with input7(6 downto 0) select
	 s6 <= "1100" when "1100100",--'p'
			 "1011" when "1100101",--'i'
			 s1 when others;
	 
	 with s3 select
	 s5 <= "1111" when "1101",--'c'
	       "1111" when "1110",--'e' 
			 "1111" when "1111",
			 s2 when others;	
	 
	 with s3 select
	 s4 <= s6 when "1101",--'c'
			 "1111" when "1111",
			 "1111" when "1110",
			 s1 when others;	
	
		u1: bcd7_decoder
		port map(input => s4, output => output70);
	   u2: bcd7_decoder
		port map(input => s5, output => output71);
     	u3: bcd7_decoder
		port map(input => s3, output => output72);
	   u4: bcd7_decoder
		port map(input =>"1111", output => output73);            
		u5: bcd7_decoder
		port map(input => "1111", output => output74);
	   u6: bcd7_decoder
		port map(input => "1111", output => output75);
	 
end comp_arch;		
		
