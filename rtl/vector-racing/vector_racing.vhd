library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.vracing_pack.all;

entity vector_racing is 
	port (
		CLOCK_50                  	: in  std_logic;
		KEY                       	: in  std_logic_vector(0 downto 0);
		VGA_R, VGA_G, VGA_B       	: out std_logic_vector(7 downto 0);
		VGA_HS, VGA_VS            	: out std_logic;
		VGA_BLANK_N, VGA_SYNC_N   	: out std_logic;
		VGA_CLK                   	: out std_logic;
		PS2_DAT 							: inout STD_LOGIC;
		PS2_CLK 							: inout STD_LOGIC;
		LEDR								: out STD_LOGIC_VECTOR(9 downto 0)
	);
end vector_racing;

architecture rtl of vector_racing is
	signal rstn : std_logic;              -- reset active low para nossos
												 -- circuitos sequenciais.

	-- Interface com a memória de vídeo do controlador

	signal we : std_logic;                        -- write enable ('1' p/ escrita)
	signal addr : integer range 0 to ADDR_MAX;       -- endereco mem. vga
	signal pixel : pixel_t;  -- valor de cor do pixel

	-- Sinais dos contadores de linhas e colunas utilizados para percorrer
	-- as posições da memória de vídeo (pixels) no momento de construir um quadro.
  
	signal line : integer range 0 to V_PIXELS-1;  -- linha atual
	signal col : integer range 0 to H_PIXELS-1;  -- coluna atual

	signal col_rstn : std_logic;          -- reset do contador de colunas
	signal col_enable : std_logic;        -- enable do contador de colunas

	signal line_rstn : std_logic;          -- reset do contador de linhas
	signal line_enable : std_logic;        -- enable do contador de linhas

	signal fim_escrita : std_logic;       -- '1' quando um quadro terminou de ser
													 -- escrito na memória de vídeo

	-- Sinais que armazem a posição de uma bola, que deverá ser desenhada
	-- na tela de acordo com sua posição.

	signal pos_x : integer range 0 to H_PIXELS-1 := INI_X;  -- coluna atual da bola
	signal pos_y : integer range 0 to V_PIXELS-1 := INI_Y;   -- linha atual da bola
	
	
	signal vel_vector : velocity_t := ZERO_V;
	signal vel_vector_q : velocity_t := ZERO_V;
	signal vel_w, vel_s, vel_a, vel_d : velocity_t := ZERO_V;
	-- Especificação dos tipos e sinais da máquina de estados de controle
	type estado_t is (show_splash, inicio, constroi_quadro, move_bola);
	signal estado: estado_t := show_splash;
	signal proximo_estado: estado_t := show_splash;

	-- Sinais para um contador utilizado para atrasar a atualização da
	-- posição da bola, a fim de evitar que a animação fique excessivamente
	-- veloz. Aqui utilizamos um contador de 0 a 1250000, de modo que quando
	-- alimentado com um clock de 50MHz, ele demore 25ms (40fps) para contar até o final.
  
	signal contador : integer range 0 to 1250000 - 1;  -- contador
	signal timer : std_logic;        -- vale '1' quando o contador chegar ao fim
	signal timer_rstn, timer_enable : std_logic;
	
	-- KBD stuff
  
	signal key_on : std_logic_vector(2 downto 0);
	signal key_on_q : std_logic_vector(2 downto 0);
	signal key_code : std_logic_vector(47 downto 0);
	
	
	-- new stuff
	signal get_velocity : std_logic;
	signal get_velocity_q : std_logic;
	
	signal choice : std_logic_vector(2 downto 0);
	signal reset : std_logic;
	
	signal track_pixel : pixel_t;
	signal reset_alt : std_logic;
	
	signal rstn_full : std_logic;
	signal collision : std_logic;
	signal got_out : std_logic;
	
	signal game_over_signal	: std_logic;
