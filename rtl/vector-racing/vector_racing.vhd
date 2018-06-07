library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.vracing_pack.all;

entity vector_racing is 
	port (
		CLOCK_50                  	: in  std_logic;
		KEY                       	: in  std_logic_vector(2 downto 0);
		VGA_R, VGA_G, VGA_B       	: out std_logic_vector(7 downto 0);
		VGA_HS, VGA_VS            	: out std_logic;
		VGA_BLANK_N, VGA_SYNC_N   	: out std_logic;
		VGA_CLK                   	: out std_logic;
		PS2_DAT 							: inout STD_LOGIC;
		PS2_CLK 							: inout STD_LOGIC;
		HEX0								: out std_logic_vector(6 downto 0);
		HEX1								: out std_logic_vector(6 downto 0);
		HEX2								: out std_logic_vector(6 downto 0);
		HEX3								: out std_logic_vector(6 downto 0)
	);
end vector_racing;

architecture rtl of vector_racing is
	-- VGA stuff
	signal rstn : std_logic;              -- reset active low para nossos
												 -- circuitos sequenciais.

	-- Interface com a memória de vídeo do controlador

	signal we : std_logic;                        -- write enable ('1' p/ escrita)
	signal addr : integer range 0 to 12287;       -- endereco mem. vga
	signal pixel : std_logic_vector(2 downto 0);  -- valor de cor do pixel

	-- Sinais dos contadores de linhas e colunas utilizados para percorrer
	-- as posições da memória de vídeo (pixels) no momento de construir um quadro.
  
	signal line : integer range 0 to 95;  -- linha atual
	signal col : integer range 0 to 127;  -- coluna atual

	signal col_rstn : std_logic;          -- reset do contador de colunas
	signal col_enable : std_logic;        -- enable do contador de colunas

	signal line_rstn : std_logic;          -- reset do contador de linhas
	signal line_enable : std_logic;        -- enable do contador de linhas

	signal fim_escrita : std_logic;       -- '1' quando um quadro terminou de ser
													 -- escrito na memória de vídeo

	-- Sinais que armazem a posição de uma bola, que deverá ser desenhada
	-- na tela de acordo com sua posição.

	signal pos_x : integer range 0 to 127 := 30;  -- coluna atual da bola
	signal pos_y : integer range 0 to 95 := 30;   -- linha atual da bola
	
	signal vel_vector : velocity_t := ZERO_V;
	signal vel_vector_q : velocity_t := ZERO_V;
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
  
	signal sync, blank: std_logic;
  
	-- KBD stuff
  
	signal key_on : std_logic_vector(2 downto 0);
	signal key_on_q : std_logic_vector(2 downto 0);
	signal key_code : std_logic_vector(47 downto 0);
	
	
	-- new stuff
	signal get_velocity : std_logic;
	signal change_pos_q: std_logic;
	signal change_pos: std_logic;
