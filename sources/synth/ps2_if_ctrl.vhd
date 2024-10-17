----------------------------------------------------------------------------------
-- ps2_if_ctrl.vhd
-- Process signals from PS2_top into registers.
-- 14 Oct, 2024
-- Semestral project in the autumn semester of 2024 in MPC-NDO.
-- Artem Gumenyuk (xgumen00@vutbr.cz)
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.ps2_pkg.all;
use work.server_pkg.all;
use IEEE.NUMERIC_STD.ALL;
use IEEE.math_real.all;
--use IEEE.Std_Logic_Arith.ALL;

entity ps2_if_ctrl is
    Generic (
           g_FOOD_CNT     : positive;
           g_CLIENTS_CNT  : positive;
           g_NODE_WIDTH   : positive
    );
    Port ( CLK          : in STD_LOGIC;
           RST          : in STD_LOGIC;
           EDIT_ENA     : in STD_LOGIC;
           KEYS         : in t_keys;
           NUMBER       : in STD_LOGIC_VECTOR(3 downto 0);
           PS2_CODE     : in STD_LOGIC_VECTOR (7 downto 0);
           START_DAY    : out STD_LOGIC;
           BUFF_RDY     : out STD_LOGIC;
           NODE_SEL     : out STD_LOGIC_VECTOR(g_NODE_WIDTH downto 0);
           SEL_CELL_COL : out STD_LOGIC_VECTOR (2 downto 0);
           SEL_CELL_ROW : out STD_LOGIC_VECTOR (5 downto 0);
           CHAR_BUFF    : out char_buff_t;
           AMOUNT       : out amount_table_t;
           ST_PRICE     : out price_table_t;
           EM_PRICE     : out price_table_t;
           EX_PRICE     : out price_table_t
           );
end ps2_if_ctrl;

architecture Behavioral of ps2_if_ctrl is

  type t_fsm_ps2_ctrl is (idle, cell_rst, edit);
  
  
  constant c_MAX_ROW    : integer := 32;
  constant c_MIN_COL    : integer := 1;
  constant c_MAX_COL    : integer := 5;
