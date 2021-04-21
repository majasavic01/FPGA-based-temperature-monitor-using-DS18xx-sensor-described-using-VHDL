library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity divider1Hz is
    Port ( clk_in 	: IN	STD_LOGIC;
           clk_out 	: OUT	STD_LOGIC
	 );
end divider1Hz;

architecture Behavioral of divider1Hz is

SIGNAL count: INTEGER RANGE 0 to 50000000; 

begin

	
	process (clk_in)
	begin
		if (rising_edge(clk_in)) then
			count <= count + 1;				
			if (count = 50000000) then	   			
				count <= 0;						
				clk_out <= '1';				
			else
				clk_out <= '0';				
			end if;
		end if;
	end process;

end Behavioral;