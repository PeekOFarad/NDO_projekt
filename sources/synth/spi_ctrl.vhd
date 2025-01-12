----------------------------------------------------------------------------------
-- spi_ctrl.vhd
-- Server part SPI controller
-- 10 Nov, 2024
-- Semestral project in the autumn semester of 2024 in MPC-NDO.
-- Artem Gumenyuk (xgumen00@vutbr.cz)
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.all;
use work.server_pkg.all;
use work.common_pkg.all;

entity spi_ctrl is
    Generic (
      g_SLAVE_CNT   : positive;
      g_DATA_WIDTH  : positive;
      g_NODE_WIDTH  : positive
    );
    Port ( CLK      : in STD_LOGIC;
           RST      : in STD_LOGIC;
           EDIT_ENA : in STD_LOGIC;
           -- from PS2
           UPD_DATA : in STD_LOGIC;
           COL      : in STD_LOGIC_VECTOR (2 downto 0);
           ROW      : in STD_LOGIC_VECTOR (5 downto 0);
           NODE     : in STD_LOGIC_VECTOR (g_NODE_WIDTH-1 downto 0);
           NUMBER   : in STD_LOGIC_VECTOR (11 downto 0);
           DATA     : in char_buff_t;
           -- to bus_arbiter
           RW       : out STD_LOGIC;
           COL_OUT  : out STD_LOGIC_VECTOR (2 downto 0);
           ROW_OUT  : out STD_LOGIC_VECTOR (5 downto 0);
           NODE_OUT : out STD_LOGIC_VECTOR (g_NODE_WIDTH-1 downto 0);
           REQ      : out STD_LOGIC;
           ACK      : in STD_LOGIC;
           DIN      : in STD_LOGIC_VECTOR (11 downto 0);
           DOUT     : out STD_LOGIC_VECTOR (11 downto 0);
           -- to spi_master
           BUSY     : in STD_LOGIC;
           RX_DATA  : in STD_LOGIC_VECTOR (g_DATA_WIDTH-1 downto 0);
           SSEL     : out STD_LOGIC_VECTOR (g_SLAVE_CNT-1 downto 0);
           SINGLE   : out STD_LOGIC;
           TXN_ENA  : out STD_LOGIC;
           TX_DATA  : out STD_LOGIC_VECTOR (g_DATA_WIDTH-1 downto 0));
end spi_ctrl;

architecture Behavioral of spi_ctrl is

  type fsm_t IS(idle, wait4data, tx_spi, wait4event, polling, read_from_regs, send_products);

  signal fsm_c : fsm_t;
  signal fsm_s : fsm_t := idle;

  signal data_s : char_buff_t := (others => (others => '0'));

  signal char_idx_c : unsigned(4 downto 0);
  signal char_idx_s : unsigned(4 downto 0) := (others => '0');

  signal ssel_c     : std_logic_vector(g_SLAVE_CNT-1 downto 0);
  signal ssel_s     : std_logic_vector(g_SLAVE_CNT-1 downto 0) := (others => '1');
  signal single_c   : std_logic;
  signal single_s   : std_logic := '0';
  signal txn_ena_c  : std_logic;
  signal txn_ena_s  : std_logic := '0';
  signal tx_frame_c  : std_logic_vector(g_DATA_WIDTH-1 downto 0);
  signal tx_frame_s  : std_logic_vector(g_DATA_WIDTH-1 downto 0) := (others => '0');

  signal tx_data_c  : std_logic_vector(11 downto 0);
  signal tx_par_c   : std_logic;
  
  signal number_s   : std_logic_vector(11 downto 0) := (others => '0');

  -- save column and row
  signal col_s      : std_logic_vector(2 downto 0) := (others => '0');
  signal row_s      : std_logic_vector(5 downto 0) := (others => '0');

begin

