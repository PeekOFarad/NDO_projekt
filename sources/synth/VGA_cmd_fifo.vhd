----------------------------------------------------------------------------------
-- VGA_sram_mux.vhd
-- SRAM read/write multiplexor - write enabled only in VGA vertical blank space
-- 11 Oct, 2024
-- Semestral project in the autumn semester of 2024 in MPC-NDO.
-- Matej Stepan (xstepa67@vutbr.cz)
----------------------------------------------------------------------------------
-- note: Addressable food table is 5x32 cells
-- prices are 3 character each
-- portion amount is 4 chars
-- food type is 9 chars
-- Food name is 32 chars
-- invert last updated cell (for user as cursor) and revert back when cell index changed

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.math_real.all;
use work.VGA_pkg.all;

entity VGA_cmd_fifo is
  generic (
    g_SRAM_OFFSET   : integer := 0
  );
  Port ( 
    CLK         : in  std_logic;
    RST         : in  std_logic;
    COLUMN      : in  std_logic_vector (c_cnt_h_w-1 downto 0);  --! horizontal pixel coordinate
    ROW         : in  std_logic_vector (c_cnt_v_w-1 downto 0);  --! vertical pixel coordinate
    PIXEL_DATA  : out std_logic;
    RW_ADDR     : out std_logic_vector (17 downto 0);
    DATA        : inout  std_logic_vector (15 downto 0);
    CE_N        : out std_logic; --! chip enable, always low
    OE_N        : out std_logic;
    WE_N        : out std_logic; --! always high for reading
    LB_N        : out std_logic; --! Byte selection, always low
    UB_N        : out std_logic; --! Byte selection, always low
    CTRL_EN     : out std_logic  --!
  );
end VGA_cmd_fifo;

architecture rtl of VGA_cmd_fifo is

  signal font_raddr       : unsigned(10 downto 0) := (others => '0');
  signal data_o           : unsigned(7 downto 0)  := (others => '0');
  signal data_i           : unsigned(7 downto 0)  := (others => '0');

  
begin

 

  fontROM_inst : entity work.fontROM
  generic map (
    addrWidth => 11,
    dataWidth => 8
  )
  port map (
    clkA          => CLK,
    writeEnableA  => '0',
    addrA         => std_logic_vector(font_raddr),
    dataOutA      => std_logic_vector(data_o),
    dataInA       => std_logic_vector(data_i)
  );



  
end rtl;
