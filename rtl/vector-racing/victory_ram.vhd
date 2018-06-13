-- Quartus Prime VHDL Template
-- Simple Dual-Port RAM with different read/write addresses but
-- single read/write clock

library ieee;
use ieee.std_logic_1164.all;
use work.vracing_pack.all;

entity victory_ram is
	port
	(
		clk		: in std_logic;
		raddr		: in natural range 0 to ADDR_MAX;
		q			: out pixel_t
	);
end victory_ram;

architecture rtl of victory_ram is
	-- Declare the RAM signal.	
	signal ram : screen_mem;
	attribute ram_init_file : string;
	attribute ram_init_file of ram : signal is "Victory.mif";
begin
	process(clk)
	begin
	if(rising_edge(clk)) then 
		-- return the OLD data at the address
		q <= ram(raddr);
	end if;
	end process;

end rtl;
