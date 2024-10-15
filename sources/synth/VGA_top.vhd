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
    H_SYNC    : out std_logic;
    V_SYNC    : out std_logic;
    RGB       : out std_logic_vector(2 downto 0)
  );
end VGA_top;

architecture rtl of VGA_top is

  -- signal int_PIXEL_CLK : std_logic;
  signal int_RST_P     : std_logic := '0';
  signal int_H_SYNC    : std_logic;
  signal int_V_SYNC    : std_logic;
  signal int_COLUMN    : std_logic_vector(c_cnt_h_w-1 downto 0);
  signal int_ROW       : std_logic_vector(c_cnt_v_w-1 downto 0);

begin


  VGA_ctrl_inst : entity work.VGA_ctrl
  port map (
    PIXEL_CLK => CLK,
    RST_P     => int_RST_P,
    H_SYNC    => int_H_SYNC,
    V_SYNC    => int_V_SYNC,
    COLUMN    => int_COLUMN,
    ROW       => int_ROW
  );

  VGA_img_gen_inst : entity work.VGA_img_gen
  port map (
    PIXEL_CLK => CLK,
    RST_P     => int_RST_P,
    H_SYNC_IN => int_H_SYNC,
    V_SYNC_IN => int_V_SYNC,
    COLUMN    => int_COLUMN,
    ROW       => int_ROW,
    H_SYNC    => H_SYNC,
    V_SYNC    => V_SYNC,
    RGB       => RGB
  );



end rtl;
