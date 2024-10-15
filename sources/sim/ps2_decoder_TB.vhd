----------------------------------------------------------------------------------
-- ps2_decoder_TB.vhd
-- PS2 decoder Testbench.
-- 08 Oct, 2024
-- Semestral project in the autumn semester of 2024 in MPC-NDO.
-- Artem Gumenyuk (xgumen00@vutbr.cz)
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.VGA_pkg.all;

entity ps2_decoder_TB is
end ps2_decoder_TB;

architecture Behavioral of ps2_decoder_TB is

  component ps2_decoder is
    Port ( CLK        : in STD_LOGIC;
           CODE_READY : in STD_LOGIC;
           PS2_CODE   : in STD_LOGIC_VECTOR(7 downto 0);
           KEYS       : out t_keys);
  end component;
  
--------------------------------------------------------------------------------

  constant clk_per              : time := 1 ns; 
  constant ps2_clk_per          : time := 1000 ns;
  signal   simulation_finished  : BOOLEAN := FALSE;

  signal   clk                  : std_logic := '0';
  signal   code_ready           : std_logic := '0';
  signal   ps2_code             : std_logic_vector(7 downto 0) := (others => '0');
  signal   keys                 : t_keys;
  
begin

  process begin
    clk <= '0'; wait for clk_per/2;
    clk <= '1'; wait for clk_per/2;
    if simulation_finished then
      wait;
    end if;
  end process;

--------------------------------------------------------------------------------

  ps2_decoder_i : ps2_decoder
  port map(
    CLK        => clk,
    CODE_READY => code_ready,
    PS2_CODE   => ps2_code,
    KEYS       => keys
  );
  
--------------------------------------------------------------------------------

  proc_stim : PROCESS BEGIN
    wait until rising_edge(clk);
    wait for clk_per * 10;
    
    wait for ps2_clk_per;
    
    -- enter
    ps2_code <= c_enter;
    wait for ps2_clk_per;
    code_ready <= '1';
    wait for clk_per;
    code_ready <= '0';
    wait for ps2_clk_per * 10;
    
    -- release enter
    -- F0
    ps2_code <= c_f0;
    wait for ps2_clk_per;
    code_ready <= '1';
    wait for clk_per;
    code_ready <= '0';
    wait for ps2_clk_per * 10;
    
    ps2_code <= c_enter;
    wait for ps2_clk_per;
    code_ready <= '1';
    wait for clk_per;
    code_ready <= '0';
    wait for ps2_clk_per * 10;
    
 --------------------------------------------------------------------------------
    
    --arrow up
    ps2_code <= c_e0;
    wait for ps2_clk_per;
    code_ready <= '1';
    wait for clk_per;
    code_ready <= '0';
    wait for ps2_clk_per * 10;
    
    ps2_code <= c_up;
    wait for ps2_clk_per;
    code_ready <= '1';
    wait for clk_per;
    code_ready <= '0';
    wait for ps2_clk_per * 10;
    
    -- release arrow up
    -- E0
    ps2_code <= c_e0;
    wait for ps2_clk_per;
    code_ready <= '1';
    wait for clk_per;
    code_ready <= '0';
    wait for ps2_clk_per * 10;
    
    -- F0
    ps2_code <= c_f0;
    wait for ps2_clk_per;
    code_ready <= '1';
    wait for clk_per;
    code_ready <= '0';
    wait for ps2_clk_per * 10;
    
    ps2_code <= c_up;
    wait for ps2_clk_per;
    code_ready <= '1';
    wait for clk_per;
    code_ready <= '0';
    wait for ps2_clk_per * 10;
    
 --------------------------------------------------------------------------------
    
    -- hold the button - code repeats
    --arrow down
    ps2_code <= c_e0;
    wait for ps2_clk_per;
    code_ready <= '1';
    wait for clk_per;
    code_ready <= '0';
    wait for ps2_clk_per * 10;
    
    ps2_code <= c_down;
    wait for ps2_clk_per;
    code_ready <= '1';
    wait for clk_per;
    code_ready <= '0';
    wait for ps2_clk_per * 10;
    
     ps2_code <= c_e0;
    wait for ps2_clk_per;
    code_ready <= '1';
    wait for clk_per;
    code_ready <= '0';
    wait for ps2_clk_per * 10;
    
    ps2_code <= c_down;
    wait for ps2_clk_per;
    code_ready <= '1';
    wait for clk_per;
    code_ready <= '0';
    wait for ps2_clk_per * 10;
    
    ps2_code <= c_e0;
    wait for ps2_clk_per;
    code_ready <= '1';
    wait for clk_per;
    code_ready <= '0';
    wait for ps2_clk_per * 10;
    
    ps2_code <= c_down;
    wait for ps2_clk_per;
    code_ready <= '1';
    wait for clk_per;
    code_ready <= '0';
    wait for ps2_clk_per * 10;
    
    ps2_code <= c_e0;
    wait for ps2_clk_per;
    code_ready <= '1';
    wait for clk_per;
    code_ready <= '0';
    wait for ps2_clk_per * 10;
    
    -- F0
    ps2_code <= c_f0;
    wait for ps2_clk_per;
    code_ready <= '1';
    wait for clk_per;
    code_ready <= '0';
    wait for ps2_clk_per * 10;
    
    ps2_code <= c_down;
    wait for ps2_clk_per;
    code_ready <= '1';
    wait for clk_per;
    code_ready <= '0';
    wait for ps2_clk_per * 10;
    
    -- push and hold two buttons in the moment
    -- enter
    ps2_code <= c_enter;
    wait for ps2_clk_per;
    code_ready <= '1';
    wait for clk_per;
    code_ready <= '0';
    wait for ps2_clk_per * 10;
    
    -- arrow down
    ps2_code <= c_e0;
    wait for ps2_clk_per;
    code_ready <= '1';
    wait for clk_per;
    code_ready <= '0';
    wait for ps2_clk_per * 10;
    
    ps2_code <= c_down;
    wait for ps2_clk_per;
    code_ready <= '1';
    wait for clk_per;
    code_ready <= '0';
    wait for ps2_clk_per * 10;
    
    -- release enter
    -- F0
    ps2_code <= c_f0;
    wait for ps2_clk_per;
    code_ready <= '1';
    wait for clk_per;
    code_ready <= '0';
    wait for ps2_clk_per * 10;
    
    ps2_code <= c_enter;
    wait for ps2_clk_per;
    code_ready <= '1';
    wait for clk_per;
    code_ready <= '0';
    wait for ps2_clk_per * 10;
    
    -- release down
    -- E0
    ps2_code <= c_e0;
    wait for ps2_clk_per;
    code_ready <= '1';
    wait for clk_per;
    code_ready <= '0';
    wait for ps2_clk_per * 10;
 
    -- F0
    ps2_code <= c_f0;
    wait for ps2_clk_per;
    code_ready <= '1';
    wait for clk_per;
    code_ready <= '0';
    wait for ps2_clk_per * 10;
    
    ps2_code <= c_down;
    wait for ps2_clk_per;
    code_ready <= '1';
    wait for clk_per;
    code_ready <= '0';
    wait for ps2_clk_per * 10;
    
    simulation_finished <= TRUE;
    WAIT;
  END PROCESS;

end Behavioral;
