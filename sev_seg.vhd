library ieee;
use ieee.std_logic_1164.all;


entity sev_seg is
	port
	(
		input	: in  std_logic_vector(15 downto 0);
		output0	: out std_logic_vector(6 downto 0);
		output1  : out std_logic_vector(6 downto 0);
		output2  : out std_logic_vector(6 downto 0);
		output3  : out std_logic_vector(6 downto 0);
		output4  : out std_logic_vector(6 downto 0);
		output5  : out std_logic_vector(6 downto 0)
		
	);
end sev_seg;




architecture comp_arch of sev_seg is

	component bcd_decoder
		port
		(
			input : in std_logic_vector(3 downto 0);
			output : out std_logic_vector(6 downto 0)

		);
	end component;
	
	component double_dabble is
   port ( binIN : in  STD_LOGIC_VECTOR (6 downto 0);
           ones : out  STD_LOGIC_VECTOR (3 downto 0);
           tens : out  STD_LOGIC_VECTOR (3 downto 0)
--           hundreds : out  STD_LOGIC_VECTOR (3 downto 0)

          );
	end component;	
	
	signal s1:   STD_LOGIC_VECTOR (3 downto 0);
	signal s2:   STD_LOGIC_VECTOR (3 downto 0);
	signal s3:   STD_LOGIC_VECTOR (3 downto 0);
	signal temp : STD_LOGIC_VECTOR (15 downto 0);

begin
	
	d3: double_dabble
		port map(binIN => input(10 downto 4), ones => s1, tens => s2);

	   WITH input(3 downto 0) SELECT      
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
		-- manipulisati ulazima ovdje u procesu
		-- npr output 1 jednako signal 3
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
		
	 
end comp_arch;		
		

configuration sev_seg_cfg of sev_seg is
	for comp_arch
	end for;
end sev_seg_cfg;





--entity sev_seg is
--	port
--	(
--		input1	: in  std_logic_vector(3 downto 0);-- jedinice
--		input2   : in  std_logic_vector(3 downto 0);-- desetice
--input3   : in  std_logic_vector(3 downto 0);-- desetice
--input4   : in  std_logic_vector(3 downto 0);-- desetice
--input5   : in  std_logic_vector(3 downto 0);-- desetice
--input6   : in  std_logic_vector(3 downto 0);-- desetice
--		output1	: out std_logic_vector(6 downto 0);-- izlaz jedinice
--		output2  : out std_logic_vector(6 downto 0)-- izlaz desetice
--		
--	);
--end sev_seg;
--
--architecture dir_arch of sev_seg is
--	signal odd : std_logic;
--begin
--	with input1 select
--	output1 <= "1000000" when "0000", 
--				 "1111001" when "0001", 
--				 "0100100" when "0010", 
--				 "0110000" when "0011", 
--				 "0011001" when "0100", 
--				 "0010010" when "0101", 
--				 "0000010" when "0110", 
--				 "1111000" when "0111", 
--				 "0000000" when "1000", 
--				 "0010000" when "1001", 
--				 "1111111" when others;
--	with input2 select
--	output2 <= "1000000" when "0000", 
--				 "1111001" when "0001", 
--				 "0100100" when "0010", 
--				 "0110000" when "0011", 
--				 "0011001" when "0100", 
--				 "0010010" when "0101", 
--				 "0000010" when "0110", 
--				 "1111000" when "0111", 
--				 "0000000" when "1000", 
--				 "0010000" when "1001", 
--				 "1111111" when others;
--
--	
--end dir_arch;
--
--
--architecture comp_arch of sev_seg is
--
--	component bcd_decoder
--		port
--		(
--			input : in std_logic_vector(3 downto 0);
--			output : out std_logic_vector(6 downto 0)
--
--		);
--	end component;
--		
--
--begin
--	u1: bcd_decoder
--		port map(input => input1, output => output1);
--	u2: bcd_decoder
--		port map(input => input2, output => output2);
--end comp_arch;
--
--configuration sev_seg_cfg of sev_seg is
--	for comp_arch
--	end for;
--end sev_seg_cfg;
