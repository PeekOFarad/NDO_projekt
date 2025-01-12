----------------------------------------------------------------------------------
-- system_top_tb.vhd
-- Server part top TB.
-- 26 Nov, 2024
-- Semestral project in the autumn semester of 2024 in MPC-NDO.
-- Artem Gumenyuk (xgumen00@vutbr.cz)
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.ps2_pkg.all;
use work.server_pkg.all;
use work.common_pkg.all;

entity system_top_tb is
end system_top_tb;

architecture bench of system_top_tb is

  component backend_top is
    Generic (
           g_SLAVE_CNT : positive
    );
    Port ( CLK      : in STD_LOGIC;
           RST      : in STD_LOGIC;
           PS2_CLK  : in STD_LOGIC;
           PS2_DATA : in STD_LOGIC;
           MISO     : in STD_LOGIC;
           VGA_RDY  : in STD_LOGIC;
           UPD_ARR  : out STD_LOGIC;
           UPD_DATA : out STD_LOGIC;
           SCLK     : out STD_LOGIC;
           MOSI     : out STD_LOGIC;
           SS_N     : out STD_LOGIC_VECTOR (g_SLAVE_CNT-1 downto 0);
           COL      : out STD_LOGIC_VECTOR (2 downto 0);
           ROW      : out STD_LOGIC_VECTOR (5 downto 0);
           DATA_OUT : out char_buff_t);
  end component;

  component client_backend_top is
    Port ( CLK      : in STD_LOGIC;
           RST      : in STD_LOGIC;
           -- PS2
           PS2_CLK  : in STD_LOGIC;
           PS2_DATA : in STD_LOGIC;
           -- SPI
           SCSB     : in STD_LOGIC;
           SCLK     : in STD_LOGIC;
           MOSI     : in STD_LOGIC;
           MISO     : out STD_LOGIC;
           -- UI TOP
           VGA_RDY  : in STD_LOGIC;
           UPD_ARR  : out STD_LOGIC;
           UPD_DATA : out STD_LOGIC;
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

  -- SERVER TOP
  signal   sps2_clk         : std_logic := '1';
  signal   sps2_data        : std_logic := '1';
  signal   col_serv         : std_logic_vector(2 downto 0);
  signal   row_serv         : std_logic_vector(5 downto 0);
  signal   upd_arr_serv     : std_logic;
  signal   upd_data_serv    : std_logic;
  signal   data_out_serv    : char_buff_t;

  signal   miso             : std_logic;
  signal   vga_rdy          : std_logic := '1';
  signal   mosi             : std_logic;
  signal   sclk             : std_logic;
  signal   ss_n             : std_logic_vector(c_CLIENTS_CNT-1 downto 0);

  -- CLIENT TOP
  signal   cps2_clk         : std_logic := '1';
  signal   cps2_data        : std_logic := '1';
  signal   col_client       : std_logic_vector(2 downto 0);
  signal   row_client       : std_logic_vector(5 downto 0);
  signal   upd_arr_client   : std_logic;
  signal   upd_data_client  : std_logic;
  signal   data_out_client  : char_buff_t;
  
  -- simulation related signals
  signal   par                  : std_logic := '0';
  signal   data                 : std_logic_vector(7 downto 0) := (others => '0');

  -- Send PS2 frame task
  procedure r_send_ps2_frame( constant data     : in std_logic_vector(7 downto 0);
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

    wait for 4 * ps2_clk_per;
  end procedure;

  -- Send PS2 special character task
  procedure r_send_ps2_special( constant data     : in std_logic_vector(7 downto 0);
                                signal   parity   : in std_logic;
                                signal   ps2_clk  : out std_logic;
                                signal   ps2_data : out std_logic) is
  begin
    r_send_ps2_frame(c_e0, '0', ps2_clk, ps2_data);
    r_send_ps2_frame(data, parity, ps2_clk, ps2_data);
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
    PS2_CLK  => sps2_clk,
    PS2_DATA => sps2_data,
    MISO     => miso,
    VGA_RDY  => vga_rdy,
    UPD_ARR  => upd_arr_serv,
    UPD_DATA => upd_data_serv,
    SCLK     => sclk,
    MOSI     => mosi,
    SS_N     => ss_n,
    COL      => col_serv,
    ROW      => row_serv,
    DATA_OUT => data_out_serv
  );

--------------------------------------------------------------------------------

  client_backend_top_i : client_backend_top
  port map(
    CLK      => clk,
    RST      => rst,
    PS2_CLK  => cps2_clk,
    PS2_DATA => cps2_data,
    SCSB     => ss_n(0),
    SCLK     => sclk,
    MOSI     => mosi,
    MISO     => miso,
    VGA_RDY  => vga_rdy,
    UPD_ARR  => upd_arr_client,
    UPD_DATA => upd_data_client,
    COL      => col_client,
    ROW      => row_client,
    DATA_OUT => data_out_client
  );

--------------------------------------------------------------------------------

  par <= not (data(0) xor data(1) xor data(2) xor data(3) xor data(4) xor data(5) xor data(6) xor data(7));

  proc_stim : PROCESS BEGIN
    wait until rising_edge(clk);
    wait for clk_per * 10;
    
    data <= c_down;
    r_send_ps2_special(c_down, par, sps2_clk, sps2_data);
    
    wait for 200us;

    -- press enter
    data <= c_enter;
    r_send_ps2_frame(c_enter, par, sps2_clk, sps2_data);
    
    wait for 200us;
    
    -- print "cesnecka"
    data <= std_logic_vector(TO_UNSIGNED(c_c, 8));
    wait for clk_per;
    r_send_ps2_frame(std_logic_vector(TO_UNSIGNED(c_c, 8)), par, sps2_clk, sps2_data);
    wait for 200us;
    data <= std_logic_vector(TO_UNSIGNED(c_e, 8));
    wait for clk_per;
    r_send_ps2_frame(std_logic_vector(TO_UNSIGNED(c_e, 8)), par, sps2_clk, sps2_data);
    wait for 200us;
    data <= std_logic_vector(TO_UNSIGNED(c_s, 8));
    wait for clk_per;
    r_send_ps2_frame(std_logic_vector(TO_UNSIGNED(c_s, 8)), par, sps2_clk, sps2_data);
    wait for 200us;
    data <= std_logic_vector(TO_UNSIGNED(c_n, 8));
    wait for clk_per;
    r_send_ps2_frame(std_logic_vector(TO_UNSIGNED(c_n, 8)), par, sps2_clk, sps2_data);
    wait for 200us;
    data <= std_logic_vector(TO_UNSIGNED(c_e, 8));
    wait for clk_per;
    r_send_ps2_frame(std_logic_vector(TO_UNSIGNED(c_e, 8)), par, sps2_clk, sps2_data);
    wait for 200us;
    data <= std_logic_vector(TO_UNSIGNED(c_c, 8));
    wait for clk_per;
    r_send_ps2_frame(std_logic_vector(TO_UNSIGNED(c_c, 8)), par, sps2_clk, sps2_data);
    wait for 200us;
    data <= std_logic_vector(TO_UNSIGNED(c_k, 8));
    wait for clk_per;
    r_send_ps2_frame(std_logic_vector(TO_UNSIGNED(c_k, 8)), par, sps2_clk, sps2_data);
    wait for 200us;
    data <= std_logic_vector(TO_UNSIGNED(c_a, 8));
    wait for clk_per;
    r_send_ps2_frame(std_logic_vector(TO_UNSIGNED(c_a, 8)), par, sps2_clk, sps2_data);
    wait for 200us;

    -- press right arrow
    data <= c_right;
    wait for clk_per;
    r_send_ps2_special(c_right, par, sps2_clk, sps2_data);
    wait for 200us;
    
    -- press enter
    data <= c_enter;
    wait for clk_per;
    r_send_ps2_frame(c_enter, par, sps2_clk, sps2_data);
    
    -- enter "14"
    data <= c_1;
    wait for clk_per;
    r_send_ps2_frame(c_1, par, sps2_clk, sps2_data);
    data <= c_4;
    wait for clk_per;
    r_send_ps2_frame(c_4, par, sps2_clk, sps2_data);
    
    -- press backspace
    data <= c_bckspc;
    wait for clk_per;
    r_send_ps2_frame(c_bckspc, par, sps2_clk, sps2_data);
    
    -- enter 5
    data <= c_5;
    wait for clk_per;
    r_send_ps2_frame(c_5, par, sps2_clk, sps2_data);
    
    -- press esc
    data <= c_esc;
    wait for clk_per;
    r_send_ps2_frame(c_esc, par, sps2_clk, sps2_data);
    
    -- press right arrow
    data <= c_right;
    wait for clk_per;
    r_send_ps2_special(c_right, par, sps2_clk, sps2_data);

    -- press enter
    data <= c_enter;
    wait for clk_per;
    r_send_ps2_frame(c_enter, par, sps2_clk, sps2_data);

    -- enter "14"
    data <= c_1;
    wait for clk_per;
    r_send_ps2_frame(c_1, par, sps2_clk, sps2_data);
    data <= c_4;
    wait for clk_per;
    r_send_ps2_frame(c_4, par, sps2_clk, sps2_data);

    -- press backspace
    data <= c_bckspc;
    wait for clk_per;
    r_send_ps2_frame(c_bckspc, par, sps2_clk, sps2_data);
    
    -- enter 5
    data <= c_5;
    wait for clk_per;
    r_send_ps2_frame(c_5, par, sps2_clk, sps2_data);

    -- press enter
    data <= c_enter;
    wait for clk_per;
    r_send_ps2_frame(c_enter, par, sps2_clk, sps2_data);
    
    -- go to the next node button row (32)
    for i in 1 to 32 loop
      data <= c_down;
      wait for clk_per;
      r_send_ps2_special(c_down, par, sps2_clk, sps2_data);
    end loop;
    
    -- press enter
    data <= c_enter;
    wait for clk_per;
    r_send_ps2_frame(c_enter, par, sps2_clk, sps2_data);

    -- press up
    data <= c_up;
    wait for clk_per;
    r_send_ps2_special(c_up, par, sps2_clk, sps2_data);

    -- press up
    data <= c_up;
    wait for clk_per;
    r_send_ps2_special(c_up, par, sps2_clk, sps2_data);

    -- press right
    data <= c_right;
    wait for clk_per;
    r_send_ps2_special(c_right, par, sps2_clk, sps2_data);
    
--    for i in 1 to 16 loop
--      data <= c_left;
--      r_send_ps2_special(c_left, par, sps2_clk, sps2_data);
--      r_send_ps2_special(c_left, par, sps2_clk, sps2_data);
--      r_send_ps2_special(c_left, par, sps2_clk, sps2_data);
--      r_send_ps2_special(c_left, par, sps2_clk, sps2_data);
--      r_send_ps2_special(c_left, par, sps2_clk, sps2_data);
--      data <= c_up;
--      r_send_ps2_special(c_up, par, sps2_clk, sps2_data);
--      data <= c_right;
--      r_send_ps2_special(c_right, par, sps2_clk, sps2_data);
--      r_send_ps2_special(c_right, par, sps2_clk, sps2_data);
--      r_send_ps2_special(c_right, par, sps2_clk, sps2_data);
--      r_send_ps2_special(c_right, par, sps2_clk, sps2_data);
--      r_send_ps2_special(c_right, par, sps2_clk, sps2_data);
--      data <= c_up;
--      r_send_ps2_special(c_up, par, sps2_clk, sps2_data);
--    end loop;
    
    wait for clk_per * 1000;

    simulation_finished <= TRUE;
    WAIT;
  END PROCESS;

end bench;
