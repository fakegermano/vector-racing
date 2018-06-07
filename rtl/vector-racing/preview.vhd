library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.vracing_pack.all;

entity preview is
	port (
		clk: in std_logic;
		key_on: in std_logic_vector(2 downto 0);
		key_code: in std_logic_vector(47 downto 0);
		vector: inout velocity_t
		);
end preview;

architecture rtl of preview is
	signal key_on_q : std_logic_vector(2 downto 0);
	signal vector_t: velocity_t := vector;
begin
	process (clk)
	begin
		if clk'event and clk = '1' then
			key_on_q <= key_on;
		end if;
	end process;
	
	preview: process (clk)
		variable inc : velocity_t := (to_signed(0, V_WSIZE), to_signed(0, V_WSIZE));
	begin
		if clk'event and clk = '1' then
			if key_on(0) = '1' AND key_on_q(0) = '0' then
				if (key_code(7 downto 0) = x"1D") then -- w 
					inc := (to_signed(0, V_WSIZE), to_signed(-1, V_WSIZE)); -- <0, -1>
				elsif key_code(7 downto 0) = x"1B" then -- s
					inc := (to_signed(0, V_WSIZE), to_signed(1, V_WSIZE)); -- <0, +1>
				elsif key_code(7 downto 0) = x"23" then -- d
					inc := (to_signed(1, V_WSIZE), to_signed(0, V_WSIZE)); -- <+1, 0>
				elsif key_code(7 downto 0) = x"1C" then -- a
					inc := (to_signed(-1, V_WSIZE), to_signed(0, V_WSIZE)); -- <-1, 0>
				else 
					inc := (to_signed(0, V_WSIZE), to_signed(0, V_WSIZE)); -- <0, 0>
				end if;
			else
				inc := (to_signed(0, V_WSIZE), to_signed(0, V_WSIZE)); -- <0, 0>
			end if;
			vector_t(0) <= vector_t(0) + inc(0);
			vector_t(1) <= vector_t(1) + inc(1);
		end if;
	end process preview;
	vector <= vector_t;
end rtl;