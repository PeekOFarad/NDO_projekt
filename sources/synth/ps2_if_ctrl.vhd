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

entity ps2_if_ctrl is
    Generic (
           g_FOOD_CNT     : positive;
           g_CLIENTS_CNT  : positive;
           g_NODE_WIDTH   : positive
    );
    Port ( 
           CLK          : in STD_LOGIC;
           RST          : in STD_LOGIC;
           EDIT_ENA     : in STD_LOGIC;
           KEYS         : in t_keys;
           NUMBER       : in STD_LOGIC_VECTOR(3 downto 0);
           PS2_CODE     : in STD_LOGIC_VECTOR (7 downto 0);
           START_DAY    : out STD_LOGIC;
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
end ps2_if_ctrl;

architecture Behavioral of ps2_if_ctrl is

  type t_fsm_ps2_ctrl is (idle, cell_rst, edit, wait4ack);
  
  constant c_MIN_COL    : integer := 0;
  constant c_MAX_COL    : integer := 4;
  
  signal fsm_c          : t_fsm_ps2_ctrl;
  signal fsm_s          : t_fsm_ps2_ctrl := idle;
  signal start_day_c    : std_logic;
  signal start_day_s    : std_logic := '0';
  signal sel_cell_col_c : unsigned(2 downto 0);
  signal sel_cell_col_s : unsigned(2 downto 0) := to_unsigned(c_MIN_COL, 3);
  signal sel_cell_row_c : unsigned(5 downto 0);
  signal sel_cell_row_s : unsigned(5 downto 0) := (others => '0');
  
  signal node_sel_c     : unsigned(g_NODE_WIDTH-1 downto 0);
  signal node_sel_s     : unsigned(g_NODE_WIDTH-1 downto 0) := (others => '0');
  
  signal char_buff_c    : char_buff_t;
  signal char_buff_s    : char_buff_t := (others => (others => '0'));
  
  signal char_sel_c     : unsigned(5 downto 0);
  signal char_sel_s     : unsigned(5 downto 0) := (others => '0');
  
  signal numb_buff_c   : unsigned(11 downto 0);
  signal numb_buff_s   : unsigned(11 downto 0) := (others => '0');

  signal new_number_c   : unsigned(15 downto 0);
  
  signal buff_rdy_c     : std_logic;
  signal buff_rdy_s     : std_logic := '0';
  
  signal upd_arr_c     : std_logic;
  signal upd_arr_s     : std_logic := '0';
  
  signal upd_data_c     : std_logic;
  signal upd_data_s     : std_logic := '0';

begin

  process(CLK, RST) begin
    if(RST = '1') then
      fsm_s          <= idle;
      start_day_s    <= '0';
      sel_cell_col_s <= to_unsigned(c_MIN_COL, 3);
      sel_cell_row_s <= (others => '0');
      char_buff_s    <= (others => (others => '0'));
      char_sel_s     <= (others => '0');
      buff_rdy_s     <= '0';
      upd_arr_s      <= '0';
      upd_data_s     <= '0';
      numb_buff_s    <= (others => '0');
    elsif(rising_edge(CLK)) then
      fsm_s          <= fsm_c;
      start_day_s    <= start_day_c;
      sel_cell_col_s <= sel_cell_col_c;
      sel_cell_row_s <= sel_cell_row_c;
      node_sel_s     <= node_sel_c;
      char_buff_s    <= char_buff_c;
      char_sel_s     <= char_sel_c;
      buff_rdy_s     <= buff_rdy_c;
      upd_arr_s      <= upd_arr_c;
      upd_data_s     <= upd_data_c;
      numb_buff_s    <= numb_buff_c;
    end if;
  end process;

  process(KEYS, fsm_s, start_day_s, sel_cell_col_s, sel_cell_row_s,
          node_sel_s, EDIT_ENA, char_sel_s, char_buff_s, buff_rdy_s,
          upd_arr_s, upd_data_s, ACK, numb_buff_s, new_number_c, PS2_CODE)
  begin
    fsm_c          <= fsm_s;
    start_day_c    <= '0';
    sel_cell_col_c <= sel_cell_col_s;
    sel_cell_row_c <= sel_cell_row_s;
    node_sel_c     <= node_sel_s;
    char_buff_c    <= char_buff_s;
    char_sel_c     <= char_sel_s;
    buff_rdy_c     <= buff_rdy_s;
    upd_arr_c      <= '0';
    upd_data_c     <= '0';
    RW             <= '1'; -- read
    REQ            <= '0';
    numb_buff_c    <= numb_buff_s;
    
    case(fsm_s) is
      when idle =>
          buff_rdy_c     <= '0';
          
          if(KEYS.up = '1') then
            if(sel_cell_row_s /= 0) then
              sel_cell_row_c <= sel_cell_row_s - 1;
              upd_arr_c      <= '1';
            end if;
          elsif(KEYS.down = '1') then
            if(sel_cell_row_s /= to_unsigned(g_FOOD_CNT, 6)) then
              if((sel_cell_row_s /= (to_unsigned(g_FOOD_CNT, 6) - 1)) or
                  sel_cell_col_s = to_unsigned(c_MAX_COL, 3)         or -- next day btn
                  sel_cell_col_s = (to_unsigned(c_MAX_COL, 3) - 1)      -- next node btn
              )then
                sel_cell_row_c <= sel_cell_row_s + 1;
                upd_arr_c      <= '1';
              end if;
            end if;
          elsif(KEYS.left = '1') then
            if((sel_cell_col_s /= c_MIN_COL) and not((sel_cell_col_s = 3) and sel_cell_row_s = to_unsigned(g_FOOD_CNT, 6))) then
              sel_cell_col_c <= sel_cell_col_s - 1;
              upd_arr_c      <= '1';
            end if;
          elsif(KEYS.right = '1') then
            if(sel_cell_col_s /= to_unsigned(c_MAX_COL, 3)) then
              sel_cell_col_c <= sel_cell_col_s + 1;
              upd_arr_c      <= '1';
            end if;
          elsif(KEYS.enter = '1') then
            if(EDIT_ENA = '1') then
              if((sel_cell_col_s = to_unsigned(c_MAX_COL, 3)) and (sel_cell_row_s = to_unsigned(g_FOOD_CNT, 6))) then
                start_day_c <= '1';
              elsif((sel_cell_col_s = (to_unsigned(c_MAX_COL, 3) - 1)) and (sel_cell_row_s = to_unsigned(g_FOOD_CNT, 6))) then
                if(node_sel_s /= g_CLIENTS_CNT) then
                  node_sel_c <= node_sel_s + 1;
                else
                  node_sel_c <= TO_UNSIGNED(0, g_NODE_WIDTH);
                end if;
              elsif((node_sel_s = 0) or (sel_cell_col_s = 1)) then -- prices and dishes can be changed only from server page
                fsm_c <= cell_rst;
              end if;
            end if;
          end if;
      when cell_rst =>
        char_buff_c <= (others => (others => '0'));
        char_sel_c  <= (others => '0');
        upd_data_c  <= '1';
        numb_buff_c <= (others => '0');
        fsm_c       <= edit;
      when edit =>
        upd_data_c <= '0';
        upd_arr_c  <= '0';
      
        if((KEYS.enter = '1') or (KEYS.esc = '1')) then -- enter or esc
          if(sel_cell_col_s = 0) then
            buff_rdy_c <= '1';
          end if;
          fsm_c <= idle;
        elsif(KEYS.up = '1') then -- up
          if(sel_cell_row_s /= 0) then
            sel_cell_row_c <= sel_cell_row_s - 1;
            upd_arr_c      <= '1';
          end if;
          if(sel_cell_col_s = 0) then
            buff_rdy_c <= '1';
          end if;
          fsm_c <= idle;
        elsif(KEYS.down = '1') then -- down
          if(sel_cell_row_s /= to_unsigned(g_FOOD_CNT, 6)) then
            if((sel_cell_row_s /= (to_unsigned(g_FOOD_CNT, 6) - 1)) or
                sel_cell_col_s = to_unsigned(c_MAX_COL, 3)         or -- next day btn
                sel_cell_col_s = (to_unsigned(c_MAX_COL, 3) - 1)      -- next node btn
            )then
              sel_cell_row_c <= sel_cell_row_s + 1;
              upd_arr_c      <= '1';
            end if;
          end if;
          if(sel_cell_col_s = 0) then
            buff_rdy_c <= '1';
          end if;
          fsm_c <= idle;
        elsif(KEYS.left = '1') then -- left
          if(sel_cell_col_s /= c_MIN_COL) then
            sel_cell_col_c <= sel_cell_col_s - 1;
            upd_arr_c      <= '1';
          end if;
          if(sel_cell_col_s = 0) then
            buff_rdy_c <= '1';
          end if;
          fsm_c <= idle;
        elsif(KEYS.right = '1') then -- right
          if(sel_cell_col_s /= to_unsigned(c_MAX_COL, 3)) then
            sel_cell_col_c <= sel_cell_col_s + 1;
            upd_arr_c      <= '1';
          end if;
          if(sel_cell_col_s = 0) then
            buff_rdy_c <= '1';
          end if;
          fsm_c <= idle;
        elsif(KEYS.bckspc = '1') then -- backspace
          if(sel_cell_col_s /= 0) then
            numb_buff_c <= (others => '0');
            RW    <= '0';
            fsm_c <= wait4ack;
          end if;

          if(char_sel_s /= 0) then -- character buffer
            char_buff_c(TO_INTEGER((char_sel_s - 1))) <= (others => '0');
            char_sel_c <= char_sel_s - 1;
            upd_data_c <= '1';
          end if;
        elsif((KEYS.number = '1') and (sel_cell_col_s /= 0)) then -- number
          numb_buff_c <= new_number_c(11 downto 0);
          RW    <= '0';
          fsm_c <= wait4ack;  
        end if;
        if(((KEYS.char = '1') or (KEYS.number = '1')) and (char_sel_s /= 31)) then -- char
          char_buff_c(TO_INTEGER(char_sel_s)) <= sprits_ROM(TO_INTEGER(UNSIGNED(PS2_CODE))); -- decode directly PS2 code to sprit number
          char_sel_c <= char_sel_s + 1;
          upd_data_c <= '1';
        end if;
      when wait4ack =>
        REQ <= '1';
        RW  <= '0';
        if(ACK = '1') then
          REQ     <= '0';
          fsm_c   <= edit;
        end if;
    end case;
  end process;
  
  -- calculate summ of prev value and new number in dec format
  new_number_c <= resize((UNSIGNED(numb_buff_s) * 10), 16) + resize(UNSIGNED(NUMBER), 16);
  
  -- output assignments
  START_DAY    <= start_day_s;
  BUFF_RDY     <= buff_rdy_s;
  UPD_ARR      <= upd_arr_s;
  UPD_DATA     <= upd_data_s;
  NODE_SEL     <= std_logic_vector(node_sel_s);
  SEL_CELL_COL <= std_logic_vector(sel_cell_col_s);
  SEL_CELL_ROW <= std_logic_vector(sel_cell_row_s);
  CHAR_BUFF    <= char_buff_s;

  DOUT         <= std_logic_vector(numb_buff_s);

end Behavioral;
