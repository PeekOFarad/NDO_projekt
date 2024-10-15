----------------------------------------------------------------------------------
-- ps2_top.vhd
-- PS2 top hierarchy design block.
-- 08 Oct, 2024
-- Semestral project in the autumn semester of 2024 in MPC-NDO.
-- Artem Gumenyuk (xgumen00@vutbr.cz)
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.VGA_pkg.all;

entity ps2_top is
    Port ( CLK      : in STD_LOGIC;
           PS2_CLK  : in STD_LOGIC;
           PS2_DATA : in STD_LOGIC;
           KEYS     : out t_keys);
end ps2_top;

architecture Behavioral of ps2_top is

  -- PS2 receiver
  component ps2_rx is
    Port ( CLK        : in  STD_LOGIC;
           PS2_CLK    : in  STD_LOGIC;
           PS2_DATA   : in  STD_LOGIC;
           CODE_READY : out STD_LOGIC;
           PS2_CODE   : out STD_LOGIC_VECTOR (7 downto 0));
  end component;
  
  -- PS2 output decoder
  component ps2_decoder is
    Port ( CLK        : in STD_LOGIC;
           CODE_READY : in STD_LOGIC;
           PS2_CODE   : in STD_LOGIC_VECTOR(7 downto 0);
           KEYS       : out t_keys);
  end component;
  
  signal code_ready_tb : std_logic;
  signal ps2_code_tb   : std_logic_vector(7 downto 0);

begin

  ps2_rx_i : ps2_rx
  port map(
    CLK        => CLK,
    PS2_CLK    => PS2_CLK,
    PS2_DATA   => PS2_DATA,
    CODE_READY => code_ready_tb,
    PS2_CODE   => ps2_code_tb
  );

  ps2_decoder_i : ps2_decoder
  port map(
    CLK        => CLK,
    CODE_READY => code_ready_tb,
    PS2_CODE   => ps2_code_tb,
    KEYS       => KEYS
  );

end Behavioral;
