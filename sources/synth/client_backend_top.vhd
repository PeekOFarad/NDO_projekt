----------------------------------------------------------------------------------
-- client_backend_top.vhd
-- Client part backend top module
-- 26 Nov, 2024
-- Semestral project in the autumn semester of 2024 in MPC-NDO.
-- Artem Gumenyuk (xgumen00@vutbr.cz)
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.ps2_pkg.all;
use work.client_pkg.all;
use work.common_pkg.all;

entity client_backend_top is
    Port (CLK      : in STD_LOGIC;
          RST      : in STD_LOGIC;
          -- PS2
          PS2_CLK  : in STD_LOGIC;
          PS2_DATA : in STD_LOGIC;
          -- SPI
          SCSB     : in STD_LOGIC;
          SCLK     : in STD_LOGIC;
          MOSI     : in STD_LOGIC;
          MISO     : out STD_LOGIC;
          -- BUTTONS
          BTN_S    : in STD_LOGIC;
          BTN_Z    : in STD_LOGIC;
          BTN_E    : in STD_LOGIC;
          -- UI TOP
          VGA_RDY  : in STD_LOGIC;
          UPD_ARR  : out STD_LOGIC;
          UPD_DATA : out STD_LOGIC;
          COL      : out STD_LOGIC_VECTOR (2 downto 0);
          ROW      : out STD_LOGIC_VECTOR (5 downto 0);
          DATA_OUT : out char_buff_t);
end client_backend_top;

architecture Behavioral of client_backend_top is

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
  
  component bus_arbiter_client is
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
            COL        : out STD_LOGIC_VECTOR (2 downto 0);
            ROW        : out STD_LOGIC_VECTOR (5 downto 0);
            NODE       : out STD_LOGIC_VECTOR (g_NODE_WIDTH-1 downto 0);
            DIN        : out STD_LOGIC_VECTOR (11 downto 0)
        );
  end component;
  
--------------------------------------------------------------------------------
  
  component server_regs_if is
    Generic (
            g_FOOD_CNT     : positive;
            g_CLIENTS_CNT  : positive;
            g_NODE_WIDTH   : positive
    );
    Port (  CLK      : in STD_LOGIC;
            RST      : in STD_LOGIC;
            RW       : in STD_LOGIC;
            COL      : in STD_LOGIC_VECTOR (2 downto 0);
            ROW      : in STD_LOGIC_VECTOR (5 downto 0);
            NODE     : in STD_LOGIC_VECTOR (g_NODE_WIDTH-1 downto 0);
            DIN      : in STD_LOGIC_VECTOR (11 downto 0);
            DOUT     : out STD_LOGIC_VECTOR (11 downto 0));
  end component;
  
--------------------------------------------------------------------------------

component client_ctrl is
    Generic (
      g_DATA_WIDTH  : positive := c_SPI_WIDTH
  );
  Port( CLK       : in STD_LOGIC;
        RST       : in STD_LOGIC;
        -- from/to SPI_SLAVE
        BUSY      : in STD_LOGIC;
        DATA_RDY  : in STD_LOGIC;
        RX_DATA   : in STD_LOGIC_VECTOR (g_DATA_WIDTH-1 downto 0);
        TX_DATA   : out STD_LOGIC_VECTOR (g_DATA_WIDTH-1 downto 0);
        -- from/to UI_ADAPTER
        VGA_RDY   : in STD_LOGIC;
        UPD_DATA  : out STD_LOGIC;
        COL       : out STD_LOGIC_VECTOR (2 downto 0);
        ROW       : out STD_LOGIC_VECTOR (5 downto 0);
        CHAR_BUFF : out char_buff_t;
        -- from/to bus_arbiter
        RW       : out STD_LOGIC;
        COL_OUT  : out STD_LOGIC_VECTOR (2 downto 0);
        ROW_OUT  : out STD_LOGIC_VECTOR (5 downto 0);
        REQ      : out STD_LOGIC;
        ACK      : in STD_LOGIC;
        DIN      : in STD_LOGIC_VECTOR (11 downto 0);
        DOUT     : out STD_LOGIC_VECTOR (11 downto 0);
        -- from/to CLIENT_CORE
        REQ_TO_SERV : in STD_LOGIC;
        REQ_ROW     : in STD_LOGIC_VECTOR (5 downto 0);
        RSP_RDY     : out STD_LOGIC;
        RSP_AMOUNT  : out STD_LOGIC_VECTOR (3 downto 0);
        EDIT_ENA    : out STD_LOGIC
  );
end component;

--------------------------------------------------------------------------------

component spi_slave is
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
end component;

--------------------------------------------------------------------------------

