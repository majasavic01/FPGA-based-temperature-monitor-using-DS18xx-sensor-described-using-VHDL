library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;


entity doublee_dabble is
    Port ( input : in  std_logic_vector (6 downto 0);
           ones : out  std_logic_vector (3 downto 0);
           tens : out  std_logic_vector (3 downto 0)
--           hundreds : out  std_logic_vector (3 downto 0)

          );
end doublee_dabble;

architecture Behavioral of doublee_dabble is

begin

bcd1: process(input)


  variable temp : std_logic_vector (6 downto 0);
  variable bcd : unsigned (11 downto 0) := (others => '0');
  
  begin
   
    bcd := (others => '0');
    temp(6 downto 0) := input;
    
  
    for i in 0 to 6 loop
    
      if bcd(3 downto 0) > 4 then 
        bcd(3 downto 0) := bcd(3 downto 0) + 3;
      end if;
      
      if bcd(7 downto 4) > 4 then 
        bcd(7 downto 4) := bcd(7 downto 4) + 3;
      end if;
    
   
      bcd := bcd(10 downto 0) & temp(6);
      temp := temp(5 downto 0) & '0';
    
    end loop;
 
    ones <= std_logic_vector(bcd(3 downto 0));
    tens <= std_logic_vector(bcd(7 downto 4));
--    hundreds <= std_logic_vector (bcd(11 downto 8));

  
  end process bcd1;            
  
end Behavioral;
