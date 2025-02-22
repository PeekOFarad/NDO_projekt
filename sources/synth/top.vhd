----------------------------------------------------------------------------------
-- top.vhd
-- Server part top module
-- 11 Nov, 2024
-- Semestral project in the autumn semester of 2024 in MPC-NDO.
-- Artem Gumenyuk (xgumen00@vutbr.cz)
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.server_pkg.all;
use work.common_pkg.all;

entity top is
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
end top;

architecture rtl of top is

  component backend_top is
    Generic (
           g_SLAVE_CNT : positive := c_CLIENTS_CNT
    );
    Port ( CLK      : in  STD_LOGIC;
           RST      : in  STD_LOGIC;
           PS2_CLK  : in  STD_LOGIC;
           PS2_DATA : in  STD_LOGIC;
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

-------------------------------------------------------------------------------

  component back2ui_debug is
    Port ( CLK      : in STD_LOGIC;
           RST      : in STD_LOGIC;
           UPD_ARR  : in STD_LOGIC;
           UPD_DATA : in STD_LOGIC;
           LED0     : out STD_LOGIC;
           LED1     : out STD_LOGIC);
  end component;

-------------------------------------------------------------------------------
  -- TOP
  signal  col              : std_logic_vector(2 downto 0);
  signal  row              : std_logic_vector(5 downto 0);
  signal  data_out         : char_buff_t;
  signal  upd_arr          : std_logic;
  signal  upd_data         : std_logic;
  signal  VGA_RDY          : std_logic;

  signal PIXEL_CLK		  : std_logic := '0';

begin
--------------------------------------------------------------------------------
-- PIXEL CLOCK GEN
  process (CLK)
  begin
    if rising_edge(CLK) then
      PIXEL_CLK <= NOT PIXEL_CLK;
    end if;
  end process;
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------

  backend_top_i : backend_top
  generic map(
    g_SLAVE_CNT => c_CLIENTS_CNT
  )
  port map(
    CLK      => PIXEL_CLK,
    RST      => RST,
    PS2_CLK  => PS2_CLK,
    PS2_DATA => PS2_DATA,
    MISO     => MISO,
    VGA_RDY  => VGA_RDY,
    UPD_ARR  => upd_arr,
    UPD_DATA => upd_data,
    SCLK     => SCLK,
    MOSI     => MOSI,
    SS_N     => SS_N,
    COL      => col,
    ROW      => row,
    DATA_OUT => data_out
  );

--------------------------------------------------------------------------------

VGA_top_inst : entity work.VGA_top
  port map (
    CLK 			=> PIXEL_CLK,
    COL_SYS 	=> COL,
    ROW_SYS 	=> ROW,
    UPD_ARR 	=> upd_arr,
    UPD_DATA 	=> upd_data,
    DATA_SYS 	=> data_out,
    VGA_RDY   => VGA_RDY,
    H_SYNC 		=> H_SYNC,
    V_SYNC 		=> V_SYNC,
    RGB 			=> RGB,
    RW_ADDR 	=> RW_ADDR,
    DATA 		=> DATA,
    CE_N 		=> CE_N,
    OE_N 		=> OE_N,
    WE_N 		=> WE_N,
    LB_N 		=> LB_N,
    UB_N 		=> UB_N
  );

--------------------------------------------------------------------------------

back2ui_debug_i : back2ui_debug
  port map(
    CLK      => PIXEL_CLK,
    RST      => RST,
    UPD_ARR  => upd_arr,
    UPD_DATA => upd_data,
    LED0     => LED0,
    LED1     => LED1
  );


end rtl;
