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

entity VGA_ctrl is
  PORT(
    PIXEL_CLK : IN   std_logic;                     --! pixel clock at frequency of VGA mode being used
    RST_P     : IN   std_logic;                     --! active high sycnchronous reset
    -- CTRL_EN   : IN   std_logic;                     --!
    H_SYNC    : OUT  std_logic;                     --! horiztonal sync pulse
    V_SYNC    : OUT  std_logic;                     --! vertical sync pulse
    COLUMN    : OUT  std_logic_vector(c_cnt_h_w-1 downto 0);   --! horizontal pixel coordinate
    ROW       : OUT  std_logic_vector(c_cnt_v_w-1 downto 0)    --! vertical pixel coordinate
  );
end VGA_ctrl;

architecture rtl of VGA_ctrl is

  signal cnt_h_c      : unsigned(c_cnt_h_w-1 downto 0)  := (others => '0'); --! horizontal counter
  signal cnt_h_s      : unsigned(c_cnt_h_w-1 downto 0)  := (others => '0'); --! horizontal counter
  signal cnt_v_c      : unsigned(c_cnt_v_w-1 downto 0)  := (others => '0'); --! vertical counter
  signal cnt_v_s      : unsigned(c_cnt_v_w-1 downto 0)  := (others => '0'); --! vertical counter

  signal h_sync_c   : std_logic := '1';
  signal v_sync_c   : std_logic := '1';


begin

--! Registers  
p_registers: process (PIXEL_CLK)
begin
  if rising_edge(PIXEL_CLK) then 
    if RST_P = '1' then
      cnt_h_s <= (others => '0');
      cnt_v_s <= (others => '0');
      H_SYNC  <= NOT c_H_POL;
      V_SYNC  <= NOT c_V_POL;
    else
      cnt_h_s <= cnt_h_c;
      cnt_v_s <= cnt_v_c;
      H_SYNC <= h_sync_c;
      V_SYNC <= v_sync_c;
    end if;
  end if;
end process;

--! Counter logic for horizontal and vertical sweep
p_cnt: process (cnt_h_s, cnt_v_s)
begin
  cnt_h_c <= cnt_h_s + 1 ;  -- default increment horizontal
  cnt_v_c <= cnt_v_s;       -- default save vertical 
  if cnt_h_s >= c_LINE - 1 then -- if at end of line, reset horizontal counter and increment vertical
    cnt_h_c <= (others => '0');
	  cnt_v_c <= cnt_v_s + 1;
    if cnt_v_s >= c_FRAME - 1 then -- if at end of screen, reset vertical counter 
      cnt_v_c <= (others => '0');
    end if;		
  end if;
end process;

--! H_SYNC and V_SYNC generation
p_sync: process (cnt_h_s, cnt_v_s)
begin
  h_sync_c <= NOT c_H_POL;  -- default deasserted
  v_sync_c <= NOT c_V_POL;  -- default deasserted
  -- assert when cnt_h in sync pulse range
  if ((cnt_h_s > c_H_PIXELS + c_H_FP) AND (cnt_h_s <= c_H_PIXELS + c_H_FP + c_H_PULSE)) then
    h_sync_c <= c_H_POL;
  end if;
  -- assert when cnt_h in sync pulse range
  if ((cnt_v_s > c_V_PIXELS + c_V_FP) AND (cnt_v_s <= c_V_PIXELS + c_V_FP + c_V_PULSE)) then
    v_sync_c <= c_V_POL;
  end if;
end process;

COLUMN  <= STD_LOGIC_VECTOR(cnt_h_s);
ROW     <= STD_LOGIC_VECTOR(cnt_v_s);


end rtl;
