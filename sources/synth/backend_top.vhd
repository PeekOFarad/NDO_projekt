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

entity backend_top is
    Port ( CLK      : in STD_LOGIC;
           RST      : in STD_LOGIC;
           PS2_CLK  : in STD_LOGIC;
           PS2_DATA : in STD_LOGIC;
           COL      : out STD_LOGIC_VECTOR (2 downto 0);
           ROW      : out STD_LOGIC_VECTOR (5 downto 0);
           UPD_ARR  : out STD_LOGIC;
           UPD_DATA : out STD_LOGIC;
           DATA_OUT : out sprit_buff_t);
end backend_top;

architecture Behavioral of backend_top is

  component ps2_top is
      Port (  CLK      : in STD_LOGIC;
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
    Port (  CLK          : in STD_LOGIC;
            RST          : in STD_LOGIC;
            EDIT_ENA     : in STD_LOGIC;
            KEYS         : in t_keys;
            NUMBER       : in STD_LOGIC_VECTOR(3 downto 0);
            PS2_CODE     : in STD_LOGIC_VECTOR (7 downto 0);
            START_DAY    : out STD_LOGIC;
            BUFF_RDY     : out STD_LOGIC;
            UPD_ARR      : out STD_LOGIC;
            UPD_DATA     : out STD_LOGIC;
            NODE_SEL     : out STD_LOGIC_VECTOR(g_NODE_WIDTH downto 0);
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
            COL        : out STD_LOGIC_VECTOR (2 downto 0);
            ROW        : out STD_LOGIC_VECTOR (5 downto 0);
            NODE       : out STD_LOGIC_VECTOR (g_NODE_WIDTH downto 0);
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
    Port ( CLK      : in STD_LOGIC;
            RST      : in STD_LOGIC;
            RW       : in STD_LOGIC;
            COL      : in STD_LOGIC_VECTOR (2 downto 0);
            ROW      : in STD_LOGIC_VECTOR (5 downto 0);
            NODE     : in STD_LOGIC_VECTOR (g_NODE_WIDTH downto 0);
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
            UPD_ARR_IN   : in STD_LOGIC;
            UPD_DATA_IN  : in STD_LOGIC;
            ACK          : in STD_LOGIC;
            COL_IN       : in STD_LOGIC_VECTOR (2 downto 0);
            ROW_IN       : in STD_LOGIC_VECTOR (5 downto 0);
            CHAR_BUFF    : in char_buff_t;
            NODE_SEL     : in STD_LOGIC_VECTOR(g_NODE_WIDTH downto 0);
            DIN          : in STD_LOGIC_VECTOR (11 downto 0);
            REQ          : out STD_LOGIC;
            RW           : out STD_LOGIC;
            UPD_ARR_OUT  : out STD_LOGIC;
            UPD_DATA_OUT : out STD_LOGIC;
            COL_OUT      : out STD_LOGIC_VECTOR (2 downto 0);
            ROW_OUT      : out STD_LOGIC_VECTOR (5 downto 0);
            DATA_OUT     : out sprit_buff_t);
  end component;
  
--------------------------------------------------------------------------------

  -- PS2 TOP
  signal   ps2_code             : std_logic_vector(7 downto 0);
  signal   keys                 : t_keys;
  signal   number               : STD_LOGIC_VECTOR(3 downto 0);

  -- PS2 IF CONTROLLER
  signal   edit_ena             : std_logic;
  signal   start_day            : std_logic;
  signal   buff_rdy             : std_logic;
  signal   upd_arr_ctrl         : std_logic;
  signal   upd_data_ctrl        : std_logic;
  signal   node_sel_ctrl        : std_logic_vector(c_NODE_WIDTH downto 0);
  signal   col_ctrl             : std_logic_vector(2 downto 0);
  signal   row_ctrl             : std_logic_vector(5 downto 0);
  signal   char_buff            : char_buff_t;
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
  signal   node_in_ui           : std_logic_vector(c_NODE_WIDTH downto 0);
  signal   reg_ui               : std_logic;
  signal   ack_ui               : std_logic;
  signal   rw_ui                : std_logic;

  -- signals from SPI controller
  signal   upd_data_spi         : std_logic;
  signal   node_spi             : std_logic_vector(c_NODE_WIDTH downto 0);
  signal   row_spi              : std_logic_vector(5 downto 0);

begin

  -- temporary assigns
  edit_ena     <= '1';
  upd_data_spi <= '0';
  node_spi     <= (others => '0');
  row_spi      <= (others => '0');

--------------------------------------------------------------------------------

ps2_top_i : ps2_top
port map(
  CLK      => CLK,
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
  EDIT_ENA     => edit_ena,
  KEYS         => keys,
  NUMBER       => number,
  PS2_CODE     => ps2_code,
  START_DAY    => start_day,
  BUFF_RDY     => buff_rdy,
  UPD_ARR      => upd_arr_ctrl,
  UPD_DATA     => upd_data_ctrl,
  NODE_SEL     => node_sel_ctrl,
  SEL_CELL_COL => col_ctrl,
  SEL_CELL_ROW => row_ctrl,
  CHAR_BUFF    => char_buff,
  REQ          => reg_ctrl,
  ACK          => ack_ctrl,
  RW           => rw_ctrl,
  DOUT         => dout_ctrl
);

--------------------------------------------------------------------------------

bus_arbiter_i : bus_arbiter
generic map(
  g_NUM_BLOCKS  => 2,
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

REQ(0)        <= reg_ctrl;
REQ(1)        <= reg_ui;
block_RW(0)   <= rw_ctrl;
block_RW(1)   <= rw_ui;
block_COL(0)  <= col_ctrl;
block_COL(1)  <= col_out;
block_ROW(0)  <= row_ctrl;
block_ROW(1)  <= row_out;
block_NODE(0) <= node_sel_ctrl;
block_NODE(1) <= node_in_ui;
block_DIN(0)  <= dout_ctrl;
block_DIN(1)  <= (others => '0');
ack_ctrl      <= ACK(0);
ack_ui        <= ACK(1);

--------------------------------------------------------------------------------

server_regs_if_i : server_regs_if
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

ui_adapter_i : ui_adapter
generic map(
  g_FOOD_CNT    => c_FOOD_CNT,
  g_CLIENTS_CNT => c_CLIENTS_CNT,
  g_NODE_WIDTH  => c_NODE_WIDTH
)
port map(
  CLK          => CLK,
  RST          => RST,
  EDIT_ENA     => edit_ena,
  UPD_ARR_IN   => upd_arr_ui,
  UPD_DATA_IN  => upd_data_ui,
  ACK          => ack_ui,
  COL_IN       => col_in_ui,
  ROW_IN       => row_in_ui,
  CHAR_BUFF    => char_buff,
  NODE_SEL     => node_in_ui,
  DIN          => dout,
  REQ          => reg_ui,
  RW           => rw_ui,
  UPD_ARR_OUT  => UPD_ARR,
  UPD_DATA_OUT => UPD_DATA,
  COL_OUT      => col_out,
  ROW_OUT      => row_out,
  DATA_OUT     => DATA_OUT
);

--------------------------------------------------------------------------------
-- TODO: replace with ctrl_core and spi_if modules
-- MUX col, row, node and update signals to UI adapter from PS2 and SPI
process(edit_ena, col_ctrl, row_ctrl, node_sel_ctrl, upd_arr_ctrl,
        upd_data_ctrl, row_spi, node_spi, upd_data_spi)
begin
  if(edit_ena = '1') then
    col_in_ui   <= col_ctrl;
    row_in_ui   <= row_ctrl;
    node_in_ui  <= node_sel_ctrl;
    upd_arr_ui  <= upd_arr_ctrl;
    upd_data_ui <= upd_data_ctrl;
  else
    col_in_ui   <= "001";
    row_in_ui   <= row_spi;
    node_in_ui  <= node_spi;
    upd_arr_ui  <= '0';
    upd_data_ui <= upd_data_spi;
  end if;
end process;

--------------------------------------------------------------------------------
-- Output assignments
  COL <= col_out;
  ROW <= row_out;

end Behavioral;