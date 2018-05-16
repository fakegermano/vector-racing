-------------------------------------------------------------------------------
-- Title      : MC613
-- Project    : Vector Racing
-------------------------------------------------------------------------------
-- File       : kbd_np_esc.vhd
-- Author     : Daniel Germano Travieso
-- Company    : IC - UNICAMP
-- Last update: 2018/05/16
-------------------------------------------------------------------------------
-- Description:
-- Reads the first pressed key on the keyboard (inputs key_on and key_code) and
-- decodes it to its asci equivalent, to be outputed as 7 segment display.
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
library input;
use input.input_pack.all;

entity kbd_np_esc is
  port (
    clk : in std_logic;
    key_on : in std_logic_vector(2 downto 0);
    key_code : in std_logic_vector(47 downto 0);
    HEX1 : out std_logic_vector(6 downto 0); -- GFEDCBA
    HEX0 : out std_logic_vector(6 downto 0) -- GFEDCBA
  );
end kbd_np_esc;

architecture rtl of kbd_np_esc is
	signal output_code: std_logic_vector(15 downto 0);
	signal asci_code: std_logic_vector(7 downto 0);
begin
	hexseg0: bin2hex port map (SW => asci_code(3 downto 0), HEX0 => HEX0); -- decode the asci code to 7 segment display
	hexseg1: bin2hex port map (SW => asci_code(7 downto 4), HEX0 => HEX1);
	
	process (clk, key_on)
	begin
		if rising_edge(clk) and key_on(0) = '1' then -- first key pressed
			output_code <= key_code(15 downto 0); -- get the code for the first key
		elsif rising_edge(clk) then
			output_code <= x"0000";
		end if;
	end process;
	
	decode: np_code_to_asci port map (np_scancode => output_code, asci => asci_code); -- decode the input scan code to asci code
end rtl;