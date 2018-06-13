-- Quartus Prime VHDL Template
-- Binary Counter

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity binary_counter is

	generic
	(
		MIN_COUNT : natural := 0;
		MAX_COUNT : natural := 99
	);

	port
	(
		clk		  : in std_logic;
		reset	  : in std_logic;
		enable	  : in std_logic;
		q_d		  : out std_logic_vector(3 downto 0);
		q_u		  : out std_logic_vector(3 downto 0)
	);

end entity;

architecture rtl of binary_counter is
	signal out_d, out_u: std_logic_vector(3 downto 0);
begin
	process (clk)
		variable   d: std_logic_vector(3 downto 0) := "0000";
		variable   u: std_logic_vector(3 downto 0) := "0000";
	begin
		if reset = '0' then
				-- Reset the counter to 0
				d := "0000";
				u := "0000";
		elsif (rising_edge(clk)) then
			if enable = '1' then
				if u /= "1110" AND d /= "1110" then
					u := u + '1';
					if u = "1001" then
						u := "0000";
						d := d + '1';
						if d = "1001" then
							u := "1110";
							d := "1110";
						end if;
					end if;
				end if;
			end if;
		end if;
		out_u <= u;
		out_d <= d;
	end process;
	
	q_u <= out_u;
	q_d <= out_d;
end rtl;
