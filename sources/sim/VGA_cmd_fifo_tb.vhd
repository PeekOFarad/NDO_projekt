library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.math_real.all;
use work.VGA_pkg.all;
use work.server_pkg.all;

entity VGA_cmd_fifo_tb is
end;

architecture bench of VGA_cmd_fifo_tb is
  -- Clock period
  constant clk_period : time := 5 ns;
  -- constant
  constant boob_cell : char_buff_t := (
    x"31",
    x"3e",
    x"3e",
    x"31",
    x"30",
    x"42",
    x"03",
    x"03",
    x"03",
    x"03",
    x"03",
    x"03",
    x"03",
    x"03",
    x"03",
    x"03",
    x"03",
    x"03",
    x"03",
    x"03",
    x"03",
    x"03",
    x"03",
    x"03",
    x"03",
    x"03",
    x"03",
    x"03",
    x"03",
    x"03",
    x"03",
    x"03"
    );
  constant ass_cell : char_buff_t := (
    x"30",
    x"42",
    x"42",
    x"03",
    x"03",
    x"42",
    x"03",
    x"03",
    x"03",
    x"03",
    x"03",
    x"03",
    x"03",
    x"03",
    x"03",
    x"03",
    x"03",
    x"03",
    x"03",
    x"03",
    x"03",
    x"03",
    x"03",
    x"03",
    x"03",
    x"03",
    x"03",
    x"03",
    x"03",
    x"03",
    x"03",
    x"03"
    );
  -- Ports
  signal CLK : std_logic := '0';
  signal RST : std_logic;
  signal COL_SYS : STD_LOGIC_VECTOR (2 downto 0) := std_logic_vector(to_unsigned(1, 3));
  signal ROW_SYS : STD_LOGIC_VECTOR (5 downto 0) := (others => '0');
  signal UPD_ARR : STD_LOGIC := '0';
  signal UPD_DATA : STD_LOGIC;
  signal DATA_SYS : char_buff_t := (
    x"31",
    x"3e",
    x"3e",
    x"31",
    x"30",
    x"42",
    x"03",
    x"03",
    x"03",
    x"03",
    x"03",
    x"03",
    x"03",
    x"03",
    x"03",
    x"03",
    x"03",
    x"03",
    x"03",
    x"03",
    x"03",
    x"03",
    x"03",
    x"03",
    x"03",
    x"03",
    x"03",
    x"03",
    x"03",
    x"03",
    x"03",
    x"03"
    );
  
  signal FIFO_REN : std_logic;
  signal WADDR_C : std_logic_vector(17 downto 0);
  signal DATA_O : std_logic_vector(15 downto 0);
  signal WE_N_D2 : std_logic;
  signal LB_N_W : std_logic;
  signal UB_N_W : std_logic;
  signal V_PORCH_N : std_logic := '1';
  signal PIXEL_CLK  : std_logic := '0';
  signal VGA_RDY  : std_logic := '0';

begin


  process (CLK)
	begin
		if rising_edge(CLK) then
			PIXEL_CLK <= NOT PIXEL_CLK;
		end if;
	end process;
  
  VGA_cmd_fifo_inst : entity work.VGA_cmd_fifo
  port map (
    CLK       => PIXEL_CLK,
    RST       => RST,
    COL_SYS   => COL_SYS,
    ROW_SYS   => ROW_SYS,
    UPD_ARR   => UPD_ARR,
    UPD_DATA  => UPD_DATA,
    DATA_SYS  => DATA_SYS,
    VGA_RDY   => VGA_RDY,
    FIFO_REN  => not V_PORCH_N,
    WADDR_C   => WADDR_C,
    DATA_O    => DATA_O,
    WE_N_D2   => WE_N_D2,
    LB_N_W    => LB_N_W,
    UB_N_W    => UB_N_W
  );

  clk <= not clk after clk_period/2;
 
  RST <= '1', '0' after clk_period*10;

  UPD_DATA  <= '0', '1' after clk_period*10, '0' after clk_period*12, '1' after clk_period*220, '0' after clk_period*222;
  UPD_ARR   <= '0', '1' after clk_period*350, '0' after clk_period*352;

  DATA_SYS  <= boob_cell, ass_cell after clk_period*350;
  COL_SYS   <= std_logic_vector(to_unsigned(1, 3)), std_logic_vector(to_unsigned(2, 3)) after clk_period*350;
  ROW_SYS   <= (others => '0');

  V_PORCH_N <= '1', '0' after clk_period*100;

end;