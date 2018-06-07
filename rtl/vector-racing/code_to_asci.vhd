library ieee;
use ieee.std_logic_1164.all;

entity code_to_asci is
	port (
		scancode : in std_logic_vector(15 downto 0);
		upper: in std_logic;
		asci: out std_logic_vector(7 downto 0)
	);
end code_to_asci;

architecture decoder of code_to_asci is
	signal decoded: std_logic_vector(7 downto 0);
	signal num: std_logic;
	component is_num
		port (
			asci: in std_logic_vector(7 downto 0);
			res: out std_logic
		);
	end component;
begin
	with scancode(7 downto 0) select
		decoded <= 	"01100001" when x"1C", -- a
						"01100010" when x"32", -- b
						"01100011" when x"21", -- c
						"01100100" when x"23", -- d
						"01100101" when x"24", -- e
						"01100110" when x"2B", -- f
						"01100111" when x"34", -- g
						"01101000" when x"33", -- h
						"01101001" when x"43", -- i
						"01101010" when x"3B", -- j
						"01101011" when x"42", -- k
						"01101100" when x"4B", -- l
						"01101101" when x"3A", -- m
						"01101110" when x"31", -- n
						"01101111" when x"44", -- o
						"01110000" when x"4D", -- p
						"01110001" when x"15", -- q
						"01110010" when x"2D", -- r
						"01110011" when x"1B", -- s
						"01110100" when x"2C", -- t
						"01110101" when x"3C", -- u
						"01110110" when x"2A", -- v
						"01110111" when x"1D", -- w
						"01111000" when x"22", -- x
						"01111001" when x"35", -- y
						"01111010" when x"1A", -- z
						"00110000" when x"45", -- 0
						"00110001" when x"16", -- 1
						"00110010" when x"1E", -- 2
						"00110011" when x"26", -- 3
						"00110100" when x"25", -- 4
						"00110101" when x"2E", -- 5
						"00110110" when x"36", -- 6
						"00110111" when x"3D", -- 7
						"00111000" when x"3E", -- 8
						"00111001" when x"46", -- 9
						"00110000" when x"71", -- N0
						"00110001" when x"70", -- N1
						"00110010" when x"69", -- N2
						"00110011" when x"7A", -- N3
						"00110100" when x"6B", -- N4
						"00110101" when x"73", -- N5
						"00110110" when x"74", -- N6
						"00110111" when x"6C", -- N7
						"00111000" when x"75", -- N8
						"00111001" when x"7D", -- N9
						"00000000" when others;
	is_it_num: is_num port map (asci => decoded, res => num);
	asci <= 	decoded XOR "00100000" when num = '0' AND upper = '1' else
				decoded;
end decoder;