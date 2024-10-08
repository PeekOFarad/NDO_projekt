----------------------------------------------------------------------------------
-- ps2_pkg.vhd
-- PS2 package
-- 06 Oct, 2024
-- Semestral project in the autumn semester of 2024 in MPC-NDO.
-- Artem Gumenyuk (xgumen00@vutbr.cz)
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package ps2_pkg is

  type t_fsm_ps2rx is (idle, receive, parity, stop);
  
  constant  c_up    : std_logic_vector (7 downto 0) := "01110101";  -- 75
  constant  c_down  : std_logic_vector (7 downto 0) := "01110010";  -- 72
  constant  c_esc   : std_logic_vector (7 downto 0) := "01110110";  -- 76
  constant  c_del   : std_logic_vector (7 downto 0) := "01110001";  -- 71
  constant  c_enter : std_logic_vector (7 downto 0) := "01011010";  -- 5A
  constant  c_f0    : std_logic_vector (7 downto 0) := "11110000";  -- F0
  constant  c_e0    : std_logic_vector (7 downto 0) := "11100000";  -- E0
  
  type t_keys is record
    up      : std_logic;
    down    : std_logic;
    del     : std_logic;
    esc     : std_logic;
    enter   : std_logic;
  end record t_keys;
  
  type t_fsm_dekoder  is (idle, end_code, special_code, set_key);

end ps2_pkg;

package body ps2_pkg is
 
end ps2_pkg;