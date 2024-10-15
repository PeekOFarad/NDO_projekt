
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
  signal H_SYNC : std_logic;
  signal V_SYNC : std_logic;
  signal DISP_ENA : std_logic;
  signal COLUMN : std_logic_vector(c_cnt_h_w-1 downto 0);
  signal ROW : std_logic_vector(c_cnt_v_w-1 downto 0);
  signal N_BLANK : std_logic;
  signal N_SYNC : std_logic;
begin

  VGA_ctrl_inst : entity work.VGA_ctrl
  port map (
    PIXEL_CLK   => PIXEL_CLK,
    RST_P       => RST_P,
    H_SYNC      => H_SYNC,
    V_SYNC      => V_SYNC,
    DISP_ENA    => DISP_ENA,
    COLUMN      => COLUMN,
    ROW         => ROW,
    N_BLANK     => N_BLANK,
    N_SYNC      => N_SYNC
  );

PIXEL_CLK <= not PIXEL_CLK after clk_period/2;

end;