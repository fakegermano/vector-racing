library ieee;
use ieee.std_logic_1164.all;

entity kbd_alphanum is
  port (
    clk : in std_logic;
    key_on : in std_logic_vector(2 downto 0);
    key_code : in std_logic_vector(47 downto 0);
    HEX1 : out std_logic_vector(6 downto 0); -- GFEDCBA
    HEX0 : out std_logic_vector(6 downto 0) -- GFEDCBA
  );
end kbd_alphanum;

architecture rtl of kbd_alphanum is
	component bin2hex
		port (
			SW  : in std_logic_vector(3 downto 0);
			HEX0: out std_logic_vector(6 downto 0)
		);
	end component;
	component code_to_asci
		port (
			scancode: in std_logic_vector(15 downto 0);
			upper: in std_logic;
			asci: out std_logic_vector(7 downto 0)
		);
	end component;
	signal output_code: std_logic_vector(15 downto 0);
	signal asci_code: std_logic_vector(7 downto 0);
	signal shift, caps: std_logic;
begin
	hexseg0: bin2hex port map (SW => asci_code(3 downto 0), HEX0 => HEX0);
	hexseg1: bin2hex port map (SW => asci_code(7 downto 4), HEX0 => HEX1);
	
	process (clk, key_on)
	begin
		if rising_edge(clk) then
			if key_on(0) = '1' AND key_code(15 downto 0) = x"0058" then
				caps <= '1' XOR caps;
			end if;
			if key_on(1) = '1' AND key_code(31 downto 16) = x"0058" then
				caps <= '1' XOR caps;
			end if;
			if key_on(2) = '1' AND key_code(47 downto 32) = x"0058" then
				caps <= '1' XOR caps;
			end if;
		end if;
	end process;
	
	process (clk, key_on)
	begin
		if rising_edge(clk) and key_on(0) = '1' then
			if key_on(1) = '1' then
				case (key_code(15 downto 0)) is
					when x"0012" => 
						output_code <= key_code(31 downto 16);
						shift <= '1';
					when x"0059" => 
						output_code <= key_code(31 downto 16);
						shift <= '1';
					when others => 
						output_code <= key_code(15 downto 0);
						shift <= '0';
				end case;
			else
				output_code <= key_code(15 downto 0);
				shift <= '0';
			end if;
		elsif rising_edge(clk) then
			output_code <= x"0000";
			shift <= '0';
		end if;
	end process;
	
	
	decode: code_to_asci port map (scancode => output_code, upper => shift XOR caps, asci => asci_code);
end rtl;
