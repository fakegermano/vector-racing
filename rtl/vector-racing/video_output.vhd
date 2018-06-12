library ieee;
use ieee.std_logic_1164.all;
use work.vracing_pack.all;

entity video_output is
	port (
		clk							: in std_logic;
		vga_r, vga_g, vga_b 		: out std_logic_vector(7 downto 0);
		vga_hs, vga_vs 			: out std_logic;
		vga_blank_n, vga_sync_n : out std_logic;
		vga_clk 						: out std_logic;
		ps2_dat, ps2_clk 			: inout std_logic;
		we								: in std_logic;
		addr							: in integer range 0 to ADDR_MAX;
		data 							: in pixel_t;
		reset 						: in std_logic;
		collide						: out std_logic;
		game_over					: in std_logic
	);
end video_output;

architecture rtl of video_output is
	signal sync, blank : std_logic;
	signal screen_p, track_p, to_screen, over_p : pixel_t;
begin
	-- VGA rtl
	-- Aqui instanciamos o controlador de vídeo, 128 colunas por 96 linhas
	-- (aspect ratio 4:3). Os sinais que iremos utilizar para comunicar
	-- com a memória de vídeo (para alterar o brilho dos pixels) são
	-- write_clk (nosso clock), write_enable ('1' quando queremos escrever
	-- o valor de um pixel), write_addr (endereço do pixel a escrever)
	-- e data_in (valor do brilho do pixel RGB, 1 bit pra cada componente de cor)
	vga_controller: entity work.vgacon generic map (NUM_HORZ_PIXELS => H_PIXELS, NUM_VERT_PIXELS => V_PIXELS) 
											port map (
												clk50M       => clk,
												rstn         => '1',
												red          => vga_r,
												green        => vga_g,
												blue         => vga_b,
												hsync        => vga_hs,
												vsync        => vga_vs,
												write_clk    => clk,
												write_enable => we,
												write_addr   => addr,
												data_in      => to_screen,
												vga_clk      => vga_clk,
												sync         => sync,
												blank        => blank
	);
	vga_sync_n <= NOT sync;
	vga_blank_n <= NOT blank;
	
	process (clk)
		variable pix : pixel_t;
	begin
		if rising_edge(clk) then
			if game_over = '1' then 
				pix := over_p;
			elsif track_p = WHITE AND screen_p /= BLACK then
				pix := screen_p;
			elsif track_p = BLACK AND screen_p = YELLOW then
				pix := screen_p;
			elsif track_p = WHITE AND data /= BLACK then
				pix := data;
			elsif track_p = BLACK AND data /= BLACK then
				pix := data;
			else 
				pix := track_p;
			end if;
		end if;
		to_screen <= pix;
	end process;
	
	process (clk, reset)
		variable col : std_logic := '0';
	begin
		if reset = '0' then
			col := '0';
			collide <= col;
		elsif rising_edge(clk) then
			if data = BLUE and track_p = WHITE then
				col := '1';
			else
				col := col;
			end if;
			collide <= col;
		end if;
	end process;
	
	screen_ram: work.screen_ram port map (
		clk => clk,
		raddr => addr,
		q => screen_p
	);
	
	track_ram: work.track_ram port map (
		clk => clk,
		raddr => addr,
		q => track_p
	);
	
	over_ram: work.over_ram port map (
		clk => clk,
		raddr => addr,
		q => over_p
	);
end rtl;