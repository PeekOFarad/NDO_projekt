----------------------------------------------------------------------------------
-- ps2_rx_TB.vhd
-- PS2 receiver Testbench.
-- 06 Oct, 2024
-- Semestral project in the autumn semester of 2024 in MPC-NDO.
-- Artem Gumenyuk (xgumen00@vutbr.cz)
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity ps2_rx_TB is
end ps2_rx_TB;

architecture Behavioral of ps2_rx_TB is
  
  component ps2_rx is
    Port ( CLK        : in  STD_LOGIC;
           PS2_CLK    : in  STD_LOGIC;
           PS2_DATA   : in  STD_LOGIC;
           CODE_READY : out STD_LOGIC;
           PS2_CODE   : out STD_LOGIC_VECTOR (7 downto 0));
  end component;
  
  constant clk_per              : time := 1 ns; 
  constant ps2_clk_per          : time := 1000 ns;
  signal   simulation_finished  : BOOLEAN := FALSE;

  signal   clk                  : std_logic := '0';
  signal   ps2_clk              : std_logic := '1';
  signal   ps2_data             : std_logic := '1';
  signal   code_ready           : std_logic;
  signal   ps2_code             : std_logic_vector(7 downto 0);
  
  signal   key_code : std_logic_vector(7 downto 0);
  
  procedure r_send_ps2_frame(signal   data     : in std_logic_vector(7 downto 0);
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

begin

  process begin
    clk <= '0'; wait for clk_per/2;
    clk <= '1'; wait for clk_per/2;
    if simulation_finished then
      wait;
    end if;
  end process;

--------------------------------------------------------------------------------

  ps2_rx_i : ps2_rx
  port map(
    CLK        => clk,
    PS2_CLK    => ps2_clk,
    PS2_DATA   => ps2_data,
    CODE_READY => code_ready,
    PS2_CODE   => ps2_code
  );
 
-------------------------------------------------------------------------------- 
  
  proc_stim : PROCESS BEGIN
    wait until rising_edge(clk);
    wait for clk_per * 10;
    
    -- correct parity
    key_code <= "11001010";
    r_send_ps2_frame(key_code, '1', ps2_clk, ps2_data);
    
    wait for ps2_clk_per * 5;
    
    -- incorrect parity
    key_code <= "11001010";
    r_send_ps2_frame(key_code, '0', ps2_clk, ps2_data);
    
    wait for ps2_clk_per * 10;
    
    simulation_finished <= TRUE;
    WAIT;
  END PROCESS;

end Behavioral;
