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

package ps2_pkg is

  type t_fsm_ps2rx is (idle, receive, parity, stop);
  
  constant  c_up     : std_logic_vector (7 downto 0) := "01110101";  -- 75
  constant  c_down   : std_logic_vector (7 downto 0) := "01110010";  -- 72
  constant  c_left   : std_logic_vector (7 downto 0) := "01101011";  -- 6B
  constant  c_right  : std_logic_vector (7 downto 0) := "01110100";  -- 74
  constant  c_esc    : std_logic_vector (7 downto 0) := "01110110";  -- 76
  constant  c_del    : std_logic_vector (7 downto 0) := "01110001";  -- 71
  constant  c_bckspc : std_logic_vector (7 downto 0) := "01100110";  -- 66
  constant  c_enter  : std_logic_vector (7 downto 0) := "01011010";  -- 5A
  constant  c_f0     : std_logic_vector (7 downto 0) := "11110000";  -- F0
  constant  c_e0     : std_logic_vector (7 downto 0) := "11100000";  -- E0
  constant  c_0      : std_logic_vector (7 downto 0) := "01000101";  -- 45
  constant  c_1      : std_logic_vector (7 downto 0) := "00010110";  -- 16
  constant  c_2      : std_logic_vector (7 downto 0) := "00011110";  -- 1E
  constant  c_3      : std_logic_vector (7 downto 0) := "00100110";  -- 26
  constant  c_4      : std_logic_vector (7 downto 0) := "00100101";  -- 25
  constant  c_5      : std_logic_vector (7 downto 0) := "00101110";  -- 2E
  constant  c_6      : std_logic_vector (7 downto 0) := "00110110";  -- 36
  constant  c_7      : std_logic_vector (7 downto 0) := "00111101";  -- 3D
  constant  c_8      : std_logic_vector (7 downto 0) := "00111110";  -- 3E
  constant  c_9      : std_logic_vector (7 downto 0) := "01000110";  -- 46
  -- characters
  constant  c_min    : std_logic_vector(7 downto 0) := "01001110"; -- 4E -- -
  constant  c_eq     : std_logic_vector(7 downto 0) := STD_LOGIC_VECTOR(TO_UNSIGNED(16#55#, 8)); -- 55 -- =
  constant  c_q      : std_logic_vector(7 downto 0) := STD_LOGIC_VECTOR(TO_UNSIGNED(16#15#, 8)); -- 15
  constant  c_w      : std_logic_vector(7 downto 0) := STD_LOGIC_VECTOR(TO_UNSIGNED(16#1D#, 8)); -- 1D
  constant  c_e      : std_logic_vector(7 downto 0) := STD_LOGIC_VECTOR(TO_UNSIGNED(16#24#, 8)); -- 24
  constant  c_r      : std_logic_vector(7 downto 0) := STD_LOGIC_VECTOR(TO_UNSIGNED(16#2D#, 8)); -- 2D
  constant  c_t      : std_logic_vector(7 downto 0) := STD_LOGIC_VECTOR(TO_UNSIGNED(16#2C#, 8)); -- 2C
  constant  c_y      : std_logic_vector(7 downto 0) := STD_LOGIC_VECTOR(TO_UNSIGNED(16#35#, 8)); -- 35
  constant  c_u      : std_logic_vector(7 downto 0) := STD_LOGIC_VECTOR(TO_UNSIGNED(16#3C#, 8)); -- 3C
  constant  c_i      : std_logic_vector(7 downto 0) := STD_LOGIC_VECTOR(TO_UNSIGNED(16#43#, 8)); -- 43
  constant  c_o      : std_logic_vector(7 downto 0) := STD_LOGIC_VECTOR(TO_UNSIGNED(16#44#, 8)); -- 44
  constant  c_p      : std_logic_vector(7 downto 0) := STD_LOGIC_VECTOR(TO_UNSIGNED(16#4D#, 8)); -- 4D
  constant  c_lbr      : std_logic_vector(7 downto 0) := STD_LOGIC_VECTOR(TO_UNSIGNED(16#54#, 8)); -- 54 -- [
  constant  c_rbr      : std_logic_vector(7 downto 0) := STD_LOGIC_VECTOR(TO_UNSIGNED(16#5B#, 8)); -- 5B -- ]
  constant  c_bcksl  : std_logic_vector(7 downto 0) := STD_LOGIC_VECTOR(TO_UNSIGNED(16#5D#, 8)); -- 5D -- \
  constant  c_a      : std_logic_vector(7 downto 0) := STD_LOGIC_VECTOR(TO_UNSIGNED(16#1C#, 8)); -- 1C
  constant  c_s      : std_logic_vector(7 downto 0) := STD_LOGIC_VECTOR(TO_UNSIGNED(16#1B#, 8)); -- 1B
  constant  c_d      : std_logic_vector(7 downto 0) := STD_LOGIC_VECTOR(TO_UNSIGNED(16#23#, 8)); -- 23
  constant  c_f      : std_logic_vector(7 downto 0) := STD_LOGIC_VECTOR(TO_UNSIGNED(16#2B#, 8)); -- 2B
  constant  c_g      : std_logic_vector(7 downto 0) := STD_LOGIC_VECTOR(TO_UNSIGNED(16#34#, 8)); -- 34
  constant  c_h      : std_logic_vector(7 downto 0) := STD_LOGIC_VECTOR(TO_UNSIGNED(16#33#, 8)); -- 33
  constant  c_j      : std_logic_vector(7 downto 0) := STD_LOGIC_VECTOR(TO_UNSIGNED(16#3B#, 8)); -- 3B
  constant  c_k      : std_logic_vector(7 downto 0) := STD_LOGIC_VECTOR(TO_UNSIGNED(16#42#, 8)); -- 42
  constant  c_l      : std_logic_vector(7 downto 0) := STD_LOGIC_VECTOR(TO_UNSIGNED(16#4B#, 8)); -- 4B
  constant  c_semi      : std_logic_vector(7 downto 0) := STD_LOGIC_VECTOR(TO_UNSIGNED(16#4C#, 8)); -- 4C -- ;
  constant  c_ap      : std_logic_vector(7 downto 0) := STD_LOGIC_VECTOR(TO_UNSIGNED(16#52#, 8)); -- 52 -- '
  constant  c_shft   : std_logic_vector(7 downto 0) := STD_LOGIC_VECTOR(TO_UNSIGNED(16#59#, 8)); -- 59
  constant  c_z      : std_logic_vector(7 downto 0) := STD_LOGIC_VECTOR(TO_UNSIGNED(16#1A#, 8)); -- 1A
  constant  c_x      : std_logic_vector(7 downto 0) := STD_LOGIC_VECTOR(TO_UNSIGNED(16#22#, 8)); -- 22
  constant  c_c      : std_logic_vector(7 downto 0) := STD_LOGIC_VECTOR(TO_UNSIGNED(16#21#, 8)); -- 21
  constant  c_v      : std_logic_vector(7 downto 0) := STD_LOGIC_VECTOR(TO_UNSIGNED(16#2A#, 8)); -- 2A
  constant  c_b      : std_logic_vector(7 downto 0) := STD_LOGIC_VECTOR(TO_UNSIGNED(16#32#, 8)); -- 32
  constant  c_n      : std_logic_vector(7 downto 0) := STD_LOGIC_VECTOR(TO_UNSIGNED(16#31#, 8)); -- 31
  constant  c_m      : std_logic_vector(7 downto 0) := STD_LOGIC_VECTOR(TO_UNSIGNED(16#3A#, 8)); -- 3A
  constant  c_col      : std_logic_vector(7 downto 0) := STD_LOGIC_VECTOR(TO_UNSIGNED(16#41#, 8)); -- 41 -- ,
  constant  c_dot      : std_logic_vector(7 downto 0) := STD_LOGIC_VECTOR(TO_UNSIGNED(16#49#, 8)); -- 49 -- .
  constant  c_slsh   : std_logic_vector(7 downto 0) := STD_LOGIC_VECTOR(TO_UNSIGNED(16#4A#, 8)); -- 4A
  
  
  type t_keys is record
    up      : std_logic;
    down    : std_logic;
    left    : std_logic;
    right   : std_logic;
    del     : std_logic;
    bckspc  : std_logic;
    esc     : std_logic;
    enter   : std_logic;
    char    : std_logic;
    number  : std_logic;
  end record t_keys;
  
  type t_fsm_dekoder  is (idle, end_code, special_code, set_key);

end ps2_pkg;

package body ps2_pkg is
 
end ps2_pkg;