--  constant c_NODE_WIDTH : integer := integer(ceil(log2(real(g_CLIENTS_CNT))));
  
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
  
  signal node_sel_c     : unsigned(g_NODE_WIDTH downto 0);
  signal node_sel_s     : unsigned(g_NODE_WIDTH downto 0) := (others => '0');
  
  signal char_buff_c    : char_buff_t;
  signal char_buff_s    : char_buff_t := (others => (others => '0'));
  
  signal char_sel_c     : unsigned(5 downto 0);
  signal char_sel_s     : unsigned(5 downto 0) := (others => '0');
  
  signal old_number_c   : unsigned(11 downto 0);
  signal new_number_c   : unsigned(15 downto 0);
  signal prev_number_c  : unsigned(11 downto 0);
  
  signal buff_rdy_c     : std_logic;
  signal buff_rdy_s     : std_logic := '0';

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
      char_buff_s    <= (others => (others => '0'));
      char_sel_s     <= (others => '0');
      buff_rdy_s     <= '0';
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
      char_buff_s    <= char_buff_c;
      char_sel_s     <= char_sel_c;
      buff_rdy_s     <= buff_rdy_c;
    end if;
  end process;

  process(KEYS, fsm_s, start_day_s, sel_cell_col_s, sel_cell_row_s,
          node_sel_s, amount_s, st_price_s, em_price_s, ex_price_s,
          EDIT_ENA, new_number_c, char_sel_s, char_buff_s, buff_rdy_s)
  begin
    fsm_c          <= fsm_s;
    start_day_c    <= '0';
    sel_cell_col_c <= sel_cell_col_s;
    sel_cell_row_c <= sel_cell_row_s;
    node_sel_c     <= node_sel_s;
    amount_c       <= amount_s;
    st_price_c     <= st_price_s;
    em_price_c     <= em_price_s;
    ex_price_c     <= ex_price_s;
    char_buff_c    <= char_buff_s;
    char_sel_c     <= char_sel_s;
    buff_rdy_c     <= buff_rdy_s;
    
    case(fsm_s) is
      when idle =>
          buff_rdy_c     <= '0';
          
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
            if((sel_cell_col_s /= c_MIN_COL) and not((sel_cell_col_s = 4) and sel_cell_row_s = to_unsigned(c_MAX_ROW, 6))) then
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
                  node_sel_c <= TO_UNSIGNED(0, (g_NODE_WIDTH + 1));
                end if;
              elsif((node_sel_s = 0) or (sel_cell_col_s = 2)) then -- prices and dishes can be changed only from server page
                fsm_c <= cell_rst;
              end if;
            end if;
          end if;
      when cell_rst =>
        if(sel_cell_col_s = 1) then -- character buffer
          char_buff_c <= (others => (others => '0'));
          char_sel_c  <= (others => '0');
        elsif(sel_cell_col_s = 2) then -- amount
          amount_c(TO_INTEGER(node_sel_s), TO_INTEGER(sel_cell_row_s)) <= (others => '0');
        elsif(sel_cell_col_s = 3) then -- student price
          st_price_c(TO_INTEGER(sel_cell_row_s)) <= (others => '0');
        elsif(sel_cell_col_s = 4) then -- employee price
          em_price_c(TO_INTEGER(sel_cell_row_s)) <= (others => '0');
        elsif(sel_cell_col_s = 5) then -- external price
          ex_price_c(TO_INTEGER(sel_cell_row_s)) <= (others => '0');
        end if;
        fsm_c <= edit;
      when edit =>
        if(KEYS.enter = '1') then -- enter
          fsm_c <= idle;
          if(sel_cell_col_s = 1) then
            buff_rdy_c <= '1';
          end if;
        elsif(KEYS.up = '1') then -- up
          fsm_c <= idle;
          if(sel_cell_row_s /= 0) then
            sel_cell_row_c <= sel_cell_row_s - 1;
          end if;
          if(sel_cell_col_s = 1) then
            buff_rdy_c <= '1';
          end if;
        elsif(KEYS.down = '1') then -- down
          fsm_c <= idle;
          if(sel_cell_row_s /= to_unsigned(c_MAX_ROW, 6)) then
            if((sel_cell_row_s /= (to_unsigned(c_MAX_ROW, 6) - 1)) or
                sel_cell_col_s = to_unsigned(c_MAX_COL, 3)         or -- next day btn
                sel_cell_col_s = (to_unsigned(c_MAX_COL, 3) - 1)      -- next node btn
            )then
              sel_cell_row_c <= sel_cell_row_s + 1;
            end if;
          end if;
          if(sel_cell_col_s = 1) then
            buff_rdy_c <= '1';
          end if;
        elsif(KEYS.left = '1') then -- left
          fsm_c <= idle;
          if(sel_cell_col_s /= c_MIN_COL) then
            sel_cell_col_c <= sel_cell_col_s - 1;
          end if;
          if(sel_cell_col_s = 1) then
            buff_rdy_c <= '1';
          end if;
        elsif(KEYS.right = '1') then -- right
          fsm_c <= idle;
          if(sel_cell_col_s /= to_unsigned(c_MAX_COL, 3)) then
            sel_cell_col_c <= sel_cell_col_s + 1;
          end if;
          if(sel_cell_col_s = 1) then
            buff_rdy_c <= '1';
          end if;
        elsif(KEYS.esc = '1') then -- esc
          fsm_c <= idle;
          if(sel_cell_col_s = 1) then
            buff_rdy_c <= '1';
          end if;
        elsif(KEYS.bckspc = '1') then -- backspace
          if((sel_cell_col_s = 1) and (char_sel_s /= 0)) then -- character buffer
            char_buff_c(TO_INTEGER((char_sel_s - 1))) <= (others => '0');
            char_sel_c <= char_sel_s - 1;
          elsif(sel_cell_col_s = 2) then -- amount
            amount_c(TO_INTEGER(node_sel_s), TO_INTEGER(sel_cell_row_s)) <= std_logic_vector(prev_number_c);
          elsif(sel_cell_col_s = 3) then -- student price
            st_price_c(TO_INTEGER(sel_cell_row_s)) <= std_logic_vector(prev_number_c(7 downto 0));
          elsif(sel_cell_col_s = 4) then -- employee price
            em_price_c(TO_INTEGER(sel_cell_row_s)) <= std_logic_vector(prev_number_c(7 downto 0));
          elsif(sel_cell_col_s = 5) then -- external price
            ex_price_c(TO_INTEGER(sel_cell_row_s)) <= std_logic_vector(prev_number_c(7 downto 0));
          end if;
        elsif((KEYS.char = '1') and (sel_cell_col_s = 1) and (char_sel_s /= 32)) then -- char
          char_buff_c(TO_INTEGER(char_sel_s)) <= PS2_CODE;
          char_sel_c <= char_sel_s + 1;
        elsif((KEYS.number = '1') and (sel_cell_col_s /= 1)) then -- number
          if((sel_cell_col_s = 2) and (new_number_c(15 downto 12) = 0)) then -- amount
            amount_c(TO_INTEGER(node_sel_s), TO_INTEGER(sel_cell_row_s)) <= std_logic_vector(new_number_c(11 downto 0));
          elsif((sel_cell_col_s = 3) and (new_number_c(15 downto 8) = 0)) then -- student price
            st_price_c(TO_INTEGER(sel_cell_row_s)) <= std_logic_vector(new_number_c(7 downto 0));
          elsif((sel_cell_col_s = 4) and (new_number_c(15 downto 8) = 0)) then -- employee price
            em_price_c(TO_INTEGER(sel_cell_row_s)) <= std_logic_vector(new_number_c(7 downto 0));
          elsif((sel_cell_col_s = 5) and (new_number_c(15 downto 8) = 0)) then -- external price
            ex_price_c(TO_INTEGER(sel_cell_row_s)) <= std_logic_vector(new_number_c(7 downto 0));
          end if;
        end if;
    end case;
  end process;
  
  -- MUX
  process(sel_cell_col_s, node_sel_s, sel_cell_row_s, amount_s, st_price_s, em_price_s, ex_price_s) begin
    if(sel_cell_col_s = 2) then
      old_number_c <= UNSIGNED(amount_s(TO_INTEGER(node_sel_s), TO_INTEGER(sel_cell_row_s)));
    elsif(sel_cell_col_s = 3) then
      old_number_c <= "0000" & UNSIGNED(st_price_s(TO_INTEGER(sel_cell_row_s)));
    elsif((sel_cell_col_s = 4) and (sel_cell_row_s /= c_MAX_ROW)) then
      old_number_c <= "0000" & UNSIGNED(em_price_s(TO_INTEGER(sel_cell_row_s)));
    elsif((sel_cell_col_s = 5) and (sel_cell_row_s /= c_MAX_ROW)) then
      old_number_c <= "0000" & UNSIGNED(ex_price_s(TO_INTEGER(sel_cell_row_s)));
    end if;
  end process;
  -- calculate summ of prev value and new number in dec format
  new_number_c <= resize((old_number_c * 10), 16) + resize(UNSIGNED(NUMBER), 16);
  
  -- calculate number without last added digit
  prev_number_c <= (old_number_c - (old_number_c rem 10)) / 10;
  
  -- output assignments
  START_DAY    <= start_day_s;
  BUFF_RDY     <= buff_rdy_s;
  NODE_SEL     <= std_logic_vector(node_sel_s);
  SEL_CELL_COL <= std_logic_vector(sel_cell_col_s);
  SEL_CELL_ROW <= std_logic_vector(sel_cell_row_s);
  CHAR_BUFF    <= char_buff_s;
  AMOUNT       <= amount_s;
  ST_PRICE     <= st_price_s;
  EM_PRICE     <= em_price_s;
  EX_PRICE     <= ex_price_s;

end Behavioral;
