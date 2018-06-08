library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.vracing_pack.all;

entity preview is
	port (
		clk: in std_logic;
		key_on: in std_logic_vector(2 downto 0);
		key_code: in std_logic_vector(47 downto 0);
		vector: inout velocity_t;
		led : out std_logic_vector(4 downto 0)
		);
end preview;

architecture rtl of preview is
	type state_type is (zero, direita, esquerda, cima, baixo);
	signal state : state_type := zero;
	signal key_on_q : std_logic_vector(2 downto 0);
	signal vector_t: velocity_t := vector;
	signal pressed : std_logic_vector(1 downto 0) := "00";
	signal reset : std_logic := '0';
	signal state_slv : std_logic_vector(2 downto 0);
begin
	process (clk)
	begin
		if clk'event and clk = '1' then
			key_on_q <= key_on;
		end if;
	end process;
	
	preview: process (clk)
	begin
		if clk'event and clk = '1' then
			if key_on(0) = '1' AND key_on_q(0) = '0' then
				if (key_code(7 downto 0) = x"1D") then -- w 
					pressed <= "00";
				elsif key_code(7 downto 0) = x"1B" then -- s
					pressed <= "01";
				elsif key_code(7 downto 0) = x"23" then -- d
					pressed <= "10";
				elsif key_code(7 downto 0) = x"1C" then -- a
					pressed <= "11";
				else 
					pressed <= pressed;
				end if;
			else
				pressed <= pressed;
			end if;
		end if;
	end process preview;
	led(4 downto 3) <= pressed;
	led(2 downto 0) <= state_slv;
	
	fsm: process (clk, reset, pressed)
	begin
		if reset <= '1' then
			state <= zero;
		elsif clk'event and clk = '1' then
			case state is
				when zero =>
					case pressed is
						when "00" => -- w
							state <= cima;
						when "01" => -- s
							state <= baixo;
						when "10" => -- a
							state <= direita;
						when "11" => -- d
							state <= esquerda;
					end case;
				when cima =>
					case pressed is
						when "00" => -- w
							state <= cima;
						when "01" => -- s
							state <= zero;
						when "10" => -- a
							state <= direita;
						when "11" => -- d
							state <= esquerda;
					end case;
				when baixo =>
					case pressed is
						when "00" => -- w
							state <= zero;
						when "01" => -- s
							state <= baixo;
						when "10" => -- a
							state <= direita;
						when "11" => -- d
							state <= esquerda;
					end case;
				when esquerda =>
					case pressed is
						when "00" => -- w
							state <= cima;
						when "01" => -- s
							state <= baixo;
						when "10" => -- a
							state <= zero;
						when "11" => -- d
							state <= esquerda;
					end case;
				when direita =>
					case pressed is
						when "00" => -- w
							state <= cima;
						when "01" => -- s
							state <= baixo;
						when "10" => -- a
							state <= direita;
						when "11" => -- d
							state <= zero;
					end case;
			end case;
		end if;
	end process fsm;
	
	fsm_output: process (state)
		variable inc : velocity_t := (to_signed(0, V_WSIZE), to_signed(0, V_WSIZE));
	begin
		case state is
			when zero =>
				inc := (to_signed(0, V_WSIZE), to_signed(0, V_WSIZE)); -- <0, 0>
				state_slv <= "111";
			when cima =>
				inc := (to_signed(0, V_WSIZE), to_signed(-1, V_WSIZE)); -- <0, -1>
				state_slv <= "001";
			when baixo =>
				inc := (to_signed(0, V_WSIZE), to_signed(1, V_WSIZE)); -- <0, +1>
				state_slv <= "010";
			when esquerda =>
				inc := (to_signed(-1, V_WSIZE), to_signed(0, V_WSIZE)); -- <-1, 0>
				state_slv <= "011";
			when direita =>
				inc := (to_signed(1, V_WSIZE), to_signed(0, V_WSIZE)); -- <1, 0>
				state_slv <= "100";
		end case;
		vector_t(0) <= vector_t(0) + inc(0);
		vector_t(1) <= vector_t(1) + inc(1);
	end process fsm_output;
	
	vector <= vector_t;
end rtl;