component client_core is
  Generic (
         g_DATA_WIDTH  : positive := c_SPI_WIDTH
  );
  Port( CLK       : in STD_LOGIC;
        RST       : in STD_LOGIC;
        -- from/to UI_ADAPTER
        VGA_RDY   : in STD_LOGIC;
        UPD_ARR   : out STD_LOGIC;
        UPD_DATA  : out STD_LOGIC;
        COL       : out STD_LOGIC_VECTOR (2 downto 0);
        ROW       : out STD_LOGIC_VECTOR (5 downto 0);
        CHAR_BUFF : out char_buff_t;
        -- from/to bus_arbiter (PS2 part)
        RW_1       : out STD_LOGIC;
        COL_OUT_1  : out STD_LOGIC_VECTOR (2 downto 0);
        ROW_OUT_1  : out STD_LOGIC_VECTOR (5 downto 0);
        REQ_1      : out STD_LOGIC;
        ACK_1      : in  STD_LOGIC;
        DOUT_1     : out STD_LOGIC_VECTOR (11 downto 0);
        -- from/to bus_arbiter (SPI part)
        RW_2       : out STD_LOGIC;
        COL_OUT_2  : out STD_LOGIC_VECTOR (2 downto 0);
        ROW_OUT_2  : out STD_LOGIC_VECTOR (5 downto 0);
        REQ_2      : out STD_LOGIC;
        ACK_2      : in  STD_LOGIC;
        DIN        : in  STD_LOGIC_VECTOR (11 downto 0);
        DOUT_2     : out STD_LOGIC_VECTOR (11 downto 0);
        -- from/to client controller (SPI)
        EDIT_ENA    : in  STD_LOGIC;
        RSP_RDY     : in  STD_LOGIC;
        RSP_AMOUNT  : in  STD_LOGIC_VECTOR (3 downto 0);
        REQ_TO_SERV : out STD_LOGIC;
        REQ_ROW     : out STD_LOGIC_VECTOR (5 downto 0);
        -- from PS2 top
        KEYS     : in t_keys;
        -- buttons (S, Z, E)
        BTN_S    : in STD_LOGIC;
        BTN_Z    : in STD_LOGIC;
        BTN_E    : in STD_LOGIC
      );
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
  signal   char_buff            : char_buff_t;
  signal   req_ctrl             : std_logic;
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
  signal   node       : std_logic_vector(c_NODE_WIDTH-1 downto 0);
  signal   col_reg    : std_logic_vector(2 downto 0);
  signal   row_reg    : std_logic_vector(5 downto 0);

  -- signals from SPI controller
  -- from/to bus_arbiter
  signal   rw_spi               : std_logic;
  signal   col_spi              : std_logic_vector(2 downto 0);
  signal   row_spi              : std_logic_vector(5 downto 0);
  signal   req_spi              : std_logic;
  signal   ack_spi              : std_logic;
  signal   din_spi              : STD_LOGIC_VECTOR (11 downto 0);
  signal   dout_spi             : STD_LOGIC_VECTOR (11 downto 0);
  -- from/to spi_slave
  signal   spi_busy             : std_logic;
  signal   data_rdy             : std_logic;
  signal   tx_data              : std_logic_vector(c_SPI_WIDTH-1 downto 0);
  signal   rx_data              : std_logic_vector(c_SPI_WIDTH-1 downto 0);
  -- to ui_adapter
  signal   upd_data_spi         : std_logic;
  signal   col_ui_spi           : std_logic_vector(2 downto 0);
  signal   row_ui_spi           : std_logic_vector(5 downto 0);
  signal   char_buff_spi        : char_buff_t;

  -- signals from client core
  -- from/to bus_arbiter
  signal   rw_core_1            : std_logic;
  signal   col_core_1           : std_logic_vector(2 downto 0);
  signal   row_core_1           : std_logic_vector(5 downto 0);
  signal   req_core_1           : std_logic;
  signal   ack_core_1           : std_logic;
  signal   dout_core_1          : STD_LOGIC_VECTOR (11 downto 0);

  signal   rw_core_2            : std_logic;
  signal   col_core_2           : std_logic_vector(2 downto 0);
  signal   row_core_2           : std_logic_vector(5 downto 0);
  signal   req_core_2           : std_logic;
  signal   ack_core_2           : std_logic;
  signal   dout_core_2          : STD_LOGIC_VECTOR (11 downto 0);
  --from/to client controller
  signal   req_to_serv          : std_logic;
  signal   req_row              : std_logic_vector (5 downto 0);
  signal   rsp_rdy              : std_logic;
  signal   rsp_amount           : std_logic_vector (3 downto 0);
  -- to UI output in run mode
  signal   upd_arr_core         : std_logic;
  signal   upd_data_core        : std_logic;
  signal   col_core             : std_logic_vector(2 downto 0);
  signal   row_core             : std_logic_vector(5 downto 0);
  signal   char_buff_core       : char_buff_t;

begin

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

bus_arbiter_cl_i : bus_arbiter_client
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
  COL          => col_reg,
  ROW          => row_reg,
  node         => node,
  DIN          => din
);

REQ(0)        <= req_spi;
block_RW(0)   <= rw_spi;
block_COL(0)  <= col_spi;
block_ROW(0)  <= row_spi;
block_NODE(0) <= "0";
block_DIN(0)  <= dout_spi;
ack_spi       <= ACK(0);

