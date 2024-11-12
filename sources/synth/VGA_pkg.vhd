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
  constant c_V_FP     : integer    := 11;    --! vertical front porch width in rows
  constant c_V_PULSE  : integer    := 2;     --! vertical sync pulse width in rows
  constant c_V_BP     : integer    := 32;    --! vertical back porch width in rows
  constant c_V_POL    : std_logic  := '0';   --! vertical sync pulse polarity (1 = positive, 0 = negative)

  constant c_H_THIRD : integer := c_H_PIXELS/3;
  constant c_V_THIRD : integer := c_V_PIXELS/3;

  constant c_LINE     : integer := c_H_PIXELS+c_H_FP+c_H_PULSE+c_H_BP; --! Number of pixels in a line
  constant c_FRAME    : integer := c_V_PIXELS+c_V_FP+c_V_PULSE+c_V_BP; --! Number of lines in a frame
  constant c_cnt_h_w  : integer := integer(ceil(log2(real(c_LINE))));
  constant c_cnt_v_w  : integer := integer(ceil(log2(real(c_FRAME))));
  
  function bit_reverse (arg:std_logic_vector) return std_logic_vector;

  constant c_COL_NUM      : integer := c_H_PIXELS/8; -- 80
  constant c_COL_NUM_BIN  : integer := integer(ceil(log2(real(c_COL_NUM)))); -- 7

  constant c_ROW_NUM      : integer := c_V_PIXELS/12; -- 40
  constant c_ROW_NUM_BIN  : integer := integer(ceil(log2(real(c_ROW_NUM)))); -- 6

  constant c_CHAR_NUM : integer := 85;

  subtype t_char_col is integer range 0 to c_COL_NUM-1;
  subtype t_char_row is integer range 0 to c_ROW_NUM-1;
  subtype t_char_id  is integer range 0 to c_CHAR_NUM-1;

  type t_char is record
    column : t_char_col;
    row    : t_char_row;
    id     : t_char_id;
  end record;

  constant c_CHAR_FIFO_SIZE : integer := 32; -- ((c_FRAME-c_V_PIXELS)*c_LINE)
  type t_char_fifo is array (0 to c_CHAR_FIFO_SIZE-1) of t_char;

  -- type t_char_fifo is array (0 to C_CHAR_FIFO_SIZE-1) of t_char;


  

end VGA_pkg;

package body VGA_pkg is

  function bit_reverse (arg:std_logic_vector) return std_logic_vector is
    variable ret : std_logic_vector(arg'range);
  begin
    for i in arg'range loop
      ret(ret'low+i) := arg(arg'high-i);
    end loop;
    return ret;
  end function;


 
end VGA_pkg;