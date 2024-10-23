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

entity VGA_sram_mux is
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
    UB_N        : out std_logic  --! Byte selection, always low
  );
end VGA_sram_mux;

architecture rtl of VGA_sram_mux is

  constant c_fontROM_size : integer := 128*16; -- = 2048

  type t_fsm_sram_mux is (init, run);
    
  signal state, next_state : t_fsm_sram_mux := init;

  signal we_n_int       : std_logic := '1';

  signal VGA_buffer_s   : std_logic_vector(15 downto 0) := (others => '0'); --! buffer
  signal VGA_buffer_c   : std_logic_vector(15 downto 0) := (others => '0'); --! buffer

  signal cnt_shift_s    : unsigned(3 downto 0) := (others => '0');
  signal cnt_shift_c    : unsigned(3 downto 0) := (others => '0');
  signal sram_re_n      : std_logic := '1'; 
  signal shreg_empty_n  : std_logic := '1';
  signal v_porch_n      : std_logic := '1';

  signal cnt_raddr_s    : unsigned(17 downto 0) := (others => '0');
  signal cnt_raddr_c    : unsigned(17 downto 0) := (others => '0');

  signal cnt_waddr_s    : unsigned(17 downto 0) := (others => '0');
  signal cnt_waddr_c    : unsigned(17 downto 0) := (others => '0');

  signal cnt_ROM_s      : unsigned(11 downto 0) := (others => '0');
  signal cnt_ROM_c      : unsigned(11 downto 0) := (others => '0');
  
  signal u_column       : unsigned(c_cnt_h_w-1 downto 0) := (others => '0');
  signal u_row          : unsigned(c_cnt_v_w-1 downto 0) := (others => '0');

  signal dataInA        : std_logic_vector(7 downto 0)  := (others => '0');
  signal dataOutA       : std_logic_vector(7 downto 0)  := (others => '0');
  -- signal dataOut16_s    : std_logic_vector(15 downto 0) := (others => '0');
  signal dataOut16_c    : std_logic_vector(15 downto 0) := (others => '0');

  signal clk_half_en       : std_logic := '0';

begin

  process (CLK)
	begin
		if rising_edge(CLK) then
			clk_half_en <= NOT clk_half_en;
		end if;
	end process;

  u_column  <= unsigned(COLUMN);
  u_row     <= unsigned(ROW);

  DATA <= dataOutA & dataOutA when state = init else
          (others => 'Z');
  RW_ADDR <=  std_logic_vector(cnt_waddr_s) when v_porch_n = '0' else
              std_logic_vector(cnt_raddr_s);
  OE_N    <= sram_re_n;
  CE_N    <= CLK; -- sram_re_n;
  WE_N    <= we_n_int; --! write enable signal 
  UB_N    <= '0' when cnt_ROM_s(cnt_ROM_s'low) = '0' and state = init else '1';
  LB_N    <= '0' when cnt_ROM_s(cnt_ROM_s'low) = '1' and state = init else '1';


  PIXEL_DATA <= VGA_buffer_s(VGA_buffer_s'low);

  p_reg: process (CLK)
  begin
  if rising_edge(CLK) then
    if RST = '1' then
      state         <= init;
      VGA_buffer_s  <= (others => '0');
      cnt_raddr_s   <= (others => '0');
      cnt_shift_s   <= (others => '0');
      cnt_ROM_s     <= (others => '0');
      cnt_waddr_s   <= (others => '0');
    else
      state         <= next_state;
      VGA_buffer_s  <= VGA_buffer_c;
      cnt_raddr_s   <= cnt_raddr_c;
      cnt_shift_s   <= cnt_shift_c;
      -- if clk_half_en = '1' then
        cnt_waddr_s   <= cnt_waddr_c;
      -- end if;
      cnt_ROM_s     <= cnt_ROM_c;
    end if;
  end if;
  end process;

  VGA_buffer_c <= DATA when cnt_shift_s >= 2**cnt_shift_s'length-1 else
                  '0' & VGA_buffer_s(VGA_buffer_s'high downto VGA_buffer_s'low+1);

  cnt_shift_c <= cnt_shift_s + 1;

  shreg_empty_n <= '0' when cnt_shift_s >= 2**cnt_shift_s'length-1-g_SRAM_OFFSET else '1'; -- TODO: determine clock offset for read delay
  sram_re_n     <= (NOT shreg_empty_n) NAND v_porch_n; -- sram_re_n active when shreg is empty and we're not in vert porch
  
  --! Generates sram read address and v_porch_n signal that allows write opperations
  p_cnt: process (cnt_raddr_s, u_row, cnt_ROM_s, cnt_waddr_s, v_porch_n, state)
  begin
    -- increment once every two ROM read cycles
    cnt_waddr_c <= cnt_waddr_s;
    if state = init and cnt_ROM_s > 1 and cnt_ROM_s(cnt_ROM_s'low) = '0' then -- cnt_ROM_s(cnt_ROM_s'low) = '1' and 
      cnt_waddr_c <= cnt_waddr_s + 1;
    end if;
    -- stop counting when ROM is read
    cnt_ROM_c  <= cnt_ROM_s;
    if v_porch_n = '0' and state = init and cnt_ROM_s < c_fontROM_size then
      cnt_ROM_c   <= cnt_ROM_s + 1;
    end if;
    
    v_porch_n   <= '1';
    cnt_raddr_c <= cnt_raddr_s + 1;
    if u_row >= c_V_PIXELS then
      v_porch_n   <= '0';
      cnt_raddr_c <= (others => '0');
    end if;
  end process;

  fontROM_inst : entity work.fontROM
  generic map (
    addrWidth => 11,
    dataWidth => 8
  )
  port map (
    clkA => CLK,
    writeEnableA => '0',
    addrA => std_logic_vector(cnt_ROM_s(cnt_ROM_s'high-1 downto cnt_ROM_s'low)),
    dataOutA => dataOutA,
    dataInA => dataInA
  );


  p_fsm: process (state, cnt_ROM_s)
  begin
    we_n_int    <= '1';

    case state is

      when init =>
        we_n_int    <= v_porch_n;

        next_state <= init;
        if cnt_ROM_s >= c_fontROM_size then 
          next_state <= run;
        end if;

      when run =>
        next_state <= run;
    
      when others =>
        null;
    end case;
    
  end process;



  
end rtl;
