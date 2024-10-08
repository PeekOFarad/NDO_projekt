----------------------------------------------------------------------------------
-- ps2_top_TB.vhd
-- PS2 top Testbench.
-- 08 Oct, 2024
-- Semestral project in the autumn semester of 2024 in MPC-NDO.
-- Artem Gumenyuk (xgumen00@vutbr.cz)
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.ps2_pkg.all;

entity ps2_top_TB is
end ps2_top_TB;

architecture Behavioral of ps2_top_TB is

  component ps2_top is
    Port ( CLK      : in STD_LOGIC;
           PS2_CLK  : in STD_LOGIC;
           PS2_DATA : in STD_LOGIC;
           KEYS     : out t_keys);
  end component;

--------------------------------------------------------------------------------

  constant clk_per              : time := 1 ns; 
  constant ps2_clk_per          : time := 1000 ns;
  signal   simulation_finished  : BOOLEAN := FALSE;

  signal   clk                  : std_logic := '0';
  signal   ps2_clk              : std_logic := '1';
  signal   ps2_data             : std_logic := '1';
  signal   code_ready           : std_logic;
  signal   ps2_code             : std_logic_vector(7 downto 0);
  signal   keys                 : t_keys;
  
  signal   key_code : std_logic_vector(7 downto 0);
  
--------------------------------------------------------------------------------
  
  procedure r_send_ps2_frame(constant data     : in std_logic_vector(7 downto 0);
                             constant parity   : in std_logic;
                             signal   ps2_clk  : out std_logic;
                             signal   ps2_data : out std_logic) is
  begin
  
    ps2_data <= '0'; wait for ps2_clk_per/2;
    ps2_clk <= '0'; wait for ps2_clk_per/2;
    for i in 0 to 7 loop
      ps2_data <= data(i);
      ps2_clk <= '1'; wait for ps2_clk_per/2;
      ps2_clk <= '0'; wait for ps2_clk_per/2;
    end loop;
    ps2_data <= parity;
    ps2_clk <= '1'; wait for ps2_clk_per/2;
    ps2_clk <= '0'; wait for ps2_clk_per/2;
    ps2_data <= '1';
    ps2_clk <= '1'; wait for ps2_clk_per/2;
    ps2_clk <= '0'; wait for ps2_clk_per/2;
    ps2_clk <= '1';
  end procedure;
  
--------------------------------------------------------------------------------

  constant c_up_par    : std_logic := '0';
  constant c_down_par  : std_logic := '1';
  constant c_esc_par   : std_logic := '0';
  constant c_enter_par : std_logic := '1';
  constant c_del_par   : std_logic := '1';
  constant c_f0_par    : std_logic := '1';
  constant c_e0_par    : std_logic := '0';

begin

  process begin
    clk <= '0'; wait for clk_per/2;
    clk <= '1'; wait for clk_per/2;
    if simulation_finished then
      wait;
    end if;
  end process;

--------------------------------------------------------------------------------

  ps2_top_i : ps2_top
  port map(
    CLK      => clk,
    PS2_CLK  => ps2_clk,
    PS2_DATA => ps2_data,
    KEYS     => keys
  );

--------------------------------------------------------------------------------

  proc_stim : PROCESS BEGIN
    wait until rising_edge(clk);
    wait for clk_per * 10;
    
    -- press enter
    r_send_ps2_frame(c_enter, c_enter_par, ps2_clk, ps2_data);
    wait for ps2_clk_per * 3;
    
    -- release enter
    r_send_ps2_frame(c_f0, c_f0_par, ps2_clk, ps2_data);
    wait for ps2_clk_per * 3;
    r_send_ps2_frame(c_enter, c_enter_par, ps2_clk, ps2_data);
    wait for ps2_clk_per * 3;
    
    -- press arrow up
    r_send_ps2_frame(c_e0, c_e0_par, ps2_clk, ps2_data);
    wait for ps2_clk_per * 3;
    r_send_ps2_frame(c_up, c_up_par, ps2_clk, ps2_data);
    wait for ps2_clk_per * 3;
    
    -- release arrow up
    r_send_ps2_frame(c_e0, c_e0_par, ps2_clk, ps2_data);
    wait for ps2_clk_per * 3;
    r_send_ps2_frame(c_f0, c_f0_par, ps2_clk, ps2_data);
    wait for ps2_clk_per * 3;
    r_send_ps2_frame(c_up, c_up_par, ps2_clk, ps2_data);
    wait for ps2_clk_per * 3;
    
    wait for ps2_clk_per * 10;
    
    simulation_finished <= TRUE;
    WAIT;
  END PROCESS;

end Behavioral;
