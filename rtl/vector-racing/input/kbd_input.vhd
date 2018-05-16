-------------------------------------------------------------------------------
-- Title      : MC613
-- Project    : Vector Racing
-------------------------------------------------------------------------------
-- File       : kbd_input.vhd
-- Author     : Andre de Souza Goncalves
-- Company    : IC - UNICAMP
-- Last update: 2018/05/12
-------------------------------------------------------------------------------
-- Description:
-- Prompts the PS2 keyboard controller to get the scan codes of key pressed.
-- The main clock for key read is 50MHz (for the SoC Board)
-- Send the scanned codes to the kbd_np_esc module
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
library input;
use input.input_pack.all;

entity kbd_input is
  port (
    CLOCK_50 : in std_logic;
    PS2_DAT : inout STD_LOGIC;
    PS2_CLK : inout STD_LOGIC;
    HEX1 : out std_logic_vector(6 downto 0);
    HEX0 : out std_logic_vector(6 downto 0)
  );
end kbd_input;

architecture rtl of kbd_input is
  signal key_on : std_logic_vector(2 downto 0);
  signal key_code : std_logic_vector(47 downto 0);
begin

  kbdex_ctrl_inst : kbdex_ctrl
    generic map (
      clkfreq => 50000
    )
    port map (
      ps2_data => PS2_DAT,
      ps2_clk => PS2_CLK,
      clk => CLOCK_50,
      en => '1',
      resetn => '1',
      lights => "000", -- lights will be off by default
      key_on => key_on,
      key_code => key_code
    );
  
  kbd_alphanum_inst : kbd_np_esc
    port map (
      clk => CLOCK_50,
      key_on => key_on,
      key_code => key_code,
      HEX1 => HEX1,
      HEX0 => HEX0
    );

end rtl;