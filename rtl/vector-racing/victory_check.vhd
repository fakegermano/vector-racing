library ieee;
use ieee.std_logic_1164.all;
use work.vracing_pack.all;

entity victory_check is
	port (
		clk : in std_logic;
		reset : in std_logic;
		pos_x : in coord_x;
		new_pos_x : in coord_x;
		new_pos_y : in coord_y;
		finish : out std_logic;
		wrong_way : out std_logic
	);
end victory_check;

architecture rtl of victory_check is
	signal t_nx : integer;
	signal t_ny : integer;
	signal t_x : integer;
begin
	process(clk)
		variable t: integer;
	begin
		if rising_edge(clk) then
			t := pos_x - 31;
		end if;
		t_x <= t;
	end process;
	
	process(clk)
		variable t: integer;
	begin
		if rising_edge(clk) then
			t := new_pos_y - 15;
		end if;
		t_ny <= t;
	end process;
	
	process(clk)
		variable t: integer;
	begin
		if rising_edge(clk) then
			t := new_pos_x - 31;
		end if;
		t_nx <= t;
	end process;
	
	process(clk)
		variable t: std_logic := '0';
		variable res: std_logic := '0';
	begin
		if reset = '0' then
			t := '0';
			res := '0';
		elsif rising_edge(clk) then
			if t_ny <= 0 AND t_x > 0 AND t_nx <= 0 then
				t := '1';
				res := '0';
			elsif t_ny <= 0 AND t_nx > 0 AND t_x <= 0 then
				res := '1';
			else
				t := t;
				res := res;
			end if;	
		end if;
		finish <= t;
		wrong_way <= res;
	end process;
end rtl;