----------------------------------------------------------------------------------
-- VGA.vhd
-- VGA controller - 640x480 @ 60Hz Industry standart timing
-- General Timing
-- Screen refresh rate	60 Hz
-- Vertical refresh	31.46875 kHz
-- Pixel freq.	25.175 MHz
-- 
-- Horizontal timing (line)
-- Polarity of horizontal sync pulse is negative.
-- Scanline part	Pixels	      Time [µs]
-- Visible area	   640	    25.422045680238
-- Front porch	   16	      0.63555114200596
-- Sync pulse	     96	      3.8133068520357
-- Back porch	     48	      1.9066534260179
-- Whole line	     800	    31.777557100298
-- 
-- Vertical timing (frame)
-- Polarity of vertical sync pulse is negative.
-- Frame part	    Lines	        Time [ms]
-- Visible area	   480	    15.253227408143
-- Front porch	   10	      0.31777557100298
-- Sync pulse	     2	      0.063555114200596
-- Back porch	     33	      1.0486593843098
-- Whole frame	   525	    16.683217477656

-- 11 Oct, 2024
-- Semestral project in the autumn semester of 2024 in MPC-NDO.
-- Matej Stepan (xstepa67@vutbr.cz)
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.math_real.all;
use work.VGA_pkg.all;
use work.server_pkg.all;
use work.common_pkg.all;

entity VGA_top is
  PORT(
    CLK : in std_logic;
    --------------------------------------------------------------------------------
    -- SYSTEM INTERFACE
    COL_SYS     : in  STD_LOGIC_VECTOR (2 downto 0);
    ROW_SYS     : in  STD_LOGIC_VECTOR (5 downto 0);
    UPD_ARR     : in  STD_LOGIC;
    UPD_DATA    : in  STD_LOGIC;
    DATA_SYS    : in  char_buff_t;
    VGA_RDY     : out std_logic;
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
    UB_N      : out std_logic  --! Byte selection, always low
    --------------------------------------------------------------------------------
  );
end VGA_top;

