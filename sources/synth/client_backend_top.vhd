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
    Port ( CLK      : in STD_LOGIC;
           RST      : in STD_LOGIC;
           -- PS2
           PS2_CLK  : in STD_LOGIC;
           PS2_DATA : in STD_LOGIC;
           -- SPI
           SCSB     : in STD_LOGIC;
           SCLK     : in STD_LOGIC;
           MOSI     : in STD_LOGIC;
           MISO     : out STD_LOGIC;
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
  
  component ui_adapter is
    Generic (
      g_FOOD_CNT     : positive;
      g_CLIENTS_CNT  : positive;
      g_NODE_WIDTH   : positive
    );
    Port ( CLK          : in STD_LOGIC;
            RST          : in STD_LOGIC;
            EDIT_ENA     : in STD_LOGIC;
            VGA_RDY      : in STD_LOGIC;
            UPD_ARR_IN   : in STD_LOGIC;
            UPD_DATA_IN  : in STD_LOGIC;
            ACK          : in STD_LOGIC;
            COL_IN       : in STD_LOGIC_VECTOR (2 downto 0);
            ROW_IN       : in STD_LOGIC_VECTOR (5 downto 0);
            CHAR_BUFF    : in char_buff_t;
            NODE_SEL     : in STD_LOGIC_VECTOR(g_NODE_WIDTH-1 downto 0);
            DIN          : in STD_LOGIC_VECTOR (11 downto 0);
            REQ          : out STD_LOGIC;
            RW           : out STD_LOGIC;
            UPD_ARR_OUT  : out STD_LOGIC;
            UPD_DATA_OUT : out STD_LOGIC;
            COL_OUT      : out STD_LOGIC_VECTOR (2 downto 0);
            ROW_OUT      : out STD_LOGIC_VECTOR (5 downto 0);
            DATA_OUT     : out char_buff_t);
  end component;
  
--------------------------------------------------------------------------------

component client_ctrl is
    Generic (
           g_DATA_WIDTH  : positive
    );
    Port(  CLK       : in STD_LOGIC;
           RST       : in STD_LOGIC;
           -- from/to SPI_SLAVE
           BUSY      : in STD_LOGIC;
           DATA_RDY  : in STD_LOGIC;
           RX_DATA   : in STD_LOGIC_VECTOR (g_DATA_WIDTH-1 downto 0);
           TX_DATA   : out STD_LOGIC_VECTOR (g_DATA_WIDTH-1 downto 0);
           -- to UI_ADAPTER
           VGA_RDY   : in STD_LOGIC;
           UPD_DATA  : out STD_LOGIC;
           COL       : out STD_LOGIC_VECTOR (2 downto 0);
           ROW       : out STD_LOGIC_VECTOR (5 downto 0);
           CHAR_BUFF : out char_buff_t;
           -- to bus_arbiter
           RW       : out STD_LOGIC;
           COL_OUT  : out STD_LOGIC_VECTOR (2 downto 0);
           ROW_OUT  : out STD_LOGIC_VECTOR (5 downto 0);
           REQ      : out STD_LOGIC;
           ACK      : in STD_LOGIC;
           DIN      : in STD_LOGIC_VECTOR (11 downto 0);
           DOUT     : out STD_LOGIC_VECTOR (11 downto 0)
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

  -- UI ADAPTER
  signal   upd_arr_ui           : std_logic;
  signal   upd_data_ui          : std_logic;
  signal   col_in_ui            : std_logic_vector(2 downto 0);
  signal   row_in_ui            : std_logic_vector(5 downto 0);
  signal   col_out              : std_logic_vector(2 downto 0);
  signal   row_out              : std_logic_vector(5 downto 0);
  signal   node_in_ui           : std_logic_vector(c_NODE_WIDTH-1 downto 0);
  signal   req_ui               : std_logic;
  signal   ack_ui               : std_logic;
  signal   rw_ui                : std_logic;
  signal   upd_data_out         : std_logic;
  signal   data_out_ui          : char_buff_t;

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

begin

--------------------------------------------------------------------------------

-- ps2_top_i : ps2_top
-- port map(
--   CLK      => CLK,
--   RST      => RST,
--   PS2_CLK  => PS2_CLK,
--   PS2_DATA => PS2_DATA,
--   PS2_CODE => ps2_code,
--   NUMBER   => number,
--   KEYS     => keys
-- );

--------------------------------------------------------------------------------

-- ps2_if_ctrl_i : ps2_if_ctrl
-- generic map(
--   g_FOOD_CNT    => c_FOOD_CNT,
--   g_CLIENTS_CNT => c_CLIENTS_CNT,
--   g_NODE_WIDTH  => c_NODE_WIDTH
-- )
-- port map(
--   CLK          => CLK,
--   RST          => RST ,
--   KEYS         => keys,
--   NUMBER       => number,
--   PS2_CODE     => ps2_code,
--   EDIT_ENA     => edit_ena,
--   BUFF_RDY     => buff_rdy,
--   UPD_ARR      => upd_arr_ctrl,
--   UPD_DATA     => upd_data_ctrl,
--   NODE_SEL     => node_sel_ctrl,
--   SEL_CELL_COL => col_ctrl,
--   SEL_CELL_ROW => row_ctrl,
--   CHAR_BUFF    => char_buff,
--   REQ          => req_ctrl,
--   ACK          => ack_ctrl,
--   RW           => rw_ctrl,
--   DOUT         => dout_ctrl
-- );

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

-- ui_adapter_i : ui_adapter
-- generic map(
--   g_FOOD_CNT    => c_FOOD_CNT,
--   g_CLIENTS_CNT => c_CLIENTS_CNT,
--   g_NODE_WIDTH  => c_NODE_WIDTH
-- )
-- port map(
--   CLK          => CLK,
--   RST          => RST,
--   EDIT_ENA     => edit_ena,
--   VGA_RDY      => VGA_RDY,
--   UPD_ARR_IN   => upd_arr_ui,
--   UPD_DATA_IN  => upd_data_ui,
--   ACK          => ack_ui,
--   COL_IN       => col_in_ui,
--   ROW_IN       => row_in_ui,
--   CHAR_BUFF    => char_buff,
--   NODE_SEL     => node_in_ui,
--   DIN          => dout,
--   REQ          => req_ui,
--   RW           => rw_ui,
--   UPD_ARR_OUT  => UPD_ARR,
--   UPD_DATA_OUT => upd_data_out,
--   COL_OUT      => col_out,
--   ROW_OUT      => row_out,
--   DATA_OUT     => data_out_ui
-- );

--------------------------------------------------------------------------------

client_ctrl_i : client_ctrl
generic map(
  g_DATA_WIDTH  => c_SPI_WIDTH
)
port map(
  CLK        => CLK,
  RST        => RST,
  BUSY       => spi_busy,
  DATA_RDY   => data_rdy,
  RX_DATA    => rx_data,
  TX_DATA    => tx_data,
  VGA_RDY    => VGA_RDY,
  UPD_DATA   => upd_data_spi,
  COL        => col_ui_spi,
  ROW        => row_ui_spi,
  CHAR_BUFF  => char_buff_spi,
  RW         => rw_spi,
  COL_OUT    => col_spi,
  ROW_OUT    => row_spi,
  REQ        => req_spi,
  ACK        => ack_spi,
  DIN        => dout,
  DOUT       => dout_spi
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
-- TODO: replace with ctrl_core and spi_if modules
-- MUX col, row, node and update signals to UI adapter from PS2 and SPI
-- process(edit_ena, col_ctrl, row_ctrl, node_sel_ctrl, upd_arr_ctrl,
--         upd_data_ctrl, row_spi, node_spi, upd_data_spi)
-- begin
--   if(edit_ena = '1') then
--     col_in_ui   <= col_ctrl;
--     row_in_ui   <= row_ctrl;
--     node_in_ui  <= node_sel_ctrl;
--     upd_arr_ui  <= upd_arr_ctrl;
--     upd_data_ui <= upd_data_ctrl;
--   else
--     col_in_ui   <= "001";
--     row_in_ui   <= row_spi;
--     node_in_ui  <= "00"; -- show server table in run mode
--     upd_arr_ui  <= '0';
--     upd_data_ui <= upd_data_spi;
--   end if;
-- end process;

--------------------------------------------------------------------------------
-- Output assignments
UPD_ARR  <= '0';
UPD_DATA <= upd_data_spi;
COL      <= col_ui_spi;
ROW      <= row_ui_spi;
DATA_OUT <= char_buff_spi;

end Behavioral;
