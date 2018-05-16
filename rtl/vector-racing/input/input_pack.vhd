library ieee;
use ieee.std_logic_1164.all;

package input_pack is 
	component ps2_iobase is
		generic(
			clkfreq : integer
		);
		port(
			ps2_data	:	inout	std_logic;
			ps2_clk		:	inout	std_logic;
			clk				:	in	std_logic;
			en				:	in	std_logic;
			resetn		:	in	std_logic;
			idata_rdy	:	in	std_logic;
			idata			:	in	std_logic_vector(7 downto 0);
			send_rdy	:	out	std_logic;
			odata_rdy	:	out	std_logic;
			odata			:	out	std_logic_vector(7 downto 0)
		);
	end component;
	
	component np_code_to_asci is
		port (
			np_scancode : in std_logic_vector(15 downto 0);
			asci: out std_logic_vector(7 downto 0)
		);
	end component;
	
	component kbdex_ctrl is
		generic(
			clkfreq : integer
		);
		port(
			ps2_data	:	inout	std_logic;
			ps2_clk		:	inout	std_logic;
			clk				:	in 	std_logic;
			en				:	in 	std_logic;
			resetn		:	in 	std_logic;		
			lights		: in	std_logic_vector(2 downto 0);
			key_on		:	out	std_logic_vector(2 downto 0);
			key_code	:	out	std_logic_vector(47 downto 0)
		);
	end component;
	
	component kbd_np_esc is
		port (
		clk : in std_logic;
		key_on : in std_logic_vector(2 downto 0);
		 key_code : in std_logic_vector(47 downto 0);
		 HEX1 : out std_logic_vector(6 downto 0);
		 HEX0 : out std_logic_vector(6 downto 0)
	  );
	end component;
	
	component kbd_input is
		port (
		 CLOCK_50 : in std_logic;
		 PS2_DAT : inout STD_LOGIC;
		 PS2_CLK : inout STD_LOGIC;
		 HEX1 : out std_logic_vector(6 downto 0);
		 HEX0 : out std_logic_vector(6 downto 0)
	  );
	end component;
	
	component bin2hex is
		PORT (
			SW: IN std_logic_vector(3 DOWNTO 0);
			HEX0: OUT std_logic_vector(6 DOWNTO 0)
		);
	end component;
end package;