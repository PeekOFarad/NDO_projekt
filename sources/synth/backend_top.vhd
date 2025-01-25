----------------------------------------------------------------------------------
-- backend_top.vhd
-- Server part backend top module
-- 3 Nov, 2024
-- Semestral project in the autumn semester of 2024 in MPC-NDO.
-- Artem Gumenyuk (xgumen00@vutbr.cz)
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.ps2_pkg.all;
use work.server_pkg.all;
use work.common_pkg.all;

entity backend_top is
    Generic (
           g_SLAVE_CNT : positive := c_CLIENTS_CNT
    );
    Port ( CLK      : in STD_LOGIC;
           RST      : in STD_LOGIC;
           PS2_CLK  : in STD_LOGIC;
           PS2_DATA : in STD_LOGIC;
           MISO     : in STD_LOGIC_VECTOR (g_SLAVE_CNT-1 downto 0);
           VGA_RDY  : in STD_LOGIC;
           UPD_ARR  : out STD_LOGIC;
           UPD_DATA : out STD_LOGIC;
           SCLK     : out STD_LOGIC;
           MOSI     : out STD_LOGIC;
           SS_N     : out STD_LOGIC_VECTOR (g_SLAVE_CNT-1 downto 0);
           COL      : out STD_LOGIC_VECTOR (2 downto 0);
           ROW      : out STD_LOGIC_VECTOR (5 downto 0);
           DATA_OUT : out char_buff_t);
end backend_top;

architecture Behavioral of backend_top is

  component ps2_top is
      Port (  CLK      : in STD_LOGIC;
              RST      : in STD_LOGIC;
              PS2_CLK  : in STD_LOGIC;
              PS2_DATA : in STD_LOGIC;
              NUMBER   : out STD_LOGIC_VECTOR(3 downto 0);
              PS2_CODE : out STD_LOGIC_VECTOR (7 downto 0);
              KEYS     : out t_keys);
    end component;
  
----------------------------------------------------------------------------------
  
  component ps2_if_ctrl is
    Generic (
           g_FOOD_CNT     : positive;
           g_CLIENTS_CNT  : positive;
           g_NODE_WIDTH   : positive
    );
    Port ( 
           CLK          : in STD_LOGIC;
           RST          : in STD_LOGIC;
           KEYS         : in t_keys;
           NUMBER       : in STD_LOGIC_VECTOR(3 downto 0);
           PS2_CODE     : in STD_LOGIC_VECTOR (7 downto 0);
           EDIT_ENA     : out STD_LOGIC;
           BUFF_RDY     : out STD_LOGIC;
           UPD_ARR      : out STD_LOGIC;
           UPD_DATA     : out STD_LOGIC;
           NODE_SEL     : out STD_LOGIC_VECTOR(g_NODE_WIDTH-1 downto 0);
           SEL_CELL_COL : out STD_LOGIC_VECTOR (2 downto 0);
           SEL_CELL_ROW : out STD_LOGIC_VECTOR (5 downto 0);
           CHAR_BUFF    : out char_buff_t;
           -- reg interface
           REQ          : out STD_LOGIC;
           ACK          : in  STD_LOGIC;
           RW           : out STD_LOGIC;
           DOUT         : out STD_LOGIC_VECTOR (11 downto 0)
          );
  end component;
  
----------------------------------------------------------------------------------
  
  component bus_arbiter is
    Generic (
        g_NUM_BLOCKS : positive;
        g_NODE_WIDTH : positive
    );
    Port(  CLK        : in STD_LOGIC;
            RST        : in STD_LOGIC;
            REQ        : in block_bit_t;
            block_RW   : in block_bit_t;
            block_COL  : in block_col_t;
            block_ROW  : in block_row_t;
            block_NODE : in block_node_t;
            block_DIN  : in block_data_t;
            ACK        : out block_bit_t;
            -- to register interface
            RW         : out STD_LOGIC;
            EN         : out STD_LOGIC;
            COL        : out STD_LOGIC_VECTOR (2 downto 0);
            ROW        : out STD_LOGIC_VECTOR (5 downto 0);
            NODE       : out STD_LOGIC_VECTOR (g_NODE_WIDTH-1 downto 0);
            DIN        : out STD_LOGIC_VECTOR (11 downto 0)
        );
  end component;
  
