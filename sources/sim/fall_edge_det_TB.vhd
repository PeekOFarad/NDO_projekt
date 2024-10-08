----------------------------------------------------------------------------------
-- fall_edge_det_TB.vhd
-- Falling edge detector Testbench.
-- 06 Oct, 2024
-- Semestral project in the autumn semester of 2024 in MPC-NDO.
-- Artem Gumenyuk (xgumen00@vutbr.cz)
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity fall_edge_det_TB is
end fall_edge_det_TB;

architecture Behavioral of fall_edge_det_TB is

component fall_edge_detector is
    Port ( CLK       : in  std_logic;
           INP_SIG   : in  std_logic;
           FALL_EDGE : out std_logic
    );
end component;

  constant clk_per              : time := 20 ns;
  signal   simulation_finished  : BOOLEAN := FALSE;

  signal   clk                  : std_logic := '0';
  signal   inp_sig              : std_logic;
  signal   fall_edge            : std_logic;
begin

  process begin
    clk <= '0'; wait for clk_per/2;
    clk <= '1'; wait for clk_per/2;
    if simulation_finished then
      wait;
    end if;
  end process;

--------------------------------------------------------------------------------
  
  fall_edge_det_i : fall_edge_detector
  port map(
    CLK       => clk,
    INP_SIG   => inp_sig,
    FALL_EDGE => fall_edge
  );
  
--------------------------------------------------------------------------------

  proc_stim : PROCESS BEGIN
    wait until rising_edge(clk);
    inp_sig <= '0';
    wait for clk_per * 5;
    inp_sig <= '1';
    wait for clk_per * 5;
    inp_sig <= '0';
    wait for clk_per * 5;
    
    inp_sig <= '1';
    wait for clk_per;
    inp_sig <= '0';
    wait for clk_per * 5;
    simulation_finished <= TRUE;
    WAIT;
  END PROCESS;

end Behavioral;
