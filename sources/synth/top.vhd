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

entity top is
  Generic (
        g_SLAVE_CNT : positive := c_CLIENTS_CNT
  );
  Port (CLK      : in STD_LOGIC;
        RST      : in STD_LOGIC;
        -- PS2 interface
        PS2_CLK  : in STD_LOGIC;
        PS2_DATA : in STD_LOGIC;
        -- SPI interface
        MISO     : in STD_LOGIC;
        SCLK     : out STD_LOGIC;
        MOSI     : out STD_LOGIC;
        SS_N     : out STD_LOGIC_VECTOR (g_SLAVE_CNT-1 downto 0)
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
           MISO     : in  STD_LOGIC;
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
  -- TOP
  signal   col              : std_logic_vector(2 downto 0);
  signal   row              : std_logic_vector(5 downto 0);
  signal   data_out         : char_buff_t;
  signal   upd_arr          : std_logic;
  signal   upd_data         : std_logic;

begin

--------------------------------------------------------------------------------

  backend_top_i : backend_top
  generic map(
    g_SLAVE_CNT => c_CLIENTS_CNT
  )
  port map(
    CLK      => CLK,
    RST      => RST,
    PS2_CLK  => PS2_CLK,
    PS2_DATA => PS2_DATA,
    MISO     => MISO,
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

  

end rtl;
