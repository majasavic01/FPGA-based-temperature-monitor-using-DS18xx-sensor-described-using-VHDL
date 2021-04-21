library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity divider1MHz is
    Port ( clk_in 	: IN	STD_LOGIC;
           clk_out 	: OUT	STD_LOGIC
	 );
end divider1MHz;

architecture Behavioral of divider1MHz is

SIGNAL count: INTEGER RANGE 0 to 49; --brojac

begin

	--  dijeljenje takta 1/50 jer nam mikrosekunde trebaju
 	process (clk_in)
	begin
		if (rising_edge(clk_in)) then
			count <= count + 1;				
			if (count = 49) then				
				count <= 0;						
				clk_out <= '1';				
			else
				clk_out <= '0';				
			end if;
		end if;
	end process;

end Behavioral;