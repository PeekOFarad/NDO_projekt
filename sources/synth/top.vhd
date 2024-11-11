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
  Port (CLK      : in STD_LOGIC;
        RST      : in STD_LOGIC;
        PS2_CLK  : in STD_LOGIC;
        PS2_DATA : in STD_LOGIC;
  );
end top;

architecture rtl of top is

  component backend_top is
    Port (CLK      : in STD_LOGIC;
          RST      : in STD_LOGIC;
          PS2_CLK  : in STD_LOGIC;
          PS2_DATA : in STD_LOGIC;
          COL      : out STD_LOGIC_VECTOR (2 downto 0);
          ROW      : out STD_LOGIC_VECTOR (5 downto 0);
          UPD_ARR  : out STD_LOGIC;
          UPD_DATA : out STD_LOGIC;
          DATA_OUT : out sprit_buff_t);
  end component;

-------------------------------------------------------------------------------
  -- TOP
  -- signal   clk              : std_logic;
  -- signal   rst              : std_logic;
  signal   col              : std_logic_vector(2 downto 0);
  signal   row              : std_logic_vector(5 downto 0);
  signal   data_out         : sprit_buff_t;
  signal   upd_arr          : std_logic;
  signal   upd_data         : std_logic;

begin

--------------------------------------------------------------------------------

  backend_top_i : backend_top
  port map(
    CLK      => CLK,
    RST      => RST,
    PS2_CLK  => PS2_CLK,
    PS2_DATA => PS2_DATA,
    COL      => col,
    ROW      => row,
    UPD_ARR  => upd_arr,
    UPD_DATA => upd_data,
    DATA_OUT => data_out
  );

--------------------------------------------------------------------------------

  

end rtl;
