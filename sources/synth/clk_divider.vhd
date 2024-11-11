----------------------------------------------------------------------------------
-- clk_divider.vhd
-- Clock divider with configurable division ratio. 
-- Divided clock output is in enable signal format.
-- 06 Oct, 2024
-- Semestral project in the autumn semester of 2024 in MPC-NDO.
-- Artem Gumenyuk (xgumen00@vutbr.cz)
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity clk_divider is
    generic (
        IN_FREQ  : positive;
        OUT_FREQ : positive
    );
    port ( CLK        : in  std_logic;
           RST        : in  STD_LOGIC;
           CLK_DIV_EN : out std_logic
    );
end clk_divider;

architecture Behavioral of clk_divider is

  signal counter  : natural range 0 to ((IN_FREQ/OUT_FREQ) - 1) := 0;

begin

  process(CLK, RST) begin
    if(RST = '1') then
      counter    <= 0;
      CLK_DIV_EN <= '0';
    elsif(rising_edge(CLK)) then
      if(counter = ((IN_FREQ/OUT_FREQ)-1)) then
        counter    <= 0;
        CLK_DIV_EN <= '1';
      else
        counter    <= counter + 1;
        CLK_DIV_EN <= '0';
      end if;
    end if;
  end process;

end Behavioral;
