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
use work.common_pkg.all;

entity top_tb is
end top_tb;

architecture bench of top_tb is

  component top is
    Generic (
        g_SLAVE_CNT : positive := c_CLIENTS_CNT
    );
    Port (
        CLK      : in STD_LOGIC;
        RST      : in STD_LOGIC;
        -- PS2 interface
        PS2_CLK  : in STD_LOGIC;
        PS2_DATA : in STD_LOGIC;
        -- SPI interface
        MISO     : in STD_LOGIC;
        SCLK     : out STD_LOGIC;
        MOSI     : out STD_LOGIC;
        SS_N     : out STD_LOGIC_VECTOR (g_SLAVE_CNT-1 downto 0);
        --------------------------------------------------------------------------------
        --------------------------------------------------------------------------------
         -- VGA
         H_SYNC    : out std_logic;
         V_SYNC    : out std_logic;
         RGB       : out std_logic_vector(2 downto 0);
         --------------------------------------------------------------------------------
         --------------------------------------------------------------------------------
         --SRAM
         RW_ADDR   : out std_logic_vector (17 downto 0);
         DATA      : inout  std_logic_vector (15 downto 0);
         CE_N      : out std_logic; --! chip enable, always low
         OE_N      : out std_logic;
         WE_N      : out std_logic; --! always high for reading
         LB_N      : out std_logic; --! Byte selection, always low
         UB_N      : out std_logic;  --! Byte selection, always low
         --------------------------------------------------------------------------------
         --------------------------------------------------------------------------------
         -- DEBUG INTERFACE
         LED0      : out std_logic;
         LED1      : out std_logic
    );
  end component;

--------------------------------------------------------------------------------

  constant clk_per              : time := 20 ns; -- 30MHz
  constant ps2_clk_per          : time := 33.3 us; -- 30kHz
  signal   simulation_finished  : BOOLEAN := FALSE;
  
  signal   clk              : std_logic := '0';
  signal   rst              : std_logic := '0';

  -- TOP
  signal   ps2_clk          : std_logic := '1';
  signal   ps2_data         : std_logic := '1';
  signal   miso             : std_logic := '0';
  signal   mosi             : std_logic;
  signal   sclk             : std_logic;
  signal   ss_n             : std_logic_vector(c_CLIENTS_CNT-1 downto 0);
  signal   h_sync           : std_logic;
  signal   v_sync           : std_logic;
  signal   rgb              : std_logic_vector(2 downto 0);
  signal   rw_addr          : std_logic_vector (17 downto 0);
  signal   sram_data        : std_logic_vector (15 downto 0);
  signal   ce_n             : std_logic;
  signal   oe_n             : std_logic;
  signal   we_n             : std_logic;
  signal   lb_n             : std_logic;
  signal   ub_n             : std_logic;

  signal   LED0             : std_logic;
  signal   LED1             : std_logic;

  
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

top_i : top
  generic map(
    g_SLAVE_CNT => c_CLIENTS_CNT
  )
  port map(
    CLK       => clk,
    RST       => rst,
    PS2_CLK   => ps2_clk,
    PS2_DATA  => ps2_data,
    MISO      => miso,
    SCLK      => sclk,
    MOSI      => mosi,
    SS_N      => ss_n,
    H_SYNC    => h_sync,
    V_SYNC    => v_sync,
    RGB       => rgb,
    RW_ADDR   => rw_addr,
    DATA      => sram_data,
    CE_N      => ce_n,
    OE_N      => oe_n,
    WE_N      => we_n,
    LB_N      => lb_n,
    UB_N      => ub_n,
    LED0      => LED0,
    LED1      => LED1
  );