begin 
	debug_1: work.bin2hex port map (SW => std_logic_vector(vel_vector(0))(3 downto 0), HEX => HEX0);
	debug_2: work.bin2hex port map (SW => std_logic_vector(vel_vector(1))(3 downto 0), HEX => HEX1);
	debug_3: work.bin2hex port map (SW => std_logic_vector(vel_vector_q(0))(3 downto 0), HEX => HEX2);
	debug_4: work.bin2hex port map (SW => std_logic_vector(vel_vector_q(1))(3 downto 0), HEX => HEX3);
	-- VGA rtl
	-- Aqui instanciamos o controlador de vídeo, 128 colunas por 96 linhas
	-- (aspect ratio 4:3). Os sinais que iremos utilizar para comunicar
	-- com a memória de vídeo (para alterar o brilho dos pixels) são
	-- write_clk (nosso clock), write_enable ('1' quando queremos escrever
	-- o valor de um pixel), write_addr (endereço do pixel a escrever)
	-- e data_in (valor do brilho do pixel RGB, 1 bit pra cada componente de cor)
	vga_controller: entity work.vgacon generic map (NUM_HORZ_PIXELS => 128, NUM_VERT_PIXELS => 96) 
											port map (
												clk50M       => CLOCK_50,
												rstn         => '1',
												red          => VGA_R,
												green        => VGA_G,
												blue         => VGA_B,
												hsync        => VGA_HS,
												vsync        => VGA_VS,
												write_clk    => CLOCK_50,
												write_enable => we,
												write_addr   => addr,
												data_in      => pixel,
												vga_clk      => VGA_CLK,
												sync         => sync,
												blank        => blank
	);
	VGA_SYNC_N <= NOT sync;
	VGA_BLANK_N <= NOT blank;

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
		elsif CLOCK_50'event and CLOCK_50 = '1' then  -- rising clock edge
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
		elsif CLOCK_50'event and CLOCK_50 = '1' then  -- rising clock edge
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
	
	
	-- sync switch 
	
	build_get_vel: process (CLOCK_50)
		variable temp : std_logic;          -- flipflop intermediario
	begin  -- process build_rstn
		if CLOCK_50'event and CLOCK_50 = '1' then  -- rising clock edge
			get_velocity <= temp;
			temp := not(KEY(1));      
		end if;
	end process build_get_vel;
	
	build_change_pos: process (CLOCK_50)
		variable temp : std_logic;          -- flipflop intermediario
	begin  -- process build_rstn
		if CLOCK_50'event and CLOCK_50 = '1' then  -- rising clock edge
			change_pos <= temp;
			temp := not(KEY(2));
		end if;
	end process build_change_pos;
	
	-- get the velocity
	p_get_vel: process (CLOCK_50)
		variable t_vel: velocity_t := ZERO_V;
	begin
		if CLOCK_50'event and CLOCK_50 = '1' then
			if get_velocity = '1' then
				t_vel := vel_vector;
			else
				t_vel := t_vel;
			end if;
		end if;
		vel_vector_q <= t_vel;
	end process p_get_vel;
	
	process (CLOCK_50)
	begin
		if CLOCK_50'event and CLOCK_50 = '1' then
			change_pos_q <= change_pos;
		end if;
	end process;
	
	-- change pos
	p_change_pos: process(CLOCK_50)
		variable new_pos_x : integer range 0 to 127 := pos_x;
		variable new_pos_y : integer range 0 to 95 := pos_y;
	begin
		if CLOCK_50'event and CLOCK_50 = '1' then
			if get_velocity = '0' AND change_pos = '1' AND change_pos_q = '0' then
				new_pos_x := pos_x + to_integer(vel_vector_q(0));
				new_pos_y := pos_y + to_integer(vel_vector_q(1));
			else
				new_pos_x := pos_x;
				new_pos_y := pos_y;
			end if;
		end if;
		pos_x <= new_pos_x;
		pos_y <= new_pos_y;
	end process p_change_pos;
	
	-- Cuida do preview da posicao que o jogador chegaria com o vetor atual 
	-- e seleciona o input tambem
	preview_process: work.preview port map (	clk => CLOCK_50,
															key_on => key_on,
															key_code => key_code,
															vector => vel_vector
														);
	-----------------------------------------------------------------------------
	-- Brilho do pixel
	-----------------------------------------------------------------------------
	-- O brilho do pixel é branco quando os contadores de linha e coluna, que
	-- indicam o endereço do pixel sendo escrito para o quadro atual, casam com a
	-- posição da bola (sinais pos_x e pos_y). Caso contrário,
	-- o pixel é preto.
  
	put_color: process (rstn) 
	begin
		if rstn = '0' then
			pixel <= "000";
		else
			if col = pos_x AND line = pos_y then
				pixel <= "111";
			elsif (col = pos_x + to_integer(vel_vector(0))) AND (line = pos_y + to_integer(vel_vector(1))) then
				pixel <= "100";
			else 
				pixel <= "000";
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
		if rstn = '0' then                  -- asynchronous reset (active low)
			estado <= show_splash;
		elsif CLOCK_50'event and CLOCK_50 = '1' then  -- rising clock edge
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
		elsif CLOCK_50'event and CLOCK_50 = '1' then  -- rising clock edge
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
		if CLOCK_50'event and CLOCK_50 = '1' then  -- rising clock edge
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
			lights => "000",
			key_on => key_on,
			key_code => key_code
		);
end rtl;