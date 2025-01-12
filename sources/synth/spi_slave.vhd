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
           RX_DATA  : out STD_LOGIC_VECTOR (g_DATA_WIDTH-1 downto 0));
end spi_slave;

architecture Behavioral of spi_slave is
  type fsm_t IS(idle, run);

  signal fsm_c : fsm_t;
  signal fsm_s : fsm_t := idle;

  signal scsb_s : std_logic := '0';
  signal sclk_s : std_logic := '0';

  signal scsb_re : std_logic;
  signal scsb_fe : std_logic;
  signal sclk_re : std_logic;
  signal sclk_fe : std_logic;

  signal rx_buff_c : std_logic_vector(g_DATA_WIDTH-1 downto 0);
  signal rx_buff_s : std_logic_vector(g_DATA_WIDTH-1 downto 0) := (others => '0');

  signal tx_buff_c : std_logic_vector(g_DATA_WIDTH-2 downto 0);
  signal tx_buff_s : std_logic_vector(g_DATA_WIDTH-2 downto 0) := (others => '0');

  signal miso_c : std_logic;
  signal miso_s : std_logic;
  signal busy_c : std_logic;
  signal busy_s : std_logic := '0';
  signal data_rdy_c  : std_logic;
  signal data_rdy_s  : std_logic := '0';
  signal parity_c    : std_logic;
  signal parity_calc : std_logic_vector(g_DATA_WIDTH-1 downto 0);
  signal data_cnt_c  : unsigned(5 downto 0);
  signal data_cnt_s  : unsigned(5 downto 0) := (others => '0');

begin

  process(CLK, RST) begin
    if(RST = '1') then
      fsm_s      <= idle;
      rx_buff_s  <= (others => '0');
      tx_buff_s  <= (others => '0');
      miso_s     <= '0';
      sclk_s     <= '0';
      scsb_s     <= '0';
      busy_s     <= '0';
      data_rdy_s <= '0';
      data_cnt_s <= (others => '0');
    elsif(rising_edge(CLK)) then
      fsm_s      <= fsm_c;
      rx_buff_s  <= rx_buff_c;
      tx_buff_s  <= tx_buff_c;
      miso_s     <= miso_c;
      sclk_s     <= SCLK;
      scsb_s     <= SCSB;
      busy_s     <= busy_c;
      data_rdy_s <= data_rdy_c;
      data_cnt_s <= data_cnt_c;
    end if;
  end process;

  -- process(RST, SCLK) begin
  --   if(RST = '1') then
  --     miso_s <= '0';
  --   elsif(rising_edge(SCLK)) then
  --     miso_s <= miso_c;
      
  --   end if;
  -- end process;
  -- process(SCLK, shift_ena) begin
  --   if(rising_edge(SCLK)) then
  --     if(shift_ena = '0') then
  --       o_miso                 <= i_data_parallel(N-1);
  --       r_tx_data              <= i_data_parallel(N-2 downto 0);
  --     else
  --       o_miso                 <= r_tx_data(N-2);
  --       r_tx_data              <= r_tx_data(N-3 downto 0)&'0';
  --     end if;
  --   end if;
  -- end process;

  process(fsm_s, scsb_re, scsb_fe, sclk_re, sclk_fe, TX_DATA, tx_buff_s,
          rx_buff_s, busy_s, data_rdy_s, data_cnt_s, miso_s, MOSI, parity_c) begin
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
          miso_c    <= TX_DATA(0);
          busy_c    <= '1';
          tx_buff_c <= TX_DATA(g_DATA_WIDTH-1 downto 1);
        end if;
      when run =>
        if(scsb_re = '1') then
          fsm_c  <= idle;
          if((data_cnt_s = g_DATA_WIDTH) and (rx_buff_s(0) = parity_c)) then -- length and parity check
            data_rdy_c <= '1';
          end if;
        -- elsif(sclk_re = '1') then
        --   miso_c <= tx_buff_s(0);
        --   tx_buff_c <= '0' & tx_buff_s(tx_buff_s'left downto 1);
        elsif(sclk_fe = '1') then
          miso_c <= tx_buff_s(0);
          tx_buff_c <= '0' & tx_buff_s(tx_buff_s'left downto 1);

          rx_buff_c <= MOSI & rx_buff_s(g_DATA_WIDTH-1 downto 1);
          data_cnt_c <= data_cnt_s + 1;
        end if;
    end case;
  end process;

  -- SCSB edge detector
  scsb_re <= SCSB and not scsb_s;
  scsb_fe <= not SCSB and scsb_s;

  -- SCLK edge detector
  sclk_re <= SCLK and not sclk_s;
  sclk_fe <= not SCLK and sclk_s;

  -- parity calulation
  parity_calc(0) <= '1'; --set first result to odd
  parity_logic: FOR i IN 0 to g_DATA_WIDTH-2 GENERATE
    parity_calc(i+1) <= parity_calc(i) XOR rx_buff_s(i+1);  --XOR each result with the next input bit
  END GENERATE;

  parity_c <= parity_calc(g_DATA_WIDTH-1);

  MISO     <= miso_s;
  BUSY     <= busy_s;
  DATA_RDY <= data_rdy_s;
  RX_DATA  <= rx_buff_s;

end Behavioral;