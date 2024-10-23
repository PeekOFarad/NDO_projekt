
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.VGA_pkg.all;

entity VGA_ctrl_tb is
end;

architecture bench of VGA_ctrl_tb is
  -- Clock period
  constant clk_period : time := 5 ns;
  -- Ports
  signal PIXEL_CLK  : std_logic := '0';
  signal RST_P      : std_logic := '0';
  signal H_SYNC     : std_logic;
  signal V_SYNC     : std_logic;
  signal DISP_ENA   : std_logic;
  signal COLUMN     : std_logic_vector(c_cnt_h_w-1 downto 0);
  signal ROW        : std_logic_vector(c_cnt_v_w-1 downto 0);
  signal N_BLANK    : std_logic;
  signal N_SYNC     : std_logic;

  signal DATA         : std_logic_vector(15 downto 0) := x"5555";
  signal RW_ADDR      : std_logic_vector(17 downto 0);
  signal PIXEL_DATA   : std_logic;
  signal OE_N         : std_logic;
  signal WE_N         : std_logic;
  signal LB_N         : std_logic;
  signal UB_N         : std_logic;

begin

  VGA_ctrl_inst : entity work.VGA_ctrl
  port map (
    PIXEL_CLK   => PIXEL_CLK,
    RST_P       => RST_P,
    H_SYNC      => H_SYNC,
    V_SYNC      => V_SYNC,
    COLUMN      => COLUMN,
    ROW         => ROW
  );
  
  VGA_sram_mux_inst : entity work.VGA_sram_mux
  generic map (
    g_SRAM_OFFSET => 0
  )
  port map (
    CLK         => PIXEL_CLK,
    RST         => RST_P,
    COLUMN      => COLUMN,
    ROW         => ROW,
    DATA        => DATA,
    PIXEL_DATA  => PIXEL_DATA,
    RW_ADDR     => RW_ADDR,
    OE_N        => OE_N,
    WE_N        => WE_N,
    LB_N        => LB_N,
    UB_N        => UB_N
  );


PIXEL_CLK <= not PIXEL_CLK after clk_period/2;

DATA <= (others => 'Z'), x"5555" after clk_period*800*530;

end;