----------------------------------------------------------------------------------
-- ps2_if_ctrl.vhd
-- Process signals from PS2_top into registers.
-- 08 Oct, 2024
-- Semestral project in the autumn semester of 2024 in MPC-NDO.
-- Artem Gumenyuk (xgumen00@vutbr.cz)
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.ps2_pkg.all;
use work.server_pkg.all;
use IEEE.NUMERIC_STD.ALL;

entity ps2_if_ctrl is
    Generic (
           g_FOOD_CNT     : positive;
           g_CLIENTS_CNT  : positive
    );
    Port ( CLK          : in STD_LOGIC;
           RST          : in STD_LOGIC;
           EDIT_ENA     : in STD_LOGIC;
           KEYS         : in t_keys;
           START_DAY    : out STD_LOGIC;
           NEXT_BTN     : out STD_LOGIC; -- TODO: implement button when user swith server/client
           SEL_CELL_COL : out STD_LOGIC_VECTOR (2 downto 0);
           SEL_CELL_ROW : out STD_LOGIC_VECTOR (5 downto 0));
end ps2_if_ctrl;

architecture Behavioral of ps2_if_ctrl is

  type t_fsm_ps2_ctrl is (idle, cell_rst, edit);
  type amount_table_t is array(0 to g_CLIENTS_CNT, 0 to (g_FOOD_CNT - 1)) of amount_t;
  type price_table_t is array(0 to (g_FOOD_CNT - 1)) of price_t;
  
  constant c_MAX_ROW    : integer := 32;
  constant c_MIN_COL    : integer := 1;
  constant c_MAX_COL    : integer := 5;
  constant c_NODE_WIDTH : integer := integer(ceil(log2(real(g_CLIENTS_CNT))));
  
  signal fsm_c          : t_fsm_ps2_ctrl;
  signal fsm_s          : t_fsm_ps2_ctrl := idle;
  signal start_day_c    : std_logic;
  signal start_day_s    : std_logic := '0';
  signal sel_cell_col_c : unsigned(2 downto 0);
  signal sel_cell_col_s : unsigned(2 downto 0) := to_unsigned(c_MIN_COL, 3);
  signal sel_cell_row_c : unsigned(5 downto 0);
  signal sel_cell_row_s : unsigned(5 downto 0) := (others => '0');
  
  signal amount_c       : amount_table_t;
  signal amount_s       : amount_table_t := (others => (others => (others => '0')));
  
  signal st_price_c     : price_table_t;
  signal st_price_s     : price_table_t := (others => (others => '0'));
  signal em_price_c     : price_table_t;
  signal em_price_s     : price_table_t := (others => (others => '0'));
  signal ex_price_c     : price_table_t;
  signal ex_price_s     : price_table_t := (others => (others => '0'));
  
  signal node_sel_c     : unsigned(c_NODE_WIDTH-1 downto 0);
  signal node_sel_s     : unsigned(c_NODE_WIDTH-1 downto 0) := (others => '0');

begin

  process(CLK, RST) begin
    if(RST = '1') then
      fsm_s          <= idle;
      start_day_s    <= '0';
      sel_cell_col_s <= to_unsigned(c_MIN_COL, 3);
      sel_cell_row_s <= (others => '0');
      amount_s       <= (others => (others => (others => '0')));
      st_price_s     <= (others => (others => '0'));
      em_price_s     <= (others => (others => '0'));
      ex_price_s     <= (others => (others => '0'));
    elsif(rising_edge(CLK)) then
      fsm_s          <= fsm_c;
      start_day_s    <= start_day_c;
      sel_cell_col_s <= sel_cell_col_c;
      sel_cell_row_s <= sel_cell_row_c;
      node_sel_s     <= node_sel_c;
      amount_s       <= amount_c;
      st_price_s     <= st_price_c;
      em_price_s     <= em_price_c;
      ex_price_s     <= ex_price_c;
    end if;
  end process;

  process(KEYS, fsm_s, start_day_s, sel_cell_col_s, sel_cell_row_s, node_sel_s) begin
    fsm_c          <= fsm_s;
    start_day_c    <= '0';
    sel_cell_col_c <= sel_cell_col_s;
    sel_cell_row_c <= sel_cell_row_s;
    node_sel_c     <= node_sel_s;
    amount_c       <= amount_s;
    st_price_c     <= st_price_s;
    em_price_c     <= em_price_s;
    ex_price_c     <= ex_price_s;
    
    case(fsm_s) is
      when idle =>
          if(KEYS.up = '1') then
            if(sel_cell_row_s /= 0) then
              sel_cell_row_c <= sel_cell_row_s - 1;
            end if;
          elsif(KEYS.down = '1') then
            if(sel_cell_row_s /= to_unsigned(c_MAX_ROW, 6)) then
              if((sel_cell_row_s /= (to_unsigned(c_MAX_ROW, 6) - 1)) or
                  sel_cell_col_s = to_unsigned(c_MAX_COL, 3)         or -- next day btn
                  sel_cell_col_s = (to_unsigned(c_MAX_COL, 3) - 1)      -- next node btn
              )then
                sel_cell_row_c <= sel_cell_row_s + 1;
              end if;
            end if;
          elsif(KEYS.left = '1') then
            if(sel_cell_col_s /= c_MIN_COL) then
              sel_cell_col_c <= sel_cell_col_s - 1;
            end if;
          elsif(KEYS.right = '1') then
            if(sel_cell_col_s /= to_unsigned(c_MAX_COL, 3)) then
              sel_cell_col_c <= sel_cell_col_s + 1;
            end if;
          elsif(KEYS.enter = '1') then
            if(EDIT_ENA = '1') then
              if((sel_cell_col_s = to_unsigned(c_MAX_COL, 3)) and (sel_cell_row_s = to_unsigned(c_MAX_ROW, 6))) then
                start_day_c <= '1';
              elsif((sel_cell_col_s = (to_unsigned(c_MAX_COL, 3) - 1)) and (sel_cell_row_s = to_unsigned(c_MAX_ROW, 6))) then
                if(node_sel_s /= g_CLIENTS_CNT) then
                  node_sel_c <= node_sel_s + 1;
                else
                  node_sel_c <= 0;
                end if;
              elsif((node_sel_s = 0) or (sel_cell_col_s < 3)) then -- prices can be changed only from server page
                fsm_c <= cell_rst;
              end if;
            end if;
          end if;
      when cell_rst =>
        if(sel_cell_col_s = 1) then -- character buffer
        -- reset character buffer
        elsif(sel_cell_col_s = 2) then -- amount
          amount_c(node_sel_s, sel_cell_row_s) <= (others => '0');
        elsif(sel_cell_col_s = 3) then -- student price
          st_price_c(sel_cell_row_s) <= (others => '0');
        elsif(sel_cell_col_s = 4) then -- employee price
          em_price_c(sel_cell_row_s) <= (others => '0');
        elsif(sel_cell_col_s = 5) then -- external price
          ex_price_c(sel_cell_row_s) <= (others => '0');
        end if;
        fsm_c <= edit;
      when edit =>
        
    end case;
  end process;

end Behavioral;
