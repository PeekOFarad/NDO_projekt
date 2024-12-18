----------------------------------------------------------------------------------
-- spi_master.vhd
-- Server part SPI master controller
-- 9 Nov, 2024
-- Semestral project in the autumn semester of 2024 in MPC-NDO.
-- Artem Gumenyuk (xgumen00@vutbr.cz)
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity spi_master is
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
end spi_master;

architecture Behavioral of spi_master is
  type fsm_t IS(idle, run);

  signal fsm_c : fsm_t;
  signal fsm_s : fsm_t := idle;

  signal sclk_cnt_c : unsigned(5 downto 0);
  signal sclk_cnt_s : unsigned(5 downto 0) := (others => '0');

  signal rx_buff_c : std_logic_vector(g_DATA_WIDTH-1 downto 0);
  signal rx_buff_s : std_logic_vector(g_DATA_WIDTH-1 downto 0) := (others => '0');

  signal tx_buff_c : std_logic_vector(g_DATA_WIDTH-1 downto 0);
  signal tx_buff_s : std_logic_vector(g_DATA_WIDTH-1 downto 0) := (others => '0');

  signal sclk_c : std_logic;
  signal sclk_s : std_logic := '0';
  signal mosi_c : std_logic;
  signal mosi_s : std_logic := '0';
  signal busy_c : std_logic;
  signal busy_s : std_logic := '0';
  signal s_sel_c : std_logic_vector (g_SLAVE_CNT-1 downto 0);
  signal s_sel_s : std_logic_vector (g_SLAVE_CNT-1 downto 0) := (others => '1');
  signal single_c : std_logic;
  signal single_s : std_logic := '0';

begin

  process(CLK, RST) begin
    if(RST = '1') then
      fsm_s      <= idle;
      sclk_cnt_s <= (others => '0');
      rx_buff_s  <= (others => '0');
      tx_buff_s  <= (others => '0');
      sclk_s     <= '0';
      mosi_s     <= '0';
      busy_s     <= '0';
      s_sel_s    <= (others => '1');
      single_s   <= '0';
    elsif(rising_edge(CLK)) then
      fsm_s      <= fsm_c;
      sclk_cnt_s <= sclk_cnt_c;
      rx_buff_s  <= rx_buff_c;
      tx_buff_s  <= tx_buff_c;
      sclk_s     <= sclk_c;
      mosi_s     <= mosi_c;
      busy_s     <= busy_c;
      s_sel_s    <= s_sel_c;
      single_s   <= single_c;
    end if;
  end process;

  process(TXN_ENA, MISO, SSEL, TX_DATA, SINGLE, fsm_s, sclk_cnt_s,
          rx_buff_s, tx_buff_s, sclk_s, mosi_s, busy_s, s_sel_s, single_s) begin
    fsm_c      <= fsm_s;
    sclk_cnt_c <= sclk_cnt_s;
    rx_buff_c  <= rx_buff_s;
    tx_buff_c  <= tx_buff_s;
    sclk_c     <= sclk_s;
    mosi_c     <= mosi_s;
    busy_c     <= busy_s;
    s_sel_c    <= s_sel_s;
    single_c   <= single_s;
    
    case(fsm_s) is
      when idle =>
        busy_c <= '0';
        mosi_c <= 'Z';
        sclk_c <= '0';

        if(TXN_ENA = '1') then
          busy_c     <= '1';
          s_sel_c    <= SSEL;
          single_c   <= SINGLE;
          tx_buff_c  <= TX_DATA;
          sclk_cnt_c <= (others => '0');
          fsm_c      <= run;
        end if;
      when run =>
        sclk_cnt_c <= sclk_cnt_s + 1;
        sclk_c <= not sclk_s;

        if(sclk_cnt_s(0) = '0') then -- TX
          mosi_c <= tx_buff_s(0);
          tx_buff_c <= '0' & tx_buff_s(g_DATA_WIDTH-1 downto 1);
        else -- RX
          if(single_s = '1') then
            rx_buff_c <= MISO & rx_buff_s(g_DATA_WIDTH-1 downto 1);
          end if;
        end if;

        if(sclk_cnt_s = ((2 * g_DATA_WIDTH))) then
          busy_c   <= '0';
          sclk_c   <= '0';
          s_sel_c  <= (others => '1');
          mosi_c   <= 'Z';
          fsm_c    <= idle;
        end if;
    end case;
  end process;

  SS_N    <= s_sel_s;
  SCLK    <= sclk_s;
  MOSI    <= mosi_s;
  BUSY    <= busy_s;
  RX_DATA <= rx_buff_s;

end Behavioral;
