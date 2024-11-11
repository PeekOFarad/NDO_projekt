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
use work.server_pkg.all;

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
           DATA     : in sprit_buff_t;
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

  signal data_s : sprit_buff_t := (others => (others => '0'));

  signal char_idx_c : unsigned(4 downto 0);
  signal char_idx_s : unsigned(4 downto 0) := (others => '0');

  signal is_empty_c : std_logic;

  signal ssel_c     : std_logic_vector(g_SLAVE_CNT-1 downto 0);
  signal ssel_s     : std_logic_vector(g_SLAVE_CNT-1 downto 0) := (others => '1');
  signal single_c   : std_logic;
  signal single_s   : std_logic := '0';
  signal txn_ena_c  : std_logic;
  signal txn_ena_s  : std_logic := '0';
  signal tx_frame_c  : std_logic_vector(g_DATA_WIDTH-1 downto 0);
  signal tx_frame_s  : std_logic_vector(g_DATA_WIDTH-1 downto 0) := (others => '0');

  signal tx_addr_c  : std_logic_vector(7 downto 0);
  signal tx_data_c  : std_logic_vector(11 downto 0);
  signal tx_par_c   : std_logic;
  
  signal busy_s     : std_logic := '0';

begin

-------------------------------------------------------------------------------
-- sample DATA from ui_adapter when valid
process(CLK, RST) begin
  if(RST = '1') then
    data_s <= (others => (others => '0'));
  elsif(rising_edge(CLK)) then
    if(UPD_DATA = '1') then
      data_s <= DATA;
    end if;
  end if;
end process;

-------------------------------------------------------------------------------
-- set is_empty_c if data_s(31 downto char_idx_s) are all zero bytes
process(char_idx_s, data_s) begin
  is_empty_c <= '1';

  for i in to_integer(char_idx_s) to 31 loop
    if(data_s(i) /= "00000000") then
      is_empty_c <= '0';
    end if;
  end loop;
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
    busy_s     <= '0';
  elsif(rising_edge(CLK)) then
    fsm_s      <= fsm_c;
    char_idx_s <= char_idx_c;
    ssel_s     <= ssel_c;
    single_s   <= single_c;
    txn_ena_s  <= txn_ena_c;
    tx_frame_s <= tx_frame_c;
    busy_s     <= BUSY;
  end if;
end process;

-------------------------------------------------------------------------------

process(fsm_s, EDIT_ENA, BUSY, UPD_DATA, char_idx_s, is_empty_c, COL, NODE, data_s,
        txn_ena_s, tx_frame_s, tx_addr_c, tx_data_c, tx_par_c, ssel_s, single_s, busy_s) begin
  fsm_c      <= fsm_s;
  char_idx_c <= char_idx_s;
  ssel_c     <= ssel_s;
  single_c   <= single_s;
  txn_ena_c  <= txn_ena_s;
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
      elsif(UPD_DATA = '1' and (COL = "000" or (TO_INTEGER(unsigned(NODE)) /= 0))) then
        char_idx_c <= (others => '0');
        fsm_c      <= tx_spi;
      end if;
    ---------------------------------------------------------------------------
    when tx_spi =>
      if(is_empty_c = '0') then
        if(BUSY = '0') then -- send SPI frame
          if(COL = "000") then -- send dishes names to all slaves in one time
            ssel_c    <= (others => '0');
            single_c  <= '0';
          else
            ssel_c <= (others => '1');
            ssel_c(TO_INTEGER(unsigned(NODE) - 1)) <= '0';
            single_c  <= '1';
          end if;
          tx_frame_c <= tx_par_c & tx_data_c & tx_addr_c & '0'; -- 1b'rw, 8b'addr, 12b'data, 1b'parity
          txn_ena_c <= '1';
        elsif(BUSY = '1' and busy_s = '0') then -- wait for SPI frame done
          char_idx_c <= char_idx_s + 1;
          txn_ena_c <= '0';
        end if;
      elsif(BUSY = '0') then -- turn back when last byte has been transmitted
        fsm_c <= wait4data;
      end if;
    ---------------------------------------------------------------------------
    when others => fsm_c <= idle;
  end case;
end process;

-- calculate TX address
tx_addr_c <= std_logic_vector((5 * unsigned(ROW)) + unsigned(COL));
tx_data_c <= "0000" & data_s(TO_INTEGER(char_idx_s));
tx_par_c  <= not ('0' xor tx_addr_c(0) xor tx_addr_c(1) xor tx_addr_c(2) xor tx_addr_c(3) xor
                          tx_addr_c(4) xor tx_addr_c(5) xor tx_addr_c(6) xor tx_addr_c(7) xor
                          tx_data_c(0) xor tx_data_c(1) xor tx_data_c(2) xor tx_data_c(3) xor
                          tx_data_c(4) xor tx_data_c(5) xor tx_data_c(6) xor tx_data_c(7) xor
                          tx_data_c(8) xor tx_data_c(9) xor tx_data_c(10) xor tx_data_c(11));

-- output assignments
SSEL    <= ssel_s;
SINGLE  <= single_s;
TXN_ENA <= txn_ena_s;
TX_DATA <= tx_frame_s;

end Behavioral;