--------------------------------------------------------------------------------

  par <= not (data(0) xor data(1) xor data(2) xor data(3) xor data(4) xor data(5) xor data(6) xor data(7));

  proc_stim : PROCESS BEGIN
    wait until rising_edge(clk);
    wait for clk_per * 10;
    
    wait for 2ms;

    -- press enter
    data <= c_enter;
    r_send_ps2_frame(c_enter, par, ps2_clk, ps2_data);
    
    wait for 200us;
    
    -- print "cesnecka"
    data <= std_logic_vector(TO_UNSIGNED(c_c, 8));
    wait for clk_per;
    r_send_ps2_frame(std_logic_vector(TO_UNSIGNED(c_c, 8)), par, ps2_clk, ps2_data);
    wait for 200us;
    data <= std_logic_vector(TO_UNSIGNED(c_e, 8));
    wait for clk_per;
    r_send_ps2_frame(std_logic_vector(TO_UNSIGNED(c_e, 8)), par, ps2_clk, ps2_data);
    wait for 200us;
    data <= std_logic_vector(TO_UNSIGNED(c_s, 8));
    wait for clk_per;
    r_send_ps2_frame(std_logic_vector(TO_UNSIGNED(c_s, 8)), par, ps2_clk, ps2_data);
    wait for 200us;
    data <= std_logic_vector(TO_UNSIGNED(c_n, 8));
    wait for clk_per;
    r_send_ps2_frame(std_logic_vector(TO_UNSIGNED(c_n, 8)), par, ps2_clk, ps2_data);
    wait for 200us;
    data <= std_logic_vector(TO_UNSIGNED(c_e, 8));
    wait for clk_per;
    r_send_ps2_frame(std_logic_vector(TO_UNSIGNED(c_e, 8)), par, ps2_clk, ps2_data);
    wait for 200us;
    data <= std_logic_vector(TO_UNSIGNED(c_c, 8));
    wait for clk_per;
    r_send_ps2_frame(std_logic_vector(TO_UNSIGNED(c_c, 8)), par, ps2_clk, ps2_data);
    wait for 200us;
    data <= std_logic_vector(TO_UNSIGNED(c_k, 8));
    wait for clk_per;
    r_send_ps2_frame(std_logic_vector(TO_UNSIGNED(c_k, 8)), par, ps2_clk, ps2_data);
    wait for 200us;
    data <= std_logic_vector(TO_UNSIGNED(c_a, 8));
    wait for clk_per;
    r_send_ps2_frame(std_logic_vector(TO_UNSIGNED(c_a, 8)), par, ps2_clk, ps2_data);
    wait for 200us;

    -- press down arrow
    data <= c_down;
    wait for clk_per;
    r_send_ps2_special(c_down, par, ps2_clk, ps2_data);
    wait for clk_per;

    -- press enter
    data <= c_enter;
    r_send_ps2_frame(c_enter, par, ps2_clk, ps2_data);
    wait for clk_per;

    -- print "kulajda"
    data <= std_logic_vector(TO_UNSIGNED(c_k, 8));
    wait for clk_per;
    r_send_ps2_frame(std_logic_vector(TO_UNSIGNED(c_k, 8)), par, ps2_clk, ps2_data);
    wait for 200us;
    data <= std_logic_vector(TO_UNSIGNED(c_u, 8));
    wait for clk_per;
    r_send_ps2_frame(std_logic_vector(TO_UNSIGNED(c_u, 8)), par, ps2_clk, ps2_data);
    wait for 200us;
    data <= std_logic_vector(TO_UNSIGNED(c_l, 8));
    wait for clk_per;
    r_send_ps2_frame(std_logic_vector(TO_UNSIGNED(c_l, 8)), par, ps2_clk, ps2_data);
    wait for 200us;
    data <= std_logic_vector(TO_UNSIGNED(c_a, 8));
    wait for clk_per;
    r_send_ps2_frame(std_logic_vector(TO_UNSIGNED(c_a, 8)), par, ps2_clk, ps2_data);
    wait for 200us;
    data <= std_logic_vector(TO_UNSIGNED(c_j, 8));
    wait for clk_per;
    r_send_ps2_frame(std_logic_vector(TO_UNSIGNED(c_j, 8)), par, ps2_clk, ps2_data);
    wait for 200us;
    data <= std_logic_vector(TO_UNSIGNED(c_d, 8));
    wait for clk_per;
    r_send_ps2_frame(std_logic_vector(TO_UNSIGNED(c_d, 8)), par, ps2_clk, ps2_data);
    wait for 200us;
    data <= std_logic_vector(TO_UNSIGNED(c_a, 8));
    wait for clk_per;
    r_send_ps2_frame(std_logic_vector(TO_UNSIGNED(c_a, 8)), par, ps2_clk, ps2_data);
    wait for 200us;

    -- press up arrow
    data <= c_up;
    wait for clk_per;
    r_send_ps2_special(c_up, par, ps2_clk, ps2_data);
    wait for clk_per;

    -- press right arrow
    data <= c_right;
    wait for clk_per;
    r_send_ps2_special(c_right, par, ps2_clk, ps2_data);
    wait for 200us;
    
    -- press enter
    data <= c_enter;
    wait for clk_per;
    r_send_ps2_frame(c_enter, par, ps2_clk, ps2_data);
    
    -- enter amount "14"
    data <= c_1;
    wait for clk_per;
    r_send_ps2_frame(c_1, par, ps2_clk, ps2_data);
    data <= c_4;
    wait for clk_per;
    r_send_ps2_frame(c_4, par, ps2_clk, ps2_data);
    
    -- press esc
    data <= c_esc;
    wait for clk_per;
    r_send_ps2_frame(c_esc, par, ps2_clk, ps2_data);

    -- press down arrow
    data <= c_down;
    wait for clk_per;
    r_send_ps2_special(c_down, par, ps2_clk, ps2_data);

    -- press enter
    data <= c_enter;
    wait for clk_per;
    r_send_ps2_frame(c_enter, par, ps2_clk, ps2_data);
    
    -- enter amount "5"
    data <= c_5;
    wait for clk_per;
    r_send_ps2_frame(c_5, par, ps2_clk, ps2_data);
    
    -- press esc
    data <= c_esc;
    wait for clk_per;
    r_send_ps2_frame(c_esc, par, ps2_clk, ps2_data);
    
    -- press up arrow
    data <= c_up;
    wait for clk_per;
    r_send_ps2_special(c_up, par, ps2_clk, ps2_data);

    -- press right arrow
    data <= c_right;
    wait for clk_per;
    r_send_ps2_special(c_right, par, ps2_clk, ps2_data);

    -- press enter
    data <= c_enter;
    wait for clk_per;
    r_send_ps2_frame(c_enter, par, ps2_clk, ps2_data);

    -- enter student price "15"
    data <= c_1;
    wait for clk_per;
    r_send_ps2_frame(c_1, par, ps2_clk, ps2_data);
    data <= c_5;
    wait for clk_per;
    r_send_ps2_frame(c_5, par, ps2_clk, ps2_data);

    -- press enter
    data <= c_enter;
    wait for clk_per;
    r_send_ps2_frame(c_enter, par, ps2_clk, ps2_data);

    -- press right arrow (under NEXT button)
    data <= c_right;
    wait for clk_per;
    r_send_ps2_special(c_right, par, ps2_clk, ps2_data);

    -- press enter
    data <= c_enter;
    wait for clk_per;
    r_send_ps2_frame(c_enter, par, ps2_clk, ps2_data);

    -- enter employee price "10"
    data <= c_1;
    wait for clk_per;
    r_send_ps2_frame(c_1, par, ps2_clk, ps2_data);
    data <= c_0;
    wait for clk_per;
    r_send_ps2_frame(c_0, par, ps2_clk, ps2_data);

    -- press enter
    data <= c_enter;
    wait for clk_per;
    r_send_ps2_frame(c_enter, par, ps2_clk, ps2_data);

    -- press right arrow
    data <= c_right;
    wait for clk_per;
    r_send_ps2_special(c_right, par, ps2_clk, ps2_data);

    -- press enter
    data <= c_enter;
    wait for clk_per;
    r_send_ps2_frame(c_enter, par, ps2_clk, ps2_data);

    -- enter external price "20"
    data <= c_2;
    wait for clk_per;
    r_send_ps2_frame(c_2, par, ps2_clk, ps2_data);
    data <= c_0;
    wait for clk_per;
    r_send_ps2_frame(c_0, par, ps2_clk, ps2_data);

    -- press enter
    data <= c_enter;
    wait for clk_per;
    r_send_ps2_frame(c_enter, par, ps2_clk, ps2_data);

    -- press down arrow
    data <= c_down;
    wait for clk_per;
    r_send_ps2_special(c_down, par, ps2_clk, ps2_data);

    -- press enter
    data <= c_enter;
    wait for clk_per;
    r_send_ps2_frame(c_enter, par, ps2_clk, ps2_data);

    -- enter external price "22"
    data <= c_2;
    wait for clk_per;
    r_send_ps2_frame(c_2, par, ps2_clk, ps2_data);
    data <= c_2;
    wait for clk_per;
    r_send_ps2_frame(c_2, par, ps2_clk, ps2_data);

    -- press enter
    data <= c_enter;
    wait for clk_per;
    r_send_ps2_frame(c_enter, par, ps2_clk, ps2_data);

    -- press left arrow
    data <= c_left;
    wait for clk_per;
    r_send_ps2_special(c_left, par, ps2_clk, ps2_data);

    -- press enter
    data <= c_enter;
    wait for clk_per;
    r_send_ps2_frame(c_enter, par, ps2_clk, ps2_data);

    -- enter employee price "11"
    data <= c_1;
    wait for clk_per;
    r_send_ps2_frame(c_1, par, ps2_clk, ps2_data);
    data <= c_1;
    wait for clk_per;
    r_send_ps2_frame(c_1, par, ps2_clk, ps2_data);

    -- press enter
    data <= c_enter;
    wait for clk_per;
    r_send_ps2_frame(c_enter, par, ps2_clk, ps2_data);

    -- press left arrow
    data <= c_left;
    wait for clk_per;
    r_send_ps2_special(c_left, par, ps2_clk, ps2_data);

    -- press enter
    data <= c_enter;
    wait for clk_per;
    r_send_ps2_frame(c_enter, par, ps2_clk, ps2_data);

    -- enter student price "16"
    data <= c_1;
    wait for clk_per;
    r_send_ps2_frame(c_1, par, ps2_clk, ps2_data);
    data <= c_6;
    wait for clk_per;
    r_send_ps2_frame(c_6, par, ps2_clk, ps2_data);

    -- press enter
    data <= c_enter;
    wait for clk_per;
    r_send_ps2_frame(c_enter, par, ps2_clk, ps2_data);

    -- press right arrow
    data <= c_right;
    wait for clk_per;
    r_send_ps2_special(c_right, par, ps2_clk, ps2_data);
    
    -- go to the next node button row (32)
    for i in 1 to 32 loop
      data <= c_down;
      wait for clk_per;
      r_send_ps2_special(c_down, par, ps2_clk, ps2_data);
    end loop;

    -- press enter - NEXT btn
    data <= c_enter;
    wait for clk_per;
    r_send_ps2_frame(c_enter, par, ps2_clk, ps2_data);

    -- go to the 0 row
    for i in 1 to 32 loop
      data <= c_up;
      wait for clk_per;
      r_send_ps2_special(c_up, par, ps2_clk, ps2_data);
    end loop;

    -- press left arrow 2x (AMOUNT col)
    data <= c_left;
    wait for clk_per;
    r_send_ps2_special(c_left, par, ps2_clk, ps2_data);
    wait for clk_per;
    r_send_ps2_special(c_left, par, ps2_clk, ps2_data);

    -- press enter
    data <= c_enter;
    wait for clk_per;
    r_send_ps2_frame(c_enter, par, ps2_clk, ps2_data);

    -- enter amount "4"
    data <= c_4;
    wait for clk_per;
    r_send_ps2_frame(c_4, par, ps2_clk, ps2_data);

    -- press enter
    data <= c_enter;
    wait for clk_per;
    r_send_ps2_frame(c_enter, par, ps2_clk, ps2_data);

    -- press down
    data <= c_down;
    wait for clk_per;
    r_send_ps2_special(c_down, par, ps2_clk, ps2_data);

    -- press enter
    data <= c_enter;
    wait for clk_per;
    r_send_ps2_frame(c_enter, par, ps2_clk, ps2_data);

    -- enter amount "5"
    data <= c_5;
    wait for clk_per;
    r_send_ps2_frame(c_5, par, ps2_clk, ps2_data);

    -- press enter
    data <= c_enter;
    wait for clk_per;
    r_send_ps2_frame(c_enter, par, ps2_clk, ps2_data);
    
    -- press right arrow 3x (START col)
    data <= c_right;
    wait for clk_per;
    r_send_ps2_special(c_right, par, ps2_clk, ps2_data);
    wait for clk_per;
    r_send_ps2_special(c_right, par, ps2_clk, ps2_data);
    wait for clk_per;
    r_send_ps2_special(c_right, par, ps2_clk, ps2_data);
    
    -- go to start button row (32)
    for i in 1 to 32 loop
      data <= c_down;
      wait for clk_per;
      r_send_ps2_special(c_down, par, ps2_clk, ps2_data);
    end loop;

    -- press enter (START the day)
    data <= c_enter;
    wait for clk_per;
    r_send_ps2_frame(c_enter, par, ps2_clk, ps2_data);
    
    wait for clk_per * 1000;

    simulation_finished <= TRUE;
    WAIT;
  END PROCESS;

end bench;
