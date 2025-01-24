----------------------------------------------------------------------------------
-- common_pkg.vhd
-- Common package for server and clients parts
-- 26 Nov, 2024
-- Semestral project in the autumn semester of 2024 in MPC-NDO.
-- Artem Gumenyuk (xgumen00@vutbr.cz)
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.math_real.all;

package common_pkg is

  subtype char_t is std_logic_vector(7 downto 0);
  type char_buff_t is array(0 to 31) of char_t;
  
  type digit_arr_t is array(0 to 3) of char_t;
  type summ_digit_arr_t is array(0 to 6) of char_t;
  type summ_buff_t is array(0 to 11) of char_t;

end common_pkg;

package body common_pkg is
 
end common_pkg;