----------------------------------------------------------------------------------
-- VGA_sram_mux.vhd
-- SRAM read/write multiplexor - write enabled only in VGA vertical blank space
-- 11 Oct, 2024
-- Semestral project in the autumn semester of 2024 in MPC-NDO.
-- Matej Stepan (xstepa67@vutbr.cz)
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.math_real.all;
use work.VGA_pkg.all;

entity VGA_sram_mux is
  generic (
    g_SRAM_OFFSET   : integer := 0
  );
  Port ( 
    CLK         : in  std_logic;
    RST         : in  std_logic;
    W_DATA      : out  std_logic_vector (15 downto 0);
    COLUMN      : in  std_logic_vector (c_cnt_h_w-1 downto 0);  --! horizontal pixel coordinate
    ROW         : in  std_logic_vector (c_cnt_v_w-1 downto 0);  --! vertical pixel coordinate
    R_DATA_i    : in  std_logic_vector (15 downto 0);
    PIXEL_DATA  : out std_logic;
    RW_ADDR      : out std_logic_vector (17 downto 0);
    CE_N        : out std_logic; --! chip enable, always low
    OE_N        : out std_logic;
    WE_N        : out std_logic --! always high for reading
    -- LB_N        : out std_logic; --! Byte selection, always low
    -- UB_N        : out std_logic  --! Byte selection, always low
  );
end VGA_sram_mux;

architecture rtl of VGA_sram_mux is

  -- signal r_addr_int   : unsigned(17 downto 0);
  signal VGA_buffer_s : std_logic_vector(15 downto 0) := (others => '0'); --! buffer
  signal VGA_buffer_c : std_logic_vector(15 downto 0) := (others => '0'); --! buffer

  signal cnt_shift_s    : unsigned(3 downto 0) := (others => '0');
  signal cnt_shift_c    : unsigned(3 downto 0) := (others => '0');
  signal sram_re_n      : std_logic := '1';
  signal shreg_empty_n  : std_logic := '1';
  signal v_porch_n      : std_logic := '1';

  signal cnt_raddr_s  : unsigned(17 downto 0) := (others => '0');
  signal cnt_raddr_c  : unsigned(17 downto 0) := (others => '0');
  
  signal u_column : unsigned(c_cnt_h_w-1 downto 0) := (others => '0');
  signal u_row    : unsigned(c_cnt_v_w-1 downto 0) := (others => '0');

begin

  u_column  <= unsigned(COLUMN);
  u_row     <= unsigned(ROW);

  RW_ADDR <= std_logic_vector(cnt_raddr_s);
  OE_N    <= sram_re_n;
  CE_N    <= sram_re_n;
  WE_N    <= '1' OR v_porch_n;

  PIXEL_DATA <= VGA_buffer_s(VGA_buffer_s'low);

  p_reg: process (CLK)
  begin
  if rising_edge(CLK) then
    if RST = '1' then
      VGA_buffer_s <= (others => '0');
      cnt_raddr_s  <= (others => '0');
      cnt_shift_s  <= (others => '0');
    else

      VGA_buffer_s  <= VGA_buffer_c;
      cnt_raddr_s   <= cnt_raddr_c;
      cnt_shift_s   <= cnt_shift_c;
    end if;
  end if;
  end process;

  VGA_buffer_c <= R_DATA_i when cnt_shift_s >= 2**cnt_shift_s'length-1 else
                  '0' & VGA_buffer_s(VGA_buffer_s'high downto VGA_buffer_s'low+1);

  cnt_shift_c <= cnt_shift_s + 1;

  shreg_empty_n <= '0' when cnt_shift_s >= 2**cnt_shift_s'length-1-g_SRAM_OFFSET else '1'; -- TODO: determine clock offset for read delay
  sram_re_n     <= (NOT shreg_empty_n) NAND v_porch_n; -- sram_re_n active when shreg is empty and we're not in vert porch
  
  --! Generates sram read address and v_porch_n signal that allows write opperations
  p_cnt: process (cnt_shift_s)
  begin
    v_porch_n   <= '1';
    cnt_raddr_c <= cnt_raddr_s + 1;
    if u_row >= c_V_PIXELS then
      v_porch_n   <= '0';
      cnt_raddr_c <= (others => '0');
    end if;
  end process;

  
end rtl;
