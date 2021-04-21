library ieee;
use ieee.std_logic_1164.all;

entity bcd_decoder is
	port
	(
		input : in std_logic_vector(3 downto 0);
		output : out std_logic_vector(6 downto 0)

	);
end bcd_decoder;

architecture bcd_arch of bcd_decoder is

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
				 "0111111" when "1111",
				 "1111111" when others;
				 

end bcd_arch;
