----------------------------------------------------------------------------------
-- ps2_pkg.vhd
-- PS2 package
-- 06 Oct, 2024
-- Semestral project in the autumn semester of 2024 in MPC-NDO.
-- Artem Gumenyuk (xgumen00@vutbr.cz)
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.math_real.all;


package VGA_pkg is

  constant c_H_PIXELS : integer    := 640;   --! horiztonal display width in pixels
  constant c_H_FP     : integer    := 16;    --! horiztonal front porch width in pixels
  constant c_H_PULSE  : integer    := 96;    --! horiztonal sync pulse width in pixels
  constant c_H_BP     : integer    := 48;    --! horiztonal back porch width in pixels
  constant c_H_POL    : std_logic  := '0';   --! horizontal sync pulse polarity (1 = positive, 0 = negative)
  constant c_V_PIXELS : integer    := 480;   --! vertical display width in rows
  constant c_V_FP     : integer    := 10;    --! vertical front porch width in rows
  constant c_V_PULSE  : integer    := 2;     --! vertical sync pulse width in rows
  constant c_V_BP     : integer    := 33;    --! vertical back porch width in rows
  constant c_V_POL    : std_logic  := '0';   --! vertical sync pulse polarity (1 = positive, 0 = negative)

  constant c_H_THIRD : integer := c_H_PIXELS/3;
  constant c_V_THIRD : integer := c_V_PIXELS/3;

  constant c_LINE     : integer := c_H_PIXELS+c_H_FP+c_H_PULSE+c_H_BP; --! Number of pixels in a line
  constant c_FRAME    : integer := c_V_PIXELS+c_V_FP+c_V_PULSE+c_V_BP; --! Number of lines in a frame
  constant c_cnt_h_w  : integer := integer(ceil(log2(real(c_LINE))));
  constant c_cnt_v_w  : integer := integer(ceil(log2(real(c_FRAME))));

end VGA_pkg;

package body VGA_pkg is
 
end VGA_pkg;