-------------------------------------------------------------------------------
-- sample DATA from ui_adapter when valid
process(CLK, RST) begin
  if(RST = '1') then
    data_s <= (others => (others => '0'));
  elsif(rising_edge(CLK)) then
    if(UPD_DATA = '1') then
      col_s    <= COL;
      row_s    <= ROW;
      data_s   <= DATA;
      number_s <= NUMBER;
    end if;
  end if;
end process;

-------------------------------------------------------------------------------

process(CLK, RST) begin
  if(RST = '1') then
    fsm_s      <= idle;
    char_idx_s <= (others => '0');
    ssel_s     <= (others => '1');
    single_s   <= '0';
    txn_ena_s  <= '0';
    tx_frame_s <= (others => '0');
  elsif(rising_edge(CLK)) then
    fsm_s      <= fsm_c;
    char_idx_s <= char_idx_c;
    ssel_s     <= ssel_c;
    single_s   <= single_c;
    txn_ena_s  <= txn_ena_c;
    tx_frame_s <= tx_frame_c;
  end if;
end process;

-------------------------------------------------------------------------------

process(fsm_s, EDIT_ENA, BUSY, UPD_DATA, char_idx_s, COL, ROW, NODE, data_s,
        txn_ena_s, tx_frame_s, tx_data_c, tx_par_c, single_s) begin
  fsm_c      <= fsm_s;
  char_idx_c <= char_idx_s;
  ssel_c     <= (others => '1');
  single_c   <= single_s;
  txn_ena_c  <= '0';
  tx_frame_c  <= tx_frame_s;

  case(fsm_s) is
    when idle =>
      if(EDIT_ENA = '1') then
        fsm_c <= wait4data;
      else
        fsm_c <= wait4event;
      end if;
    ---------------------------------------------------------------------------
    when wait4data =>
      if(EDIT_ENA = '0') then
        fsm_c <= wait4event;
      elsif(UPD_DATA = '1' and not(COL = "001" and (TO_INTEGER(unsigned(NODE)) = 0))) then
        if(COL /= col_s or ROW /= row_s) then
          char_idx_c <= (others => '0');
        end if;
        fsm_c      <= tx_spi;
      end if;
    ---------------------------------------------------------------------------
    when tx_spi =>
      if(BUSY = '0') then -- if SPI is not busy
        if(COL = "001") then -- send amount to selected client
          ssel_c <= (others => '1');
          ssel_c(TO_INTEGER(unsigned(NODE) - 1)) <= '0';
          single_c  <= '1';
        else -- send dishes names and prices to all slaves in one time
          ssel_c    <= (others => '0');
          single_c  <= '0';
        end if;

        tx_frame_c <= tx_par_c & tx_data_c & ROW & COL & '0'; -- 1b'rw, 9b'addr, 12b'data, 1b'parity
        txn_ena_c <= '1';
        fsm_c <= wait4data;
        if(data_s(0) /= x"00") then
          char_idx_c <= char_idx_s + 1;
        end if;
      end if;
    ---------------------------------------------------------------------------
    when others => fsm_c <= idle;
  end case;
end process;

-- calculate TX
process(COL, data_s, char_idx_s, number_s) begin
  if(COL = "000") then
    tx_data_c <= "0000" & data_s(TO_INTEGER(char_idx_s));
  else
    tx_data_c <= number_s;
  end if;
end process;
tx_par_c  <= not ('0' xor COL(0) xor COL(1) xor COL(2) xor ROW(0) xor
                          ROW(1) xor ROW(2) xor ROW(3) xor ROW(4) xor ROW(5) xor
                          tx_data_c(0) xor tx_data_c(1) xor tx_data_c(2) xor tx_data_c(3) xor
                          tx_data_c(4) xor tx_data_c(5) xor tx_data_c(6) xor tx_data_c(7) xor
                          tx_data_c(8) xor tx_data_c(9) xor tx_data_c(10) xor tx_data_c(11));

-- output assignments
SSEL    <= ssel_s;
SINGLE  <= single_s;
TXN_ENA <= txn_ena_s;
TX_DATA <= tx_frame_s;

end Behavioral;