architecture rtl of VGA_top is

  -- signal int_PIXEL_CLK : std_logic;
  -- signal int_RST_P     : std_logic := '0';
  -- signal int_H_SYNC     : std_logic;
  -- signal int_V_SYNC     : std_logic;
  signal int_COLUMN     : std_logic_vector(c_cnt_h_w-1 downto 0);
  signal int_ROW        : std_logic_vector(c_cnt_v_w-1 downto 0);
  signal PIXEL_CLK		  : std_logic := '0';
  signal PIXEL_DATA		  : std_logic := '0';
  signal CTRL_EN        : std_logic := '0';
  signal RST            : std_logic := '1';

  --------------------------------------------------------------------------------
  -- SYSTEM MODEL
  signal cnt_sys_div_s  : unsigned(15 downto 0) := (others => '0');
  signal cnt_sys_div_c  : unsigned(15 downto 0) := (others => '0');
  signal cnt_sys_s      : unsigned(1 downto 0) := (others => '0');
  signal cnt_sys_c      : unsigned(1 downto 0) := (others => '0');

  signal bfm_COL_SYS    : std_logic_vector(2 downto 0);
  signal bfm_ROW_SYS    : std_logic_vector(5 downto 0);
  signal bfm_UPD_ARR    : std_logic := '0';
  signal bfm_UPD_DATA   : std_logic := '0';

  signal bfm_DATA_SYS   : char_buff_t := ((others => (others => '0')));
  signal bfm_DATA_SYS0  : char_buff_t := ( x"31", x"3e", x"3e",x"31",x"30",x"42",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00");
  signal bfm_DATA_SYS1  : char_buff_t := ( x"30", x"41", x"34",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00");
  signal bfm_DATA_SYS2  : char_buff_t := ( x"43", x"37", x"34",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00");
  signal bfm_DATA_SYS3  : char_buff_t := ( x"42", x"37", x"43",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00");
  --------------------------------------------------------------------------------
  
begin

  --------------------------------------------------------------------------------
  -- SYSTEM MODEL
  -- process (PIXEL_CLK)
  -- begin
  --   if rising_edge(PIXEL_CLK) then
  --     cnt_sys_s       <= cnt_sys_c;
  --     cnt_sys_div_s   <= cnt_sys_div_c;
  --   end if;
    
  -- end process;

  -- process (cnt_sys_div_s, cnt_sys_s)
  -- begin
  --   cnt_sys_c       <= cnt_sys_s;
  --   cnt_sys_div_c   <= cnt_sys_div_s + 1;
  --   if cnt_sys_div_s = (2**cnt_sys_div_s'length)-1 then
  --     cnt_sys_c     <= cnt_sys_s + 1;
  --   end if;
  -- end process;

  -- bfm_UPD_DATA <= '1' when cnt_sys_div_s = 0 else '0';

  -- bfm_DATA_SYS <= bfm_DATA_SYS0 when cnt_sys_s = 0 else
  --                 bfm_DATA_SYS1 when cnt_sys_s = 1 else
  --                 bfm_DATA_SYS2 when cnt_sys_s = 2 else
  --                 bfm_DATA_SYS3 when cnt_sys_s = 3 else
  --                 (others => (others => '0'));

  -- bfm_COL_SYS <=  std_logic_vector(resize(cnt_sys_s, bfm_COL_SYS'length));

  -- bfm_ROW_SYS <=  std_logic_vector(to_unsigned(0, bfm_ROW_SYS'length));


  --------------------------------------------------------------------------------

	-- process (CLK)
	-- begin
	-- 	if rising_edge(CLK) then
	-- 		PIXEL_CLK <= NOT PIXEL_CLK;
	-- 	end if;
	-- end process;

  PIXEL_CLK <= CLK;

  process (PIXEL_CLK)
  begin
    if rising_edge(PIXEL_CLK) then
      RST <= '0';
    end if;
  end process;

  RGB <= PIXEL_DATA & PIXEL_DATA & PIXEL_DATA;

  VGA_ctrl_inst : entity work.VGA_ctrl
  port map (
    PIXEL_CLK => PIXEL_CLK,
    RST_P     => NOT CTRL_EN,
    -- CTRL_EN   => CTRL_EN,
    H_SYNC    => H_SYNC,
    V_SYNC    => V_SYNC,
    COLUMN    => int_COLUMN,
    ROW       => int_ROW
  );


  VGA_sram_mux_inst : entity work.VGA_sram_mux
  port map (
    CLK         => PIXEL_CLK,
    RST         => '0',
    COL_SYS     => COL_SYS,   -- bfm_COL_SYS  ,   
    ROW_SYS     => ROW_SYS,   -- bfm_ROW_SYS  ,    
    UPD_ARR     => UPD_ARR,   -- bfm_UPD_ARR  ,
    UPD_DATA    => UPD_DATA,  -- bfm_UPD_DATA ,
    DATA_SYS    => DATA_SYS,  -- bfm_DATA_SYS ,
    VGA_RDY     => VGA_RDY,
    CTRL_EN     => CTRL_EN,
    COLUMN      => int_COLUMN,
    ROW         => int_ROW,
    PIXEL_DATA  => PIXEL_DATA,
    RW_ADDR     => RW_ADDR,
    DATA        => DATA,
    CE_N        => CE_N,
    OE_N        => OE_N,
    WE_N        => WE_N,
    LB_N        => LB_N,
    UB_N        => UB_N
  );



  -- VGA_img_gen_inst : entity work.VGA_img_gen
  -- port map (
  --   PIXEL_CLK => PIXEL_CLK,
  --   RST_P     => '0',
  --   H_SYNC_IN => int_H_SYNC,
  --   V_SYNC_IN => int_V_SYNC,
  --   COLUMN    => int_COLUMN,
  --   ROW       => int_ROW,
  --   H_SYNC    => H_SYNC,
  --   V_SYNC    => V_SYNC,
  --   RGB       => RGB
  -- );



end rtl;