REQ(1)        <= req_core_1;
block_RW(1)   <= rw_core_1;
block_COL(1)  <= col_core_1;
block_ROW(1)  <= row_core_1;
block_NODE(1) <= "0";
block_DIN(1)  <= dout_core_1;
ack_core_1    <= ACK(1);

REQ(2)        <= req_core_2;
block_RW(2)   <= rw_core_2;
block_COL(2)  <= col_core_2;
block_ROW(2)  <= row_core_2;
block_NODE(2) <= "0";
block_DIN(2)  <= dout_core_2;
ack_core_2    <= ACK(2);

--------------------------------------------------------------------------------

client_regs_if_i : server_regs_if
generic map(
  g_FOOD_CNT    => c_FOOD_CNT,
  g_CLIENTS_CNT => c_CLIENTS_CNT,
  g_NODE_WIDTH  => c_NODE_WIDTH
)
port map(
  CLK    => CLK,
  RST    => RST,
  RW     => rw,
  COL    => col_reg,
  ROW    => row_reg,
  NODE   => node,
  DIN    => din,
  DOUT   => dout
);

--------------------------------------------------------------------------------

client_ctrl_i : client_ctrl
generic map(
  g_DATA_WIDTH  => c_SPI_WIDTH
)
port map(
  CLK         => CLK,
  RST         => RST,
  BUSY        => spi_busy,
  DATA_RDY    => data_rdy,
  RX_DATA     => rx_data,
  TX_DATA     => tx_data,
  VGA_RDY     => VGA_RDY,
  UPD_DATA    => upd_data_spi,
  COL         => col_ui_spi,
  ROW         => row_ui_spi,
  CHAR_BUFF   => char_buff_spi,
  RW          => rw_spi,
  COL_OUT     => col_spi,
  ROW_OUT     => row_spi,
  REQ         => req_spi,
  ACK         => ack_spi,
  DIN         => dout,
  DOUT        => dout_spi,
  REQ_TO_SERV => req_to_serv,
  REQ_ROW     => req_row,
  RSP_RDY     => rsp_rdy,
  RSP_AMOUNT  => rsp_amount,
  EDIT_ENA    => edit_ena
);

--------------------------------------------------------------------------------

spi_slave_i : spi_slave
generic map(
  g_DATA_WIDTH  => c_SPI_WIDTH
)
port map(
  CLK        => CLK,
  RST        => RST,
  MOSI       => MOSI,
  SCSB       => SCSB,
  SCLK       => SCLK,
  TX_DATA    => tx_data,
  MISO       => MISO,
  BUSY       => spi_busy,
  DATA_RDY   => data_rdy,
  RX_DATA    => rx_data
);

--------------------------------------------------------------------------------

client_core_i : client_core
generic map(
  g_DATA_WIDTH  => c_SPI_WIDTH
)
port map(
  CLK         => CLK,
  RST         => RST,
  -- from/to UI_ADAPTER
  VGA_RDY     => VGA_RDY,
  UPD_ARR     => upd_arr_core,
  UPD_DATA    => upd_data_core,
  COL         => col_core,
  ROW         => row_core,
  CHAR_BUFF   => char_buff_core,
  -- from/to bus_arbiter (PS2 part)
  RW_1        => rw_core_1,
  COL_OUT_1   => col_core_1,
  ROW_OUT_1   => row_core_1,
  REQ_1       => req_core_1,
  ACK_1       => ack_core_1,
  DOUT_1      => dout_core_1,
  -- from/to bus_arbiter (SPI part)
  RW_2        => rw_core_2,
  COL_OUT_2   => col_core_2,
  ROW_OUT_2   => row_core_2,
  REQ_2       => req_core_2,
  ACK_2       => ack_core_2,
  DIN         => dout,
  DOUT_2      => dout_core_2,
  -- from/to client controller (SPI)
  EDIT_ENA    => edit_ena,
  RSP_RDY     => rsp_rdy,
  RSP_AMOUNT  => rsp_amount,
  REQ_TO_SERV => req_to_serv,
  REQ_ROW     => req_row,
  -- from PS2 top
  KEYS        => keys,
  -- buttons (S, Z, E)
  BTN_S       => BTN_S,
  BTN_Z       => BTN_Z,
  BTN_E       => BTN_E
);
--------------------------------------------------------------------------------
-- switch UI interface outputs between client_ctrl and client_core

process(edit_ena, upd_data_spi, col_ui_spi, row_ui_spi, char_buff_spi,
        upd_arr_core, upd_data_core, col_core, row_core, char_buff_core) begin
  if(edit_ena = '1') then -- config
    UPD_ARR   <= '0';
    UPD_DATA  <= upd_data_spi;
    COL       <= col_ui_spi;
    ROW       <= row_ui_spi;
    DATA_OUT  <= char_buff_spi;
  else -- run
    UPD_ARR   <= upd_arr_core;
    UPD_DATA  <= upd_data_core;
    COL       <= col_core;
    ROW       <= row_core;
    DATA_OUT  <= char_buff_core;
  end if;
end process; 

--------------------------------------------------------------------------------
-- Output assignments

end Behavioral;
