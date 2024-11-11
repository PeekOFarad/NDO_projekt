----------------------------------------------------------------------------------
-- top_tb.vhd
-- Server part top TB.
-- 2 Nov, 2024
-- Semestral project in the autumn semester of 2024 in MPC-NDO.
-- Artem Gumenyuk (xgumen00@vutbr.cz)
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.ps2_pkg.all;
use work.server_pkg.all;

entity top_tb is
end top_tb;

architecture bench of top_tb is

  component backend_top is
    Generic (
           g_SLAVE_CNT : positive
    );
    Port ( CLK      : in STD_LOGIC;
           RST      : in STD_LOGIC;
           PS2_CLK  : in STD_LOGIC;
           PS2_DATA : in STD_LOGIC;
           MISO     : in STD_LOGIC;
           UPD_ARR  : out STD_LOGIC;
           UPD_DATA : out STD_LOGIC;
           SCLK     : out STD_LOGIC;
           MOSI     : out STD_LOGIC;
           SS_N     : out STD_LOGIC_VECTOR (g_SLAVE_CNT-1 downto 0);
           COL      : out STD_LOGIC_VECTOR (2 downto 0);
           ROW      : out STD_LOGIC_VECTOR (5 downto 0);
           DATA_OUT : out char_buff_t);
  end component;

--------------------------------------------------------------------------------

  constant clk_per              : time := 20 ns; 
  constant ps2_clk_per          : time := 34 us;
  signal   simulation_finished  : BOOLEAN := FALSE;
  
  signal   clk              : std_logic := '0';
  signal   rst              : std_logic := '0';

  -- TOP
  signal   ps2_clk          : std_logic := '1';
  signal   ps2_data         : std_logic := '1';
  signal   col              : std_logic_vector(2 downto 0);
  signal   row              : std_logic_vector(5 downto 0);
  signal   data_out         : char_buff_t;
  signal   upd_arr          : std_logic;
  signal   upd_data         : std_logic;
  signal   miso             : std_logic := '0';
  signal   mosi             : std_logic;
  signal   sclk             : std_logic;
  signal   ss_n             : std_logic_vector(c_CLIENTS_CNT-1 downto 0);

  
  -- simulation related signals
  signal   par                  : std_logic := '0';
  signal   data                 : std_logic_vector(7 downto 0) := (others => '0');

  -- Send PS2 frame task
  procedure r_send_ps2_frame( constant data     : in std_logic_vector(7 downto 0);
                              signal   parity   : in std_logic;
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

    wait for 4 * ps2_clk_per;
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

  backend_top_i : backend_top
  generic map(
    g_SLAVE_CNT => c_CLIENTS_CNT
  )
  port map(
    CLK      => clk,
    RST      => rst,
    PS2_CLK  => ps2_clk,
    PS2_DATA => ps2_data,
    MISO     => miso,
    UPD_ARR  => upd_arr,
    UPD_DATA => upd_data,
    SCLK     => sclk,
    MOSI     => mosi,
    SS_N     => ss_n,
    COL      => col,
    ROW      => row,
    DATA_OUT => data_out
  );

--------------------------------------------------------------------------------

  par <= not (data(0) xor data(1) xor data(2) xor data(3) xor data(4) xor data(5) xor data(6) xor data(7));

  proc_stim : PROCESS BEGIN
    wait until rising_edge(clk);
    wait for clk_per * 10;

    -- press enter
    data <= c_enter;
    r_send_ps2_frame(c_enter, par, ps2_clk, ps2_data);
    
    -- print "cesnecka"
    data <= std_logic_vector(TO_UNSIGNED(c_c, 8));
    r_send_ps2_frame(std_logic_vector(TO_UNSIGNED(c_c, 8)), par, ps2_clk, ps2_data);
    data <= std_logic_vector(TO_UNSIGNED(c_e, 8));
    r_send_ps2_frame(std_logic_vector(TO_UNSIGNED(c_e, 8)), par, ps2_clk, ps2_data);
    data <= std_logic_vector(TO_UNSIGNED(c_s, 8));
    r_send_ps2_frame(std_logic_vector(TO_UNSIGNED(c_s, 8)), par, ps2_clk, ps2_data);
    data <= std_logic_vector(TO_UNSIGNED(c_n, 8));
    r_send_ps2_frame(std_logic_vector(TO_UNSIGNED(c_n, 8)), par, ps2_clk, ps2_data);
    data <= std_logic_vector(TO_UNSIGNED(c_e, 8));
    r_send_ps2_frame(std_logic_vector(TO_UNSIGNED(c_e, 8)), par, ps2_clk, ps2_data);
    data <= std_logic_vector(TO_UNSIGNED(c_c, 8));
    r_send_ps2_frame(std_logic_vector(TO_UNSIGNED(c_c, 8)), par, ps2_clk, ps2_data);
    data <= std_logic_vector(TO_UNSIGNED(c_k, 8));
    r_send_ps2_frame(std_logic_vector(TO_UNSIGNED(c_k, 8)), par, ps2_clk, ps2_data);
    data <= std_logic_vector(TO_UNSIGNED(c_a, 8));
    r_send_ps2_frame(std_logic_vector(TO_UNSIGNED(c_a, 8)), par, ps2_clk, ps2_data);

    -- press right arrow
    data <= c_e0;
    r_send_ps2_frame(c_e0, par, ps2_clk, ps2_data);
    data <= c_right;
    r_send_ps2_frame(c_right, par, ps2_clk, ps2_data);
    
    -- press enter
    data <= c_enter;
    r_send_ps2_frame(c_enter, par, ps2_clk, ps2_data);
    
    -- enter "14"
    data <= c_1;
    r_send_ps2_frame(c_1, par, ps2_clk, ps2_data);
    data <= c_4;
    r_send_ps2_frame(c_4, par, ps2_clk, ps2_data);
    
    -- press backspace
    data <= c_bckspc;
    r_send_ps2_frame(c_bckspc, par, ps2_clk, ps2_data);
    
    -- enter 5
    data <= c_5;
    r_send_ps2_frame(c_5, par, ps2_clk, ps2_data);
    
    -- press esc
    data <= c_esc;
    r_send_ps2_frame(c_esc, par, ps2_clk, ps2_data);
    
    -- press right arrow 2x
    data <= c_e0;
    r_send_ps2_frame(c_e0, par, ps2_clk, ps2_data);
    data <= c_right;
    r_send_ps2_frame(c_right, par, ps2_clk, ps2_data);
    data <= c_e0;
    r_send_ps2_frame(c_e0, par, ps2_clk, ps2_data);
    data <= c_right;
    r_send_ps2_frame(c_right, par, ps2_clk, ps2_data);
    
    -- go to the next node button row (32)
    for i in 1 to 32 loop
      data <= c_e0;
      r_send_ps2_frame(c_e0, par, ps2_clk, ps2_data);
      data <= c_down;
      r_send_ps2_frame(c_down, par, ps2_clk, ps2_data);
    end loop;
    
    -- press enter
    data <= c_enter;
    r_send_ps2_frame(c_enter, par, ps2_clk, ps2_data);
    
    -- press enter
    data <= c_enter;
    r_send_ps2_frame(c_enter, par, ps2_clk, ps2_data);
    
    -- press enter
    data <= c_enter;
    r_send_ps2_frame(c_enter, par, ps2_clk, ps2_data);
    
    wait for clk_per * 1000;

    simulation_finished <= TRUE;
    WAIT;
  END PROCESS;

end bench;
