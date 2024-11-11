----------------------------------------------------------------------------------
-- spi_master_TB.vhd
-- Server part SPI master controller TB
-- 9 Nov, 2024
-- Semestral project in the autumn semester of 2024 in MPC-NDO.
-- Artem Gumenyuk (xgumen00@vutbr.cz)
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.server_pkg.all;

entity spi_master_TB is
end spi_master_TB;

architecture Behavioral of spi_master_TB is

  component spi_master is
    Generic (
           g_SLAVE_CNT   : positive;
           g_DATA_WIDTH  : positive
    );
    Port ( CLK     : in STD_LOGIC;
           RST     : in STD_LOGIC;
           TXN_ENA : in STD_LOGIC;
           MISO    : in STD_LOGIC;
           SINGLE  : in STD_LOGIC; -- 1 - send frame to single slave, 0 - send frames to multiple slaves (ignore MISO)
           SSEL    : in STD_LOGIC_VECTOR (g_SLAVE_CNT-1 downto 0);
           TX_DATA : in STD_LOGIC_VECTOR (g_DATA_WIDTH-1 downto 0);
           SCLK    : out STD_LOGIC;
           MOSI    : out STD_LOGIC;
           BUSY    : out STD_LOGIC;
           SS_N    : out STD_LOGIC_VECTOR (g_SLAVE_CNT-1 downto 0);
           RX_DATA : out STD_LOGIC_VECTOR (g_DATA_WIDTH-1 downto 0));
  end component;

--------------------------------------------------------------------------------

  constant clk_per              : time := 20 ns;
  signal   simulation_finished  : BOOLEAN := FALSE;

  signal   clk              : std_logic := '0';
  signal   rst              : std_logic := '0';

  signal   txn_ena          : std_logic := '0';
  signal   miso             : std_logic := 'Z';
  signal   single           : std_logic := '0';
  signal   ssel             : std_logic_vector(c_CLIENTS_CNT-1 downto 0) := (others => '1');
  signal   tx_data          : std_logic_vector(c_SPI_WIDTH-1 downto 0) := (others => '0');

  signal   sclk             : std_logic;
  signal   mosi             : std_logic;
  signal   busy             : std_logic;
  signal   ss_n             : std_logic_vector(c_CLIENTS_CNT-1 downto 0);
  signal   rx_data          : std_logic_vector(c_SPI_WIDTH-1 downto 0);

  -- data to drive from slave
  signal   slave_data       : std_logic_vector(c_SPI_WIDTH-1 downto 0) := (others => '0');

  -- parts of mosi frame
  signal   rw            : std_logic;
  signal   parity        : std_logic;
  signal   addr          : std_logic_vector(7 downto 0);
  signal   data          : std_logic_vector(11 downto 0);

begin

  process begin
    clk <= '0'; wait for clk_per/2;
    clk <= '1'; wait for clk_per/2;
    if simulation_finished then
      wait;
    end if;
  end process;

--------------------------------------------------------------------------------
-- Slave model
  process begin
    wait until ss_n'event and (ss_n /= "11");

    for i in 0 to 21 loop
      wait until rising_edge(sclk);
      miso <= slave_data(i);
    end loop;

    wait until ss_n'event and (ss_n = "11");
    miso <= 'Z';
  end process;

--------------------------------------------------------------------------------

spi_master_i : spi_master
generic map(
  g_SLAVE_CNT  => c_CLIENTS_CNT,
  g_DATA_WIDTH => c_SPI_WIDTH
)
port map(
  CLK      => clk,
  RST      => rst,
  TXN_ENA  => txn_ena,
  MISO     => miso,
  SINGLE   => single,
  SSEL     => ssel,
  TX_DATA  => tx_data,
  SCLK     => sclk,
  MOSI     => mosi,
  BUSY     => busy,
  SS_N     => ss_n,
  RX_DATA  => rx_data
);

--------------------------------------------------------------------------------

parity <= not (rw xor addr(0) xor addr(1) xor addr(2) xor addr(3) xor addr(4) xor addr(5) xor addr(6) xor addr(7) xor data(0) xor data(1) xor data(2) xor data(3) xor data(4) xor data(5) xor data(6) xor data(7) xor data(8) xor data(9) xor data(10) xor data(11));

proc_stim : PROCESS BEGIN
    wait until rising_edge(clk);
    wait for clk_per * 10;

    -- single frame
    single     <= '1';
    slave_data <= "1101011101000101101001";
    ssel       <= "01";
    rw         <= '1';
    addr       <= STD_LOGIC_VECTOR(TO_UNSIGNED(6, 8)); -- amount second row
    data       <= STD_LOGIC_VECTOR(TO_UNSIGNED(76, 12));
    wait for clk_per;
    tx_data    <= rw & addr & data & parity;
    txn_ena    <= '1';
    wait for clk_per;
    txn_ena    <= '0';

    wait for clk_per * 100;
    
    -- multiple frame
    single     <= '0';
    slave_data <= "1101011101000101101001";
    ssel       <= "00";
    rw         <= '1';
    addr       <= STD_LOGIC_VECTOR(TO_UNSIGNED(6, 8)); -- amount second row
    data       <= STD_LOGIC_VECTOR(TO_UNSIGNED(76, 12));
    wait for clk_per;
    tx_data    <= rw & addr & data & parity;
    txn_ena    <= '1';
    wait for clk_per;
    txn_ena    <= '0';

    wait for clk_per * 100;

    simulation_finished <= TRUE;
    WAIT;
END PROCESS;

end Behavioral;
