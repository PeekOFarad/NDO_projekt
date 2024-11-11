----------------------------------------------------------------------------------
-- fall_edge_detector.vhd
-- Input signal falling edge detector.
-- Output signal is high 1 clock cycle after falling edge of input signal.
-- 06 Oct, 2024
-- Semestral project in the autumn semester of 2024 in MPC-NDO.
-- Artem Gumenyuk (xgumen00@vutbr.cz)
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity fall_edge_detector is
    Port ( CLK       : in  std_logic;
           RST       : in  STD_LOGIC;
           INP_SIG   : in  std_logic;
           FALL_EDGE : out std_logic
    );
end fall_edge_detector;

architecture Behavioral of fall_edge_detector is

  signal q : std_logic_vector (1 downto 0) := (others => '0');

begin
    
  process(CLK, RST) begin
    if(RST = '1') then
      q <= (others => '0');
    elsif(rising_edge(CLK)) then
      q(0) <= INP_SIG;
      q(1) <= q(0);
    end if;
  end process;
  
  FALL_EDGE <= not q(0) and q(1);

end Behavioral;