--------------------------------------------------------------------------------

  component rams_sp_wf is
    Generic (
        g_ADDR_WIDTH : positive := 10
    );
    port(
          clk : in std_logic;
          we : in std_logic;
          en : in std_logic;
          addr : in std_logic_vector(g_ADDR_WIDTH-1 downto 0);
          di : in std_logic_vector(15 downto 0);
          do : out std_logic_vector(15 downto 0)
        );
  end component;
  
--------------------------------------------------------------------------------
  
  component ui_adapter is
    Generic (
      g_FOOD_CNT     : positive;
      g_CLIENTS_CNT  : positive;
      g_NODE_WIDTH   : positive
    );
    Port (  CLK             : in STD_LOGIC;
            RST             : in STD_LOGIC;
            EDIT_ENA        : in STD_LOGIC;
            VGA_RDY         : in STD_LOGIC;
            UPD_ARR_IN      : in STD_LOGIC;
            UPD_DATA_IN     : in STD_LOGIC;
            ACK             : in STD_LOGIC;
            COL_IN          : in STD_LOGIC_VECTOR (2 downto 0);
            ROW_IN          : in STD_LOGIC_VECTOR (5 downto 0);
            CHAR_BUFF       : in char_buff_t;
            NODE_SEL        : in STD_LOGIC_VECTOR(g_NODE_WIDTH-1 downto 0);
            DIN             : in STD_LOGIC_VECTOR (11 downto 0);
            REQ             : out STD_LOGIC;
            RW              : out STD_LOGIC;
            UPD_ARR_OUT     : out STD_LOGIC;
            UPD_DATA_OUT    : out STD_LOGIC;
            COL_OUT         : out STD_LOGIC_VECTOR (2 downto 0);
            ROW_OUT         : out STD_LOGIC_VECTOR (5 downto 0);
            DATA_OUT        : out char_buff_t;
            NODE_UPD_ACTIVE : out std_logic
          );
  end component;
  
--------------------------------------------------------------------------------

component spi_ctrl is
    Generic (
      g_SLAVE_CNT     : positive;
      g_DATA_WIDTH    : positive;
      g_NODE_WIDTH    : positive
  );
  Port (CLK             : in STD_LOGIC;
      RST             : in STD_LOGIC;
      EDIT_ENA        : in STD_LOGIC;
      VGA_RDY         : in STD_LOGIC;
      -- from PS2
      UPD_DATA        : in STD_LOGIC;
      BACKSPACE       : in STD_LOGIC;
      COL             : in STD_LOGIC_VECTOR (2 downto 0);
      ROW             : in STD_LOGIC_VECTOR (5 downto 0);
      NODE            : in STD_LOGIC_VECTOR (g_NODE_WIDTH-1 downto 0);
      NUMBER          : in STD_LOGIC_VECTOR (11 downto 0);
      DATA            : in char_buff_t;
      -- to bus_arbiter
      RW              : out STD_LOGIC;
      COL_OUT         : out STD_LOGIC_VECTOR (2 downto 0);
      ROW_OUT         : out STD_LOGIC_VECTOR (5 downto 0);
      NODE_OUT        : out STD_LOGIC_VECTOR (g_NODE_WIDTH-1 downto 0);
      REQ             : out STD_LOGIC;
      ACK             : in STD_LOGIC;
      DIN             : in STD_LOGIC_VECTOR (11 downto 0);
      DOUT            : out STD_LOGIC_VECTOR (11 downto 0);
      -- to spi_master
      BUSY            : in STD_LOGIC;
      RX_DATA         : in STD_LOGIC_VECTOR (g_DATA_WIDTH-1 downto 0);
      SSEL            : out STD_LOGIC_VECTOR (g_SLAVE_CNT-1 downto 0);
      SINGLE          : out STD_LOGIC;
      TXN_ENA         : out STD_LOGIC;
      TX_DATA         : out STD_LOGIC_VECTOR (g_DATA_WIDTH-1 downto 0);
      -- from/to UI adapter
      NODE_UPD_ACTIVE : in STD_LOGIC;
      UPD_DATA_OUT    : out STD_LOGIC;
      END_OF_THE_DAY  : out STD_LOGIC;
      COL_UI          : out STD_LOGIC_VECTOR (2 downto 0);
      ROW_UI          : out STD_LOGIC_VECTOR (5 downto 0);
      SUMM_BCD        : out summ_digit_arr_t
  );
