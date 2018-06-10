library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.vracing_pack.all;

entity preview is
	port (
		clk: in std_logic;
		key_on: in std_logic_vector(2 downto 0);
		key_code: in std_logic_vector(47 downto 0);
		vector: in velocity_t;
		vector_w, vector_s, vector_a, vector_d: out velocity_t;
		get_vel : out std_logic;
		choice : out std_logic_vector(2 downto 0);
		reset : in std_logic
		);
end preview;

architecture rtl of preview is
	signal key_on_q : std_logic_vector(2 downto 0);
	signal pressed : std_logic_vector(2 downto 0);
begin
	process (clk)
	begin
		if clk'event and clk = '1' then
			key_on_q <= key_on;
		end if;
	end process;
	
	choice <= pressed;
	
	preview: process (clk, reset)
	begin
		if reset = '0' then
			pressed <= SPACE;
		elsif clk'event and clk = '1' then
			if key_on(0) = '1' AND key_on_q(0) = '0' then
				if (key_code(7 downto 0) = x"1D") then -- w 
					pressed <= W;
				elsif key_code(7 downto 0) = x"1B" then -- s
					pressed <= S;
				elsif key_code(7 downto 0) = x"23" then -- d
					pressed <= D;
				elsif key_code(7 downto 0) = x"1C" then -- a
					pressed <= A;
				elsif key_code(7 downto 0) = x"29" then -- space
					pressed <= SPACE;
				else 
					pressed <= pressed;
				end if;
			else
				pressed <= pressed;
			end if;
		end if;
	end process preview;
	
	process (clk) 
		variable inc_w : velocity_t := (to_signed(0, V_WSIZE), to_signed(-1, V_WSIZE));
		variable inc_s : velocity_t := (to_signed(0, V_WSIZE), to_signed(1, V_WSIZE));
		variable inc_a : velocity_t := (to_signed(-1, V_WSIZE), to_signed(0, V_WSIZE));
		variable inc_d : velocity_t := (to_signed(1, V_WSIZE), to_signed(0, V_WSIZE));
	begin
		if clk'event and clk = '1' then
			vector_w(0) <= vector(0) + inc_w(0);
			vector_w(1) <= vector(1) + inc_w(1);
			vector_s(0) <= vector(0) + inc_s(0);
			vector_s(1) <= vector(1) + inc_s(1);
			vector_a(0) <= vector(0) + inc_a(0);
			vector_a(1) <= vector(1) + inc_a(1);
			vector_d(0) <= vector(0) + inc_d(0);
			vector_d(1) <= vector(1) + inc_d(1);
		end if;
	end process;
	
	process (clk)
		variable temp : std_logic;
	begin
		if clk'event and clk = '1' then
			get_vel <= temp;
			if key_on(0) = '1' AND key_on_q(0) = '0' then
				if key_code(7 downto 0) = x"5A" then -- enter
					temp := '1';
				else
					temp := '0';
				end if;
			else
				temp := '0';
			end if;
		end if;
	end process;
	
	
end rtl;


