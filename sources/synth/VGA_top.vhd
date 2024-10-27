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

entity VGA_top is
  PORT(
    CLK : in std_logic;
    -- VGA
    H_SYNC    : out std_logic;
    V_SYNC    : out std_logic;
    RGB       : out std_logic_vector(2 downto 0);
    --SRAM
    RW_ADDR   : out std_logic_vector (17 downto 0);
    DATA      : inout  std_logic_vector (15 downto 0);
    CE_N      : out std_logic; --! chip enable, always low
    OE_N      : out std_logic;
    WE_N      : out std_logic; --! always high for reading
    LB_N      : out std_logic; --! Byte selection, always low
    UB_N      : out std_logic  --! Byte selection, always low
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
  
begin

	process (CLK)
	begin
		if rising_edge(CLK) then
			PIXEL_CLK <= NOT PIXEL_CLK;
		end if;
	end process;

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
  generic map (
    g_SRAM_OFFSET => 1
  )
  port map (
    CLK         => PIXEL_CLK,
    RST         => '0',
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
