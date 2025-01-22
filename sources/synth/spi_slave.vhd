----------------------------------------------------------------------------------
-- spi_slave.vhd
-- Client part SPI slave controller
-- 25 Nov, 2024
-- Semestral project in the autumn semester of 2024 in MPC-NDO.
-- Artem Gumenyuk (xgumen00@vutbr.cz)
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity spi_slave is
    Generic (
           g_DATA_WIDTH  : positive
    );
    Port ( CLK      : in STD_LOGIC;
           RST      : in STD_LOGIC;
           MOSI     : in STD_LOGIC;
           SCSB     : in STD_LOGIC;
           SCLK     : in STD_LOGIC;
           TX_DATA  : in STD_LOGIC_VECTOR (g_DATA_WIDTH-1 downto 0);
           MISO     : out STD_LOGIC;
           BUSY     : out STD_LOGIC;
           DATA_RDY : out STD_LOGIC;
           RX_DATA  : out STD_LOGIC_VECTOR (g_DATA_WIDTH-1 downto 0);
           -- DEBUG IF
           SCSB_FE_DBG  : out STD_LOGIC;
           SCSB_RE_DBG  : out STD_LOGIC
         );
end spi_slave;

architecture Behavioral of spi_slave is
  type fsm_t IS(idle, run);

  signal fsm_c : fsm_t;
  signal fsm_s : fsm_t := idle;

  signal scsb_s : std_logic := '1';
  signal sclk_s : std_logic := '0';
  signal mosi_s : std_logic := '0';

  signal scsb_re : std_logic;
  signal scsb_fe : std_logic;
  signal sclk_re : std_logic;
  signal sclk_fe : std_logic;

  signal rx_buff_c : std_logic_vector(g_DATA_WIDTH-1 downto 0);
  signal rx_buff_s : std_logic_vector(g_DATA_WIDTH-1 downto 0) := (others => '0');

  signal tx_buff_c : std_logic_vector(g_DATA_WIDTH-1 downto 0);
  signal tx_buff_s : std_logic_vector(g_DATA_WIDTH-1 downto 0) := (others => '0');

  signal miso_c : std_logic;
  signal miso_s : std_logic := '0';
  signal busy_c : std_logic;
  signal busy_s : std_logic := '0';
  signal data_rdy_c  : std_logic;
  signal data_rdy_s  : std_logic := '0';
  signal parity_c    : std_logic;
  signal parity_calc : std_logic_vector(g_DATA_WIDTH-2 downto 0);
  signal data_cnt_c  : unsigned(5 downto 0);
  signal data_cnt_s  : unsigned(5 downto 0) := (others => '0');

  -- re-synchronization
  signal scsb_sync_s : std_logic_vector(1 downto 0) := (others => '1');
  signal sclk_sync_s : std_logic_vector(1 downto 0) := (others => '0');
  signal mosi_sync_s : std_logic_vector(1 downto 0) := (others => '0');

begin

  process(CLK, RST) begin
    if(RST = '1') then
      fsm_s       <= idle;
      rx_buff_s   <= (others => '0');
      tx_buff_s   <= (others => '0');
      miso_s      <= '0';
      sclk_s      <= '0';
      scsb_s      <= '1';
      mosi_s      <= '0';
      busy_s      <= '0';
      data_rdy_s  <= '0';
      data_cnt_s  <= (others => '0');
      scsb_sync_s <= (others => '1');
      sclk_sync_s <= (others => '0');
      mosi_sync_s <= (others => '0');
    elsif(rising_edge(CLK)) then
      fsm_s      <= fsm_c;
      rx_buff_s  <= rx_buff_c;
      tx_buff_s  <= tx_buff_c;
      miso_s     <= miso_c;
      busy_s     <= busy_c;
      data_rdy_s <= data_rdy_c;
      data_cnt_s <= data_cnt_c;
      -- SCSB
      scsb_sync_s(0) <= SCSB;
      scsb_sync_s(1) <= scsb_sync_s(0);
      scsb_s         <= scsb_sync_s(1);
      -- SCLK
      sclk_sync_s(0) <= SCLK;
      sclk_sync_s(1) <= sclk_sync_s(0);
      sclk_s         <= sclk_sync_s(1);
      -- MOSI
      mosi_sync_s(0) <= MOSI;
      mosi_sync_s(1) <= mosi_sync_s(0);
      mosi_s         <= mosi_sync_s(1);
    end if;
  end process;

  process(fsm_s, scsb_re, scsb_fe, sclk_re, sclk_fe, TX_DATA, tx_buff_s,
          rx_buff_s, busy_s, data_rdy_s, data_cnt_s, miso_s, mosi_s, parity_c) begin
    fsm_c      <= fsm_s;
    rx_buff_c  <= rx_buff_s;
    tx_buff_c  <= tx_buff_s;
    busy_c     <= busy_s;
    data_rdy_c <= data_rdy_s;
    data_cnt_c <= data_cnt_s;
    miso_c     <= miso_s;

    case(fsm_s) is
      when idle =>
        miso_c     <= 'Z';
        busy_c     <= '0';
        data_rdy_c <= '0';
        data_cnt_c <= (others => '0');

        if(scsb_fe = '1') then
          fsm_c     <= run;
          busy_c    <= '1';
          tx_buff_c <= TX_DATA;
        end if;
      when run =>
        if(scsb_re = '1') then
          fsm_c  <= idle;
          if((data_cnt_s = g_DATA_WIDTH) and (rx_buff_s(g_DATA_WIDTH-1) = parity_c)) then -- length and parity check
            data_rdy_c <= '1';
          end if;
        elsif(sclk_re = '1') then
          miso_c <= tx_buff_s(0);
          tx_buff_c <= '0' & tx_buff_s(tx_buff_s'left downto 1);
        elsif(sclk_fe = '1') then
          rx_buff_c <= mosi_s & rx_buff_s(g_DATA_WIDTH-1 downto 1);
          data_cnt_c <= data_cnt_s + 1;
        end if;
    end case;
  end process;

  -- SCSB edge detector
  scsb_re <= '1' when (scsb_sync_s(1) = '1' and scsb_s = '0') else '0';
  scsb_fe <= '1' when (scsb_sync_s(1) = '0' and scsb_s = '1') else '0';

  -- SCLK edge detector
  sclk_re <= '1' when (sclk_sync_s(1) = '1' and sclk_s = '0') else '0';
  sclk_fe <= '1' when (sclk_sync_s(1) = '0' and sclk_s = '1') else '0';

  -- parity calulation
  parity_calc(0) <= '1'; --set first result to odd
  parity_logic: FOR i IN 0 to g_DATA_WIDTH-3 GENERATE
    parity_calc(i+1) <= parity_calc(i) XOR rx_buff_s(i+1);  --XOR each result with the next input bit
  END GENERATE;

  parity_c <= parity_calc(g_DATA_WIDTH-2);

  MISO     <= miso_s;
  BUSY     <= busy_s;
  DATA_RDY <= data_rdy_s;
  RX_DATA  <= rx_buff_s;

  SCSB_FE_DBG   <= scsb_fe;
  SCSB_RE_DBG   <= scsb_re;

end Behavioral;