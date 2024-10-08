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
  constant  c_0     : std_logic_vector (7 downto 0) := "01000101";  -- 45
  constant  c_1     : std_logic_vector (7 downto 0) := "00010110";  -- 16
  constant  c_2     : std_logic_vector (7 downto 0) := "00011110";  -- 1E
  constant  c_3     : std_logic_vector (7 downto 0) := "00100110";  -- 26
  constant  c_4     : std_logic_vector (7 downto 0) := "00100101";  -- 25
  constant  c_5     : std_logic_vector (7 downto 0) := "00101110";  -- 2E
  constant  c_6     : std_logic_vector (7 downto 0) := "00110110";  -- 36
  constant  c_7     : std_logic_vector (7 downto 0) := "00111101";  -- 3D
  constant  c_8     : std_logic_vector (7 downto 0) := "00111110";  -- 3E
  constant  c_9     : std_logic_vector (7 downto 0) := "01000110";  -- 46
  
  type t_keys is record
    up      : std_logic;
    down    : std_logic;
    del     : std_logic;
    esc     : std_logic;
    enter   : std_logic;
    number  : std_logic;
  end record t_keys;
  
  type t_fsm_dekoder  is (idle, end_code, special_code, set_key);

end ps2_pkg;

package body ps2_pkg is
 
end ps2_pkg;