library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity top_sdram is
    generic (
	C_clk_freq: natural := 80
    );
    port (
	clk_25mhz: in std_logic;

	-- '1' = power off
	shutdown: out std_logic := '0';

	-- SDRAM
	sdram_clk: out std_logic;
	sdram_cke: out std_logic;
	sdram_csn: out std_logic;
	sdram_rasn: out std_logic;
	sdram_casn: out std_logic;
	sdram_wen: out std_logic;
	sdram_a: out std_logic_vector (12 downto 0);
	sdram_ba: out std_logic_vector(1 downto 0);
	sdram_dqm: out std_logic_vector(1 downto 0);
	sdram_d: inout std_logic_vector (15 downto 0);

	-- On-board simple IO
	led: out std_logic_vector(7 downto 0);
	btn: in std_logic_vector(6 downto 0);
	sw: in std_logic_vector(3 downto 0);

	-- GPIO
	gp: inout std_logic_vector(27 downto 0) := (others => 'Z');
	gn: inout std_logic_vector(27 downto 0) := (others => 'Z');

	-- Audio jack 3.5mm
	audio_l: inout std_logic_vector(3 downto 0) := (others => 'Z');
	audio_r: inout std_logic_vector(3 downto 0) := (others => 'Z');
	audio_v: inout std_logic_vector(3 downto 0) := (others => 'Z');

	-- SIO0 (FTDI)
	ftdi_rxd: out std_logic;
	ftdi_txd: in std_logic;

	-- SIO1 (ESP32)
	wifi_rxd: out std_logic;
	wifi_txd: in std_logic;
	wifi_en: out std_logic := '0'
    );
end top_sdram;

architecture x of top_sdram is
    signal clk, pll_lock: std_logic;
    signal clk_133m, clk_66m, clk_160m, clk_80m: std_logic;
    signal reset: std_logic;
    signal sio_break: std_logic;

begin
    I_top: entity work.glue_sdram_min
    generic map (
	C_clk_freq => C_clk_freq,
	C_debug => false
    )
    port map (
	clk => clk,
	reset => reset,
	sdram_clk => sdram_clk,
	sdram_cke => sdram_cke,
	sdram_cs => sdram_csn,
	sdram_we => sdram_wen,
	sdram_ba => sdram_ba,
	sdram_dqm => sdram_dqm,
	sdram_ras => sdram_rasn,
	sdram_cas => sdram_casn,
	sdram_addr => sdram_a,
	sdram_data => sdram_d,
	sio_rxd(0) => ftdi_txd,
	sio_txd(0) => ftdi_rxd,
	sio_break(0) => sio_break,
	simple_in(31 downto 20) => (others => '0'),
	simple_in(19 downto 16) => sw,
	simple_in(15 downto 7) => (others => '0'),
	simple_in(6 downto 1) => btn(6 downto 1), -- r l d up f2 f1
	simple_in(0) => not btn(0), -- pwr
	simple_out(31 downto 8) => open,
	simple_out(7 downto 0) => led
    );

    I_pll: entity work.pll
    port map (
	clki => clk_25mhz,
	stdby => '0',
	enclk_133m => '1',
	enclk_66m => '1',
	enclk_160m => '1',
	enclk_80m => '1',
	clk_133m => clk_133m,
	clk_66m => clk_66m,
	clk_160m => clk_160m,
	clk_80m => clk_80m,
	lock => pll_lock 
    );

    clk <= clk_160m when C_clk_freq = 160
      else clk_133m when C_clk_freq = 133
      else clk_80m when C_clk_freq = 80
      else clk_66m;
    reset <= not pll_lock or sio_break;
end x;