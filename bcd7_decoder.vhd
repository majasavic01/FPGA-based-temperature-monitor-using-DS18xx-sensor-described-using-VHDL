library ieee;
use ieee.std_logic_1164.all;

entity bcd7_decoder is
	port
	(
		input : in std_logic_vector(3 downto 0);
		output : out std_logic_vector(6 downto 0)

	);
end bcd7_decoder;

architecture bcd7_arch of bcd7_decoder is

begin


	with input select
	output <= "1000000" when "0000", 
				 "1111001" when "0001", 
				 "0100100" when "0010", 
				 "0110000" when "0011", 
				 "0011001" when "0100", 
				 "0010010" when "0101", 
				 "0000010" when "0110", 
				 "1111000" when "0111", 
				 "0000000" when "1000", 
				 "0010000" when "1001",
				 "0111111" when "1010",--'-'
				 "1001111" when "1011",--'i'
				 "0001100" when "1100",--'p'
				 "1000110" when "1101",--'c'
				 "0000110" when "1110",--'e'
				 "1111111" when others;
				 
				 

end bcd7_arch;
