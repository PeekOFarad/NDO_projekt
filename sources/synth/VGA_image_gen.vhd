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

entity VGA_img_gen is
  PORT(
    PIXEL_CLK   : IN  std_logic;                              --! pixel clock at frequency of VGA mode being used
    RST_P       : IN  std_logic;                              --! active high sycnchronous reset
    H_SYNC_IN   : IN  std_logic;                              --! horiztonal sync pulse
    V_SYNC_IN   : IN  std_logic;                              --! vertical sync pulse
    COLUMN      : IN  std_logic_vector(c_cnt_h_w-1 downto 0); --! horizontal pixel coordinate
    ROW         : IN  std_logic_vector(c_cnt_v_w-1 downto 0); --! vertical pixel coordinate
    H_SYNC      : OUT std_logic;                              --! horiztonal sync pulse
    V_SYNC      : OUT std_logic;                              --! vertical sync pulse
    RGB         : OUT std_logic_vector(2 downto 0)
  );
end VGA_img_gen;

architecture rtl of VGA_img_gen is

  signal RGB_c    : std_logic_vector(2 downto 0);
  signal u_column : unsigned(c_cnt_h_w-1 downto 0);
  signal u_row    : unsigned(c_cnt_v_w-1 downto 0);

begin

  u_column  <= unsigned(COLUMN);
  u_row     <= unsigned(ROW);

--! Registers  
p_registers: process (PIXEL_CLK)
begin
  if rising_edge(PIXEL_CLK) then 
    if RST_P = '1' then
      RGB     <=  (others => '0');
      H_SYNC  <=  NOT c_H_POL;
      V_SYNC  <=  NOT c_V_POL;
    else
      RGB     <=  RGB_c;
      H_SYNC  <=  H_SYNC_IN;
      V_SYNC  <=  v_SYNC_IN;
    end if;
  end if;
end process;

RGB_c <=  "000" when ((u_column <= c_H_THIRD-1)   AND (u_row <= c_V_THIRD-1))   else
          "001" when ((u_column <= 2*c_H_THIRD-1) AND (u_row <= c_V_THIRD-1))   else
          "010" when ((u_column <= c_H_PIXELS)    AND (u_row <= c_V_THIRD-1))   else
          "011" when ((u_column <= c_H_THIRD-1)   AND (u_row <= 2*c_V_THIRD-1)) else
          "000" when ((u_column <= 2*c_H_THIRD-1) AND (u_row <= 2*c_V_THIRD-1)) else
          "100" when ((u_column <= c_H_PIXELS)    AND (u_row <= 2*c_V_THIRD-1)) else
          "101" when ((u_column <= c_H_THIRD-1)   AND (u_row <= 3*c_V_THIRD-1)) else
          "110" when ((u_column <= 2*c_H_THIRD-1) AND (u_row <= c_V_PIXELS-1)) else
          "111" when ((u_column <= c_H_PIXELS)    AND (u_row <= c_V_PIXELS-1)) else
          "001"; 


end rtl;
