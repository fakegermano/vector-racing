library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package vracing_pack is
	-- types
	constant V_WSIZE : integer := 4;
	constant W : std_logic_vector(2 downto 0) := "000";
	constant S : std_logic_vector(2 downto 0) := "001";
	constant A : std_logic_vector(2 downto 0) := "010";
	constant D : std_logic_vector(2 downto 0) := "011";
	constant SPACE : std_logic_vector(2 downto 0) := "100";
	subtype vcoordinate_t is signed(V_WSIZE-1 downto 0); -- de -8 a +7
	type velocity_t is array(0 to 1) of vcoordinate_t;
	constant ZERO_V : velocity_t := (to_signed(0, V_WSIZE), to_signed(0, V_WSIZE));
	constant SOME_V : velocity_t := (to_signed(2, V_WSIZE), to_signed(3, V_WSIZE));
end package;