end component;

--------------------------------------------------------------------------------

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

  -- PS2 TOP
  signal   ps2_code             : std_logic_vector(7 downto 0);
  signal   keys                 : t_keys;
  signal   number               : STD_LOGIC_VECTOR(3 downto 0);

  -- PS2 IF CONTROLLER
  signal   edit_ena             : std_logic;
  signal   buff_rdy             : std_logic;
  signal   upd_arr_ctrl         : std_logic;
  signal   upd_data_ctrl        : std_logic;
  signal   node_sel_ctrl        : std_logic_vector(c_NODE_WIDTH-1 downto 0);
  signal   col_ctrl             : std_logic_vector(2 downto 0);
  signal   row_ctrl             : std_logic_vector(5 downto 0);
  signal   ps2_char_buff        : char_buff_t;
  signal   reg_ctrl             : std_logic;
  signal   ack_ctrl             : std_logic;
  signal   rw_ctrl              : std_logic;
  signal   dout_ctrl            : STD_LOGIC_VECTOR (11 downto 0);

  -- BUS ARBITER
  signal   REQ        :  block_bit_t;
  signal   block_RW   :  block_bit_t;
  signal   block_COL  :  block_col_t;
  signal   block_ROW  :  block_row_t;
  signal   block_NODE :  block_node_t;
  signal   block_DIN  :  block_data_t;
  signal   ACK        :  block_bit_t;

  -- SERVER REGISTERS IF
  signal   rw         : std_logic;
  signal   din        : std_logic_vector(11 downto 0);
  signal   dout       : std_logic_vector(11 downto 0);
  signal   node       : std_logic_vector(1 downto 0);
  signal   col_reg    : std_logic_vector(2 downto 0);
  signal   row_reg    : std_logic_vector(5 downto 0);

  -- UI ADAPTER
  signal   upd_arr_ui           : std_logic;
  signal   upd_data_ui          : std_logic;
  signal   col_in_ui            : std_logic_vector(2 downto 0);
  signal   row_in_ui            : std_logic_vector(5 downto 0);
  signal   col_out              : std_logic_vector(2 downto 0);
  signal   row_out              : std_logic_vector(5 downto 0);
  signal   node_in_ui           : std_logic_vector(c_NODE_WIDTH-1 downto 0);
  signal   reg_ui               : std_logic;
  signal   ack_ui               : std_logic;
  signal   rw_ui                : std_logic;
  signal   upd_data_out         : std_logic;
  signal   node_upd_active      : std_logic;
  signal   char_buff            : char_buff_t;
  signal   data_out_ui          : char_buff_t;

  -- signals from SPI controller
  -- to bus_arbiter
  signal   rw_spi               : std_logic;
  signal   col_spi              : std_logic_vector(2 downto 0);
  signal   row_spi              : std_logic_vector(5 downto 0);
  signal   node_spi             : std_logic_vector(c_NODE_WIDTH-1 downto 0);
  signal   reg_spi              : std_logic;
  signal   ack_spi              : std_logic;
  signal   dout_spi             : STD_LOGIC_VECTOR (11 downto 0);
  -- to spi_master
  signal   txn_ena              : std_logic;
  signal   single               : std_logic;
  signal   spi_busy             : std_logic;
  signal   ssel                 : std_logic_vector(c_CLIENTS_CNT-1 downto 0);
  signal   tx_data              : std_logic_vector(c_SPI_WIDTH-1 downto 0);
  signal   rx_data              : std_logic_vector(c_SPI_WIDTH-1 downto 0);
  
  signal   upd_data_spi         : std_logic;
  signal   end_of_the_day       : std_logic;
  signal   spi_summ_bcd         : summ_digit_arr_t;

  signal col_c  : unsigned(2 downto 0);
  signal row_c  : unsigned(4 downto 0);
  signal addr_c : unsigned(9 downto 0);
  
  signal do_c : std_logic_vector(15 downto 0);
  signal di_c : std_logic_vector(15 downto 0);
  signal we_c : std_logic;
  signal en   : std_logic;

  signal backspace_active_c : std_logic;
  signal backspace_active_s : std_logic := '0';

  signal col_spi_ui : std_logic_vector(2 downto 0);
  signal row_spi_ui : std_logic_vector(5 downto 0);

  signal miso_c : std_logic;
  signal ss_n_c : STD_LOGIC_VECTOR (g_SLAVE_CNT-1 downto 0);