begin 
	video_output_controller: work.video_output port map (
		clk => CLOCK_50,
		vga_r => VGA_R, vga_g => VGA_G, vga_b => VGA_B,
		vga_hs => VGA_HS, vga_vs => VGA_VS,
		vga_blank_n => VGA_BLANK_N, vga_sync_n => VGA_SYNC_N,
		vga_clk => VGA_CLK,
		ps2_dat => PS2_DAT, ps2_clk => PS2_CLK,
		we => we,
		addr => addr,
		data => pixel,
		reset => rstn_full,
		collide => collision,
		game_over => game_over_signal
	);
	LEDR(0) <= rstn;
	LEDR(1) <= reset_alt;
	rstn_full <= rstn AND reset_alt;
	-----------------------------------------------------------------------------
	-- Processos que controlam contadores de linhas e coluna para varrer
	-- todos os endereços da memória de vídeo, no momento de construir um quadro.
	-----------------------------------------------------------------------------	

	-- purpose: Este processo conta o número da coluna atual, quando habilitado
	--          pelo sinal "col_enable".
	-- type   : sequential
	-- inputs : CLOCK_50, col_rstn
	-- outputs: col
	conta_coluna: process (CLOCK_50, col_rstn)
	begin  -- process conta_coluna
		if col_rstn = '0' then                  -- asynchronous reset (active low)
			col <= 0;
		elsif rising_edge(CLOCK_50) then  -- rising clock edge
			if col_enable = '1' then
				if col = 127 then               -- conta de 0 a 127 (128 colunas)
					col <= 0;
				else
					col <= col + 1;  
				end if;
			end if;
		end if;
	end process conta_coluna;
    
	-- purpose: Este processo conta o número da linha atual, quando habilitado
	--          pelo sinal "line_enable".
	-- type   : sequential
	-- inputs : CLOCK_50, line_rstn
	-- outputs: line
	conta_linha: process (CLOCK_50, line_rstn)
	begin  -- process conta_linha
		if line_rstn = '0' then                  -- asynchronous reset (active low)
			line <= 0;
		elsif rising_edge(CLOCK_50) then  -- rising clock edge
			-- o contador de linha só incrementa quando o contador de colunas
			-- chegou ao fim (valor 127)
			if line_enable = '1' and col = 127 then
				if line = 95 then               -- conta de 0 a 95 (96 linhas)
					line <= 0;
				else
					line <= line + 1;  
				end if;        
			end if;
		end if;
	end process conta_linha;

	-- Este sinal é útil para informar nossa lógica de controle quando
	-- o quadro terminou de ser escrito na memória de vídeo, para que
	-- possamos avançar para o próximo estado.
	fim_escrita <= '1' when (line = 95) and (col = 127)
						else '0'; 
	
	-- get the velocity
	p_get_vel: process (CLOCK_50)
		variable t_vel: velocity_t := ZERO_V;
	begin
		if rising_edge(CLOCK_50) then
			if get_velocity = '1' then
				case choice is
					when W =>
						t_vel := vel_w;
					when S =>
						t_vel := vel_s;
					when D =>
						t_vel := vel_d;
					when A =>
						t_vel := vel_a;
					when SPACE =>
						t_vel := vel_vector;
					when others =>
				end case;
			else
				t_vel := t_vel;
			end if;
		end if;
		vel_vector_q <= t_vel;
	end process p_get_vel;
	
	process(CLOCK_50)
		variable temp: std_logic;
	begin
		if rising_edge(CLOCK_50) then
			temp := get_velocity;
			get_velocity_q <= temp;
		end if;
	end process;
	
	-- change pos
	p_change_pos: process(CLOCK_50)
		variable r : std_logic := '0';
	begin
		if rstn_full = '0' then
			pos_x <= INI_X;
			pos_y <= INI_Y;
			vel_vector <= ZERO_V;
			r := '0';
			got_out <= '0';
		elsif rising_edge(CLOCK_50) then
			if get_velocity_q = '1' and get_velocity = '0' then
				pos_x <= pos_x + to_integer(vel_vector_q(0));
				pos_y <= pos_y + to_integer(vel_vector_q(1));
				vel_vector <= vel_vector_q;
				r := '0';
			else
				pos_x <= pos_x;
				pos_y <= pos_y;
				vel_vector <= vel_vector;
				r := '1';
			end if;
			if pos_x >= H_PIXELS OR pos_y >= V_PIXELS OR pos_x < 0 OR pos_y < 0 then
				got_out <= '1';
			else
				got_out <= '0';
			end if;
		end if;
		reset <= r;
	end process p_change_pos;
	-- Cuida do preview da posicao que o jogador chegaria com o vetor atual 
	-- e seleciona o input tambem
	preview_process: work.preview port map (	clk => CLOCK_50,
															key_on => key_on,
															key_code => key_code,
															vector => vel_vector,
															vector_w => vel_w,
															vector_s => vel_s,
															vector_a => vel_a,
															vector_d => vel_d,
															get_vel => get_velocity,
															reset => reset,
															choice => choice
														);
	collision_detection: process (CLOCK_50) 
		variable t : std_logic := '1';
	begin
		if rstn_full = '0' then
			t := '1';
		elsif rising_edge(CLOCK_50) then
			if game_over_signal = '1' AND get_velocity = '0' AND get_velocity_q = '1' then
				t := '0';
			else
				t := t;
			end if;
		end if;
		reset_alt <= t;
	end process collision_detection;
	
	game_over: process (CLOCK_50)
		variable t : std_logic := '0';
	begin
		if rstn_full = '0' then 
			t := '0';
		elsif rising_edge(CLOCK_50) then
			if collision = '1' OR got_out = '1' then
				t := '1';
			else
				t := t;
			end if;
		end if;
		game_over_signal <= t;
	end process game_over;
	-----------------------------------------------------------------------------
	-- Brilho do pixel
	-----------------------------------------------------------------------------
	-- O brilho do pixel é branco quando os contadores de linha e coluna, que
	-- indicam o endereço do pixel sendo escrito para o quadro atual, casam com a
	-- posição da bola (sinais pos_x e pos_y). Caso contrário,
	-- o pixel é preto.
  
	put_color: process (CLOCK_50, rstn) 
	begin
		if rstn_full = '0' then
			pixel <= BLACK;
		elsif rising_edge(CLOCK_50) then
			if col = pos_x AND line = pos_y then
				pixel <= BLUE;
			elsif (col = pos_x + to_integer(vel_vector(0))) AND (line = pos_y + to_integer(vel_vector(1))) then
				if choice = SPACE then
					pixel <= RED;
				else
					pixel <= PINK;
				end if;
			elsif (col = pos_x + to_integer(vel_w(0))) AND (line = pos_y + to_integer(vel_w(1))) then
				if choice = W then
					pixel <= RED;
				else
					pixel <= PINK;
				end if;
			elsif (col = pos_x + to_integer(vel_a(0))) AND (line = pos_y + to_integer(vel_a(1))) then
				if choice = A then
					pixel <= RED;
				else
					pixel <= PINK;
				end if;
			elsif (col = pos_x + to_integer(vel_s(0))) AND (line = pos_y + to_integer(vel_s(1))) then
				if choice = S then
					pixel <= RED;
				else
					pixel <= PINK;
				end if;
			elsif (col = pos_x + to_integer(vel_d(0))) AND (line = pos_y + to_integer(vel_d(1))) then
				if choice = D then
					pixel <= RED;
				else
					pixel <= PINK;
				end if;
			else 
				pixel <= BLACK;
			end if;
		end if;
	end process put_color;
  
  
	-- O endereço de memória pode ser construído com essa fórmula simples,
	-- a partir da linha e coluna atual
	addr  <= col + (128 * line);

	-----------------------------------------------------------------------------
	-- Processos que definem a FSM (finite state machine), nossa máquina
	-- de estados de controle.
	-----------------------------------------------------------------------------
	
	-- purpose: Esta é a lógica combinacional que calcula sinais de saída a partir
	--          do estado atual e alguns sinais de entrada (Máquina de Mealy).
	-- type   : combinational
	-- inputs : estado, fim_escrita, timer
	-- outputs: proximo_estado, atualiza_pos_x, atualiza_pos_y, line_rstn,
	--          line_enable, col_rstn, col_enable, we, timer_enable, timer_rstn
	logica_mealy: process (estado, fim_escrita, timer)
	begin  -- process logica_mealy
		case estado is
			when inicio			=> if timer = '1' then              
											proximo_estado <= constroi_quadro;
										else
											proximo_estado <= inicio;
										end if;
										line_rstn      <= '0';  -- reset é active low!
										line_enable    <= '0';
										col_rstn       <= '0';  -- reset é active low!
										col_enable     <= '0';
										we             <= '0';
										timer_rstn     <= '1';  -- reset é active low!
										timer_enable   <= '1';
	
			when constroi_quadro=> if fim_escrita = '1' then
											proximo_estado <= move_bola;
										else
											proximo_estado <= constroi_quadro;
										end if;
										line_rstn      <= '1';
										line_enable    <= '1';
										col_rstn       <= '1';
										col_enable     <= '1';
										we             <= '1';
										timer_rstn     <= '0'; 
										timer_enable   <= '0';
	
			when move_bola      => proximo_estado <= inicio;
										line_rstn      <= '1';
										line_enable    <= '0';
										col_rstn       <= '1';
										col_enable     <= '0';
										we             <= '0';
										timer_rstn     <= '0'; 
										timer_enable   <= '0';
	
			when others         =>	if fim_escrita = '1' then
												proximo_estado <= inicio;
											else
												proximo_estado <= show_splash;
											end if;
											line_rstn      <= '1';
											line_enable    <= '1';
											col_rstn       <= '1';
											col_enable     <= '1';
											we             <= '1';
											timer_rstn     <= '0'; 
											timer_enable   <= '0';
			
		end case;
	end process logica_mealy;
  
	-- purpose: Avança a FSM para o próximo estado
	-- type   : sequential
	-- inputs : CLOCK_50, rstn, proximo_estado
	-- outputs: estado
	seq_fsm: process (CLOCK_50, rstn)
	begin  -- process seq_fsm
		if rstn_full = '0' then                  -- asynchronous reset (active low)
			estado <= show_splash;
		elsif rising_edge(CLOCK_50) then  -- rising clock edge
			estado <= proximo_estado;
		end if;
	end process seq_fsm;
  
	-----------------------------------------------------------------------------
	-- Processos do contador utilizado para atrasar a animação (evitar
	-- que a atualização de quadros fique excessivamente veloz).
	-----------------------------------------------------------------------------
	-- purpose: Incrementa o contador a cada ciclo de clock
	-- type   : sequential
	-- inputs : CLOCK_50, timer_rstn
	-- outputs: contador, timer
	p_contador: process (CLOCK_50, timer_rstn)
	begin  -- process p_contador
		if timer_rstn = '0' then            -- asynchronous reset (active low)
			contador <= 0;
		elsif rising_edge(CLOCK_50) then  -- rising clock edge
			if timer_enable = '1' then       
				if contador = 1250000 - 1 then
					contador <= 0;
				else
					contador <=  contador + 1;        
			end if;
		end if;
	end if;
	end process p_contador;
	
	
	-- purpose: Calcula o sinal "timer" que indica quando o contador chegou ao
	--          final
	-- type   : combinational
	-- inputs : contador
	-- outputs: timer
	p_timer: process (contador)
	begin  -- process p_timer
		if contador = 1250000 - 1 then
			timer <= '1';
		else
			timer <= '0';
		end if;
	end process p_timer;

	-----------------------------------------------------------------------------
	-- Processos que sincronizam sinais assíncronos, de preferência com mais
	-- de 1 flipflop, para evitar metaestabilidade.
	-----------------------------------------------------------------------------
	
	-- purpose: Aqui sincronizamos nosso sinal de reset vindo do botão da DE1
	-- type   : sequential
	-- inputs : CLOCK_50
	-- outputs: rstn
	build_rstn: process (CLOCK_50)
		variable temp : std_logic;          -- flipflop intermediario
	begin  -- process build_rstn
		if rising_edge(CLOCK_50) then  -- rising clock edge
			rstn <= temp;
			temp := KEY(0);      
		end if;
	end process build_rstn;
  
	-- KBD rtl
	kbdex_ctrl_inst : work.kbdex_ctrl
		generic map (
			clkfreq => 50000
		)
		port map (
			ps2_data => PS2_DAT,
			ps2_clk => PS2_CLK,
			clk => CLOCK_50,
			en => '1',
			resetn => '1',
			lights => "111",
			key_on => key_on,
			key_code => key_code
		);
end rtl;