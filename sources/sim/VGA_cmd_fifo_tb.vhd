library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.math_real.all;
use work.VGA_pkg.all;

entity VGA_cmd_fifo_tb is
end;

architecture bench of VGA_cmd_fifo_tb is
  -- Clock period
  constant clk_period : time := 5 ns;
  -- Generics
  constant g_SRAM_OFFSET : integer := 0;
  -- Ports
  signal CLK : std_logic := '0';
  signal RST : std_logic;
  signal V_PORCH_N : std_logic := '1';
  signal CHAR_COL : t_char_col;
  signal CHAR_ROW : t_char_row;
  signal CHAR_ID : t_char_id;
  signal RW_ADDR : std_logic_vector (17 downto 0);
  signal DATA : std_logic_vector (15 downto 0);
  signal CE_N : std_logic;
  signal OE_N : std_logic;
  signal WE_N : std_logic;
  signal LB_N : std_logic;
  signal UB_N : std_logic;
  signal CTRL_EN : std_logic;
  signal PIXEL_CLK  : std_logic := '0';

begin

  process (CLK)
	begin
		if rising_edge(CLK) then
			PIXEL_CLK <= NOT PIXEL_CLK;
		end if;
	end process;

  VGA_cmd_fifo_inst : entity work.VGA_cmd_fifo
  port map (
    CLK         => PIXEL_CLK,
    RST         => RST,
    FIFO_REN   => V_PORCH_N
  );

clk <= not clk after clk_period/2;
 
RST <= '1', '0' after clk_period*10;
V_PORCH_N <= '1', '0' after clk_period*100;

end;