----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/08/2024 10:31:12 PM
-- Design Name: 
-- Module Name: sram_ctrl_TB - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity sram_ctrl_TB is
--  Port ( );
end sram_ctrl_TB;

architecture Behavioral of sram_ctrl_TB is
  
  component sram_ctrl is
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
  end component;
 
--------------------------------------------------------------------------------

  constant clk_per              : time := 1 ns; 
  constant ps2_clk_per          : time := 1000 ns;
  signal   simulation_finished  : BOOLEAN := FALSE;

  signal   clk                  : std_logic := '0';
  signal   rst                  : std_logic := '0';
  signal   rw                   : std_logic := '0';
  signal   wbe_n                : std_logic_vector(1 downto 0)  := (others => '0');
  signal   addr                 : std_logic_vector(17 downto 0) := (others => '0');
  signal   wdata                : std_logic_vector(15 downto 0) := (others => '0');
  signal   rdata                : std_logic_vector(15 downto 0);
  signal   saddr                : std_logic_vector(17 downto 0);
  signal   we_n                 : std_logic := '0';
  signal   oe_n                 : std_logic := '0';
  signal   ce_n                 : std_logic := '0';
  signal   swbe_n               : std_logic_vector(1 downto 0);
  signal   io_sdata             : std_logic_vector(15 downto 0);
  
begin

  process begin
    clk <= '0'; wait for clk_per/2;
    clk <= '1'; wait for clk_per/2;
    if simulation_finished then
      wait;
    end if;
  end process;

--------------------------------------------------------------------------------

  sram_ctrl_i : sram_ctrl
  port map(
    CLK      => clk,
    RST      => rst,
    RW       => rw,
    WBE_N    => wbe_n,
    ADDR     => addr,
    WDATA    => wdata,
    RDATA    => rdata,
    SADDR    => saddr,
    WE_N     => we_n,
    OE_N     => oe_n,
    CE_N     => ce_n,
    SWBE_N   => swbe_n,
    IO_SDATA => io_sdata
  );
  
--------------------------------------------------------------------------------

  proc_stim : PROCESS BEGIN
    wait until rising_edge(clk);
    wait for clk_per * 10;
    
    -- write
    rw    <= '0';
    wbe_n <= "01";
    addr  <= "100000000000001101";
    wdata <= X"10AB";
    
    wait for clk_per * 2;
    -- read
    rw    <= '1';
    wbe_n <= "11";
    addr  <= "100000000000001110";
    wdata <= X"10AB";
    
    wait for clk_per * 2;
    
    simulation_finished <= TRUE;
    WAIT;
  END PROCESS;

end Behavioral;
