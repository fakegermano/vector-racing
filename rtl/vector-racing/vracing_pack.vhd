library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package vracing_pack is
	-- types
	constant V_WSIZE : integer := 9;
	constant W : std_logic_vector(2 downto 0) := "000";
	constant S : std_logic_vector(2 downto 0) := "001";
	constant A : std_logic_vector(2 downto 0) := "010";
	constant D : std_logic_vector(2 downto 0) := "011";
	constant SPACE : std_logic_vector(2 downto 0) := "100";
	constant SPEED_UP : integer := 3;
	constant SPEED_DOWN : integer := -3;
	subtype vcoordinate_t is signed(V_WSIZE-1 downto 0);
	type velocity_t is array(0 to 1) of vcoordinate_t;
	constant ZERO_V : velocity_t := (to_signed(0, V_WSIZE), to_signed(0, V_WSIZE));
	constant SOME_V : velocity_t := (to_signed(2, V_WSIZE), to_signed(3, V_WSIZE));
	
	constant INI_X : integer := 30;
	constant INI_Y : integer := 8;
	constant V_PIXELS : integer := 96;
	constant H_PIXELS : integer := 128;
	subtype coord_y is integer range 0 to V_PIXELS-1;
	subtype coord_x is integer range 0 to H_PIXELS-1;
	constant ADDR_MAX : integer := (V_PIXELS * H_PIXELS) - 1;
	
	subtype pixel_t is std_logic_vector(2 downto 0);
	constant BLACK : pixel_t := "000";
	constant WHITE : pixel_t := "111";
	constant RED : pixel_t := "100";
	constant BLUE : pixel_t := "001";
	constant PINK : pixel_t := "101";
	constant YELLOW : pixel_t := "110";
	type screen_mem is array(0 to ADDR_MAX) of pixel_t;
	
	subtype filename is string;
end package;