begin

  col_c   <= (unsigned(col_reg) - 1) when ((unsigned(col_reg) >= 1) and (unsigned(col_reg) <= 4)) else (others => '0');
  row_c   <= unsigned(row_reg(4 downto 0)) when (row_reg(5) = '0') else (others => '0');
  addr_c  <= shift_left(resize(unsigned(node), addr_c'length), 8) or shift_left(resize(row_c, addr_c'length), 3) or resize(col_c, addr_c'length);
  
  di_c <= "0000" & din;
  we_c <= not rw;

  dout <= do_c(11 downto 0);

--------------------------------------------------------------------------------

ps2_top_i : ps2_top
port map(
  CLK      => CLK,
  RST      => RST,
  PS2_CLK  => PS2_CLK,
  PS2_DATA => PS2_DATA,
  PS2_CODE => ps2_code,
  NUMBER   => number,
  KEYS     => keys
);

--------------------------------------------------------------------------------

ps2_if_ctrl_i : ps2_if_ctrl
generic map(
  g_FOOD_CNT    => c_FOOD_CNT,
  g_CLIENTS_CNT => c_CLIENTS_CNT,
  g_NODE_WIDTH  => c_NODE_WIDTH
)
port map(
  CLK          => CLK,
  RST          => RST ,
  KEYS         => keys,
  NUMBER       => number,
  PS2_CODE     => ps2_code,
  EDIT_ENA     => edit_ena,
  BUFF_RDY     => buff_rdy,
  UPD_ARR      => upd_arr_ctrl,
  UPD_DATA     => upd_data_ctrl,
  NODE_SEL     => node_sel_ctrl,
  SEL_CELL_COL => col_ctrl,
  SEL_CELL_ROW => row_ctrl,
  CHAR_BUFF    => ps2_char_buff,
  REQ          => reg_ctrl,
  ACK          => ack_ctrl,
  RW           => rw_ctrl,
  DOUT         => dout_ctrl
);

--------------------------------------------------------------------------------

bus_arbiter_i : bus_arbiter
generic map(
  g_NUM_BLOCKS  => c_NUM_BLOCKS,
  g_NODE_WIDTH  => c_NODE_WIDTH
)
port map(
  CLK          => CLK,
  RST          => RST,
  REQ          => REQ,
  block_RW     => block_RW,
  block_COL    => block_COL,
  block_ROW    => block_ROW,
  block_NODE   => block_NODE,
  block_DIN    => block_DIN,
  ACK          => ACK,
  RW           => rw,
  EN           => en,
  COL          => col_reg,
  ROW          => row_reg,
  node         => node,
  DIN          => din
);

REQ(0)        <= reg_ctrl;
REQ(1)        <= reg_ui;
REQ(2)        <= reg_spi;
block_RW(0)   <= rw_ctrl;
block_RW(1)   <= rw_ui;
block_RW(2)   <= rw_spi;
block_COL(0)  <= col_ctrl;
block_COL(1)  <= col_out;
block_COL(2)  <= col_spi;
block_ROW(0)  <= row_ctrl;
block_ROW(1)  <= row_out;
block_ROW(2)  <= row_spi;
block_NODE(0) <= node_sel_ctrl;
block_NODE(1) <= node_in_ui;
block_NODE(2) <= node_spi;
block_DIN(0)  <= dout_ctrl;
block_DIN(1)  <= (others => '0');
block_DIN(2)  <= dout_spi;
ack_ctrl      <= ACK(0);
ack_ui        <= ACK(1);
ack_spi       <= ACK(2);

--------------------------------------------------------------------------------

rams_sp_wf_i : rams_sp_wf
port map(
  clk   => CLK,
  we    => we_c,
  en    => en,
  addr  => std_logic_vector(addr_c),
  di    => di_c,
  do    => do_c
);

--------------------------------------------------------------------------------

ui_adapter_i : ui_adapter
generic map(
  g_FOOD_CNT    => c_FOOD_CNT,
  g_CLIENTS_CNT => c_CLIENTS_CNT,
  g_NODE_WIDTH  => c_NODE_WIDTH
)
port map(
  CLK             => CLK,
  RST             => RST,
  EDIT_ENA        => edit_ena,
  VGA_RDY         => VGA_RDY,
  UPD_ARR_IN      => upd_arr_ui,
  UPD_DATA_IN     => upd_data_ui,
  ACK             => ack_ui,
  COL_IN          => col_in_ui,
  ROW_IN          => row_in_ui,
  CHAR_BUFF       => char_buff,
  NODE_SEL        => node_in_ui,
  DIN             => dout,
  REQ             => reg_ui,
  RW              => rw_ui,
  UPD_ARR_OUT     => UPD_ARR,
  UPD_DATA_OUT    => upd_data_out,
  COL_OUT         => col_out,
  ROW_OUT         => row_out,
  DATA_OUT        => data_out_ui,
  NODE_UPD_ACTIVE => node_upd_active
);

--------------------------------------------------------------------------------

spi_ctrl_i : spi_ctrl
generic map(
  g_SLAVE_CNT     => c_CLIENTS_CNT,
  g_DATA_WIDTH    => c_SPI_WIDTH,
  g_NODE_WIDTH    => c_NODE_WIDTH
)
port map(
  CLK             => CLK,
  RST             => RST,
  EDIT_ENA        => edit_ena,
  VGA_RDY         => VGA_RDY,
  -- from PS2
  UPD_DATA        => upd_data_out,
  BACKSPACE       => backspace_active_s,
  COL             => col_out,
  ROW             => row_out,
  NODE            => node_in_ui,
  NUMBER          => dout_ctrl,
  DATA            => data_out_ui,
  -- to bus_arbiter
  RW              => rw_spi,
  COL_OUT         => col_spi,
  ROW_OUT         => row_spi,
  NODE_OUT        => node_spi,
  REQ             => reg_spi,
  ACK             => ack_spi,
  DIN             => dout,
  DOUT            => dout_spi,
  -- to spi_master
  BUSY            => spi_busy,
  RX_DATA         => rx_data,
  SSEL            => ssel,
  SINGLE          => single,
  TXN_ENA         => txn_ena,
  TX_DATA         => tx_data,
  -- to UI adapter
  NODE_UPD_ACTIVE => node_upd_active,
  UPD_DATA_OUT    => upd_data_spi,
  END_OF_THE_DAY  => end_of_the_day,
  COL_UI          => col_spi_ui,
  ROW_UI          => row_spi_ui,
  SUMM_BCD        => spi_summ_bcd
);

--------------------------------------------------------------------------------

spi_master_i : spi_master
generic map(
  g_SLAVE_CNT   => c_CLIENTS_CNT,
  g_DATA_WIDTH  => c_SPI_WIDTH
)
port map(
  CLK        => CLK,
  RST        => RST,
  TXN_ENA    => txn_ena,
  MISO       => miso_c,
  SINGLE     => single,
  SSEL       => ssel,
  TX_DATA    => tx_data,
  SCLK       => SCLK,
  MOSI       => MOSI,
  BUSY       => spi_busy,
  SS_N       => ss_n_c,
  RX_DATA    => rx_data
);

--------------------------------------------------------------------------------
-- MUX col, row, node and update signals to UI adapter from PS2 and SPI
process(edit_ena, col_ctrl, row_ctrl, node_sel_ctrl, upd_arr_ctrl, spi_summ_bcd,
        upd_data_ctrl, row_spi, node_spi, upd_data_spi, end_of_the_day, ps2_char_buff)
begin
  if((edit_ena = '1') and (end_of_the_day = '0')) then
    col_in_ui     <= col_ctrl;
    row_in_ui     <= row_ctrl;
    node_in_ui    <= node_sel_ctrl;
    upd_arr_ui    <= upd_arr_ctrl;
    upd_data_ui   <= upd_data_ctrl;
    char_buff     <= ps2_char_buff;
  else
    if(end_of_the_day = '0') then
      col_in_ui     <= col_ctrl;
      row_in_ui     <= row_ctrl;
    else
      col_in_ui     <= col_spi_ui;
      row_in_ui     <= row_spi_ui;
    end if;
    node_in_ui    <= "00"; -- show server table in run mode
    upd_arr_ui    <= upd_arr_ctrl;
    upd_data_ui   <= upd_data_spi;
    char_buff     <= (others => (others => '0'));
    char_buff(0)  <= x"42"; -- S;
    char_buff(1)  <= x"44"; -- U;
    char_buff(2)  <= x"3c"; -- M;
    char_buff(3)  <= x"29"; -- :
    char_buff(4)  <= x"00"; --
    char_buff(5)  <= spi_summ_bcd(0);
    char_buff(6)  <= spi_summ_bcd(1);
    char_buff(7)  <= spi_summ_bcd(2);
    char_buff(8)  <= spi_summ_bcd(3);
    char_buff(9)  <= spi_summ_bcd(4);
    char_buff(10) <= spi_summ_bcd(5);
    char_buff(11) <= spi_summ_bcd(6);
  end if;
end process;

-- backspace was activated flag process
process(backspace_active_s, keys, txn_ena) begin
  backspace_active_c <= backspace_active_s;

  if(keys.bckspc = '1') then
    backspace_active_c <= '1';
  elsif(txn_ena = '1') then
    backspace_active_c <= '0';
  end if;
end process;

process(CLK, RST) begin
  if(RST = '1') then
    backspace_active_s  <= '0';
  elsif(rising_edge(CLK)) then
    backspace_active_s  <= backspace_active_c;
  end if;
end process;

process(ss_n_c, MISO) begin
  miso_c <= '0';

  if(unsigned(ss_n_c) = TO_UNSIGNED(0, ss_n_c'length)) then
    miso_c <= '0';
  else
    for i in 0 to c_CLIENTS_CNT-1 loop
      if(ss_n_c(i) = '0') then
        miso_c <= MISO(i);
        exit;
      end if;
    end loop;
  end if;
end process;

--------------------------------------------------------------------------------
-- Output assignments
  COL       <= col_out;
  ROW       <= row_out;
  UPD_DATA  <= upd_data_out;
  DATA_OUT  <= data_out_ui;
  SS_N      <= ss_n_c;

end Behavioral;
