----------------------------------------------------------------------------------
-- clk_divider_TB.vhd
-- Clock divider Testbench.
-- 06 Oct, 2024
-- Semestral project in the autumn semester of 2024 in MPC-NDO.
-- Artem Gumenyuk (xgumen00@vutbr.cz)
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity clk_divider_TB is
--  Port ( );
end clk_divider_TB;

architecture Behavioral of clk_divider_TB is

component clk_divider is
    generic (
        IN_FREQ  : positive;
        OUT_FREQ : positive
    );
    port ( CLK        : in  std_logic;
           CLK_DIV_EN : out std_logic
    );
end component;

  constant clk_per              : time := 20 ns;
  signal   simulation_finished  : BOOLEAN := FALSE;

  signal   clk                  : std_logic := '0';
  signal   div_clk              : std_logic;

begin

  process begin
    clk <= '0'; wait for clk_per/2;
    clk <= '1'; wait for clk_per/2;
    if simulation_finished then
      wait;
    end if;
  end process;

--------------------------------------------------------------------------------
  
  clk_divider_i : clk_divider
  generic map(
    IN_FREQ  => 1000,
    OUT_FREQ => 500
  )
  port map(
    CLK          => clk,
    CLK_DIV_EN   => div_clk
  );
  
--------------------------------------------------------------------------------

  proc_stim : PROCESS BEGIN
    wait until rising_edge(clk);
    wait for clk_per * 20;
    simulation_finished <= TRUE;
    WAIT;
  END PROCESS;

end Behavioral;
