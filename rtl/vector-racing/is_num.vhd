library ieee;
use ieee.std_logic_1164.all;

entity is_num is
	port (
		asci: in std_logic_vector(7 downto 0);
		res: out std_logic
	);
end is_num;

architecture rtl of is_num is
begin
	with asci select
		res <=	'1' when "00110000", -- 0
					'1' when "00110001", -- 1
					'1' when "00110010", -- 2
					'1' when "00110011", -- 3
					'1' when "00110100", -- 4
					'1' when "00110101", -- 5
					'1' when "00110110", -- 6
					'1' when "00110111", -- 7
					'1' when "00111000", -- 8
					'1' when "00111001", -- 9
					'1' when "00000000", -- non valid asci codes must be treated as numbers so shift has no effect
					'0' when others;
end rtl;