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
  
  -- special keys
  constant  c_up     : std_logic_vector (7 downto 0) := x"75";  -- 75
  constant  c_down   : std_logic_vector (7 downto 0) := x"72";  -- 72
  constant  c_left   : std_logic_vector (7 downto 0) := x"6B";  -- 6B
  constant  c_right  : std_logic_vector (7 downto 0) := x"74";  -- 74
  constant  c_esc    : std_logic_vector (7 downto 0) := x"76";  -- 76
  constant  c_bckspc : std_logic_vector (7 downto 0) := x"66";  -- 66
  constant  c_enter  : std_logic_vector (7 downto 0) := x"5A";  -- 5A
  -- special codes
  constant  c_f0     : std_logic_vector (7 downto 0) := x"F0";  -- F0
  constant  c_e0     : std_logic_vector (7 downto 0) := x"E0";  -- E0
  -- digits
  constant  c_0      : std_logic_vector (7 downto 0) := x"45";  -- 45
  constant  c_1      : std_logic_vector (7 downto 0) := x"16";  -- 16
  constant  c_2      : std_logic_vector (7 downto 0) := x"1E";  -- 1E
  constant  c_3      : std_logic_vector (7 downto 0) := x"26";  -- 26
  constant  c_4      : std_logic_vector (7 downto 0) := x"25";  -- 25
  constant  c_5      : std_logic_vector (7 downto 0) := x"2E";  -- 2E
  constant  c_6      : std_logic_vector (7 downto 0) := x"36";  -- 36
  constant  c_7      : std_logic_vector (7 downto 0) := x"3D";  -- 3D
  constant  c_8      : std_logic_vector (7 downto 0) := x"3E";  -- 3E
  constant  c_9      : std_logic_vector (7 downto 0) := x"46";  -- 46

  constant  c_0_int  : integer := 16#45#;  -- 45
  constant  c_1_int  : integer := 16#16#;  -- 16
  constant  c_2_int  : integer := 16#1E#;  -- 1E
  constant  c_3_int  : integer := 16#26#;  -- 26
  constant  c_4_int  : integer := 16#25#;  -- 25
  constant  c_5_int  : integer := 16#2E#;  -- 2E
  constant  c_6_int  : integer := 16#36#;  -- 36
  constant  c_7_int  : integer := 16#3D#;  -- 3D
  constant  c_8_int  : integer := 16#3E#;  -- 3E
  constant  c_9_int  : integer := 16#46#;  -- 46
  -- characters
  constant  c_min    : integer := 16#4E#; -- 4E -- -
  constant  c_eq     : integer := 16#55#; -- 55 -- =
  constant  c_q      : integer := 16#15#; -- 15
  constant  c_w      : integer := 16#1D#; -- 1D
  constant  c_e      : integer := 16#24#; -- 24
  constant  c_r      : integer := 16#2D#; -- 2D
  constant  c_t      : integer := 16#2C#; -- 2C
  constant  c_y      : integer := 16#35#; -- 35
  constant  c_u      : integer := 16#3C#; -- 3C
  constant  c_i      : integer := 16#43#; -- 43
  constant  c_o      : integer := 16#44#; -- 44
  constant  c_p      : integer := 16#4D#; -- 4D
  constant  c_lbr    : integer := 16#54#; -- 54 -- [
  constant  c_rbr    : integer := 16#5B#; -- 5B -- ]
  constant  c_bcksl  : integer := 16#5D#; -- 5D -- \
  constant  c_a      : integer := 16#1C#; -- 1C
  constant  c_s      : integer := 16#1B#; -- 1B
  constant  c_d      : integer := 16#23#; -- 23
  constant  c_f      : integer := 16#2B#; -- 2B
  constant  c_g      : integer := 16#34#; -- 34
  constant  c_h      : integer := 16#33#; -- 33
  constant  c_j      : integer := 16#3B#; -- 3B
  constant  c_k      : integer := 16#42#; -- 42
  constant  c_l      : integer := 16#4B#; -- 4B
  constant  c_semi   : integer := 16#4C#; -- 4C -- ;
  constant  c_ap     : integer := 16#52#; -- 52 -- '
  constant  c_caps   : integer := 16#58#; -- 58
  constant  c_shft   : integer := 16#59#; -- 59
  constant  c_z      : integer := 16#1A#; -- 1A
  constant  c_x      : integer := 16#22#; -- 22
  constant  c_c      : integer := 16#21#; -- 21
  constant  c_v      : integer := 16#2A#; -- 2A
  constant  c_b      : integer := 16#32#; -- 32
  constant  c_n      : integer := 16#31#; -- 31
  constant  c_m      : integer := 16#3A#; -- 3A
  constant  c_col    : integer := 16#41#; -- 41 -- ,
  constant  c_dot    : integer := 16#49#; -- 49 -- .
  constant  c_slsh   : integer := 16#4A#; -- 4A

  type sprit_rom_type is array (0 to 255) of STD_LOGIC_VECTOR(7 downto 0);

  -- PS2 to sprit
  -- ROM initialization with predefined values
  constant sprits_ROM: sprit_rom_type := (
--    TO_INTEGER(UNSIGNED(c_0))     => x"1f",
    c_0_int     => x"1f",
    c_1_int     => x"20",
    c_2_int     => x"21",
    c_3_int     => x"22",
    c_4_int     => x"23",
    c_5_int     => x"24",
    c_6_int     => x"25",
    c_7_int     => x"26",
    c_8_int     => x"27",
    c_9_int     => x"28",
    c_min       => x"1c",
    c_eq        => x"2c",
    c_a         => x"30",
    c_b         => x"31",
    c_c         => x"32",
    c_d         => x"33",
    c_e         => x"34",
    c_f         => x"35",
    c_g         => x"36",
    c_h         => x"37",
    c_i         => x"38",
    c_j         => x"39",
    c_k         => x"3a",
    c_l         => x"3b",
    c_m         => x"3c",
    c_n         => x"3d",
    c_o         => x"3e",
    c_p         => x"3f",
    c_q         => x"40",
    c_r         => x"41",
    c_s         => x"42",
    c_t         => x"43",
    c_u         => x"44",
    c_v         => x"45",
    c_w         => x"46",
    c_x         => x"47",
    c_y         => x"48",
    c_z         => x"49",
    c_lbr       => x"4a",
    c_rbr       => x"4c",
    c_bcksl     => x"4b",
    c_semi      => x"2a",
    c_ap        => x"16",
    c_col       => x"1b",
    c_dot       => x"1d",
    c_slsh      => x"1e",
    others  => x"00"
  );
  
  type t_keys is record
    up      : std_logic;
    down    : std_logic;
    left    : std_logic;
    right   : std_logic;
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