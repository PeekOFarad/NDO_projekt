----------------------------------------------------------------------------------
-- sram_ctrl.vhd
-- 256Kx16 SRAM controller.
-- 08 Oct, 2024
-- Semestral project in the autumn semester of 2024 in MPC-NDO.
-- Artem Gumenyuk (xgumen00@vutbr.cz)
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity sram_ctrl is
    Port ( CLK      : in    STD_LOGIC;
           RST      : in    STD_LOGIC;
           RW       : in    STD_LOGIC;
           WBE_N    : in    STD_LOGIC_VECTOR (1 downto 0);
           ADDR     : in    STD_LOGIC_VECTOR (17 downto 0);
           WDATA    : in    STD_LOGIC_VECTOR (15 downto 0);
           RDATA    : out   STD_LOGIC_VECTOR (15 downto 0);
           SADDR    : out   STD_LOGIC_VECTOR (17 downto 0);
           WE_N     : out   STD_LOGIC;
           OE_N     : out   STD_LOGIC;
           CE_N     : out   STD_LOGIC;
           SWBE_N   : out   STD_LOGIC_VECTOR (1 downto 0);
           IO_SDATA : inout STD_LOGIC_VECTOR (15 downto 0));
end sram_ctrl;

architecture Behavioral of sram_ctrl is

begin

  process(clk, RST) begin
    if(RST = '1') then
      RDATA    <= (others => '0');
    elsif(rising_edge(CLK)) then
      if(RW = '1') then
        RDATA <= IO_SDATA;
      end if;
    end if;
  end process;
  
  process(RW) begin
    IO_SDATA <= (others => 'Z');
    if(RW = '0') then
      IO_SDATA <= WDATA;
    end if;
  end process;
  
  SADDR  <= ADDR;
  WE_N   <= RW;
  OE_N   <= '0';
  CE_N   <= '0';
  SWBE_N <= WBE_N;
  
end Behavioral;
