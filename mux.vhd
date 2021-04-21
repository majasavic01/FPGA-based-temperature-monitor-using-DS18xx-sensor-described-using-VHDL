library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity mux is
    Port ( SEL : in  STD_LOGIC;
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
end mux;

architecture Behavioral of mux is
begin
    X0 <= A0 when (SEL = '1') else B0;
	 X1 <= A1 when (SEL = '1') else B1;
	 X2 <= A2 when (SEL = '1') else B2;
	 X3 <= A3 when (SEL = '1') else B3;
	 X4 <= A4 when (SEL = '1') else B4;
	 X5 <= A5 when (SEL = '1') else B5;
	 point<='1' when(SEL='1') else '0';
	 minus_output<=minus_input;
end Behavioral;
