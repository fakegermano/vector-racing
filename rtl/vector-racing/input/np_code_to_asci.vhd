-------------------------------------------------------------------------------
-- Title      : MC613
-- Project    : Vector Racing
-------------------------------------------------------------------------------
-- File       : np_code_to_asci.vhd
-- Author     : Daniel Germano Travieso
-- Company    : IC - UNICAMP
-- Last update: 2018/05/16
-------------------------------------------------------------------------------
-- Description:
-- Decodes the read Scan Code from the keyboard controller to the equivalent
-- ASCI code of the keypress. Only keys on the KeyPad are read 
-- + and - keys
-- Enter and Esc keys
-- 1 to 9 numeric keys
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity np_code_to_asci is
	port (
		np_scancode : in std_logic_vector(15 downto 0);
		asci: out std_logic_vector(7 downto 0)
	);
end np_code_to_asci;

architecture decoder of np_code_to_asci is
begin
	with np_scancode(7 downto 0) select
		asci <= 	"00110000" when x"71", -- N0
					"00110001" when x"70", -- N1
					"00110010" when x"69", -- N2
					"00110011" when x"7A", -- N3
					"00110100" when x"6B", -- N4
					"00110101" when x"73", -- N5
					"00110110" when x"74", -- N6
					"00110111" when x"6C", -- N7
					"00111000" when x"75", -- N8
					"00111001" when x"7D", -- N9
					"00101011" when x"79", -- N+
					"00101101" when x"7B", -- N-
					"00001010" when x"5A", -- NEn
					"00011011" when x"76", -- ESC
					"00000000" when others;
end decoder;