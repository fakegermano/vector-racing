library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package vracing_pack is
	-- types
	constant V_WSIZE : integer := 4;
	subtype vcoordinate_t is signed(V_WSIZE-1 downto 0); -- de -8 a +7
	type velocity_t is array(0 to 1) of vcoordinate_t;
	constant ZERO_V : velocity_t := (to_signed(0, V_WSIZE), to_signed(0, V_WSIZE));
end package;