----------------------------------------------------------------------------------
-- server_pkg.vhd
-- Server package
-- 14 Oct, 2024
-- Semestral project in the autumn semester of 2024 in MPC-NDO.
-- Artem Gumenyuk (xgumen00@vutbr.cz)
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package server_pkg is

  subtype amount_t is std_logic_vector(11 downto 0);
  
  subtype price_t is std_logic_vector(7 downto 0);
  
  constant c_FOOD_TYPES_CNT : integer := 32;

end server_pkg;

package body server_pkg is
 
end server_pkg;