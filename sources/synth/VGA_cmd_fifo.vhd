----------------------------------------------------------------------------------
-- VGA_cmd_fifo.vhd
-- System to VGA driver fifo for printing characters
-- 11 Oct, 2024
-- Semestral project in the autumn semester of 2024 in MPC-NDO.
-- Matej Stepan (xstepa67@vutbr.cz)
----------------------------------------------------------------------------------
-- note: Addressable food table is 5x32 cells
-- prices are 3 character each
-- portion amount is 4 chars
-- food type is 9 chars
-- Food name is 32 chars
-- invert last updated cell (for user as cursor) and revert back when cell index changed

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.math_real.all;
use work.VGA_pkg.all;
use work.server_pkg.all;
use work.common_pkg.all;

entity VGA_cmd_fifo is
  Port ( 
    CLK         : in  std_logic;
    RST         : in  std_logic;
    -- System Interface
    COL_SYS     : in  STD_LOGIC_VECTOR (2 downto 0); --! Food table column
    ROW_SYS     : in  STD_LOGIC_VECTOR (5 downto 0); --! Food table row
    UPD_ARR     : in  STD_LOGIC; --! update cursor position -> shares col_sys and row_sys with upd_data
    UPD_DATA    : in  STD_LOGIC; --! update food table cell -> shares col_sys and row_sys with upd_arr
    DATA_SYS    : in  char_buff_t; -- food cell data -> Array of 32 8bit vector, each coresponding to a single char in the cell
    VGA_RDY     : out std_logic;
    -- SRAM signals
    FIFO_REN    : in  std_logic; -- TODO this "read enable" signal will need to be deasserted sooner than v_porch (12 clocks), because we want to always print whole sprites to SRAM
    RWADDR_C     : out std_logic_vector(17 downto 0);
    DATA_IO      : inout std_logic_vector(15 downto 0);
    OE_N_W      : out std_logic;
    WE_N_D2     : out std_logic;
    LB_N_W      : out std_logic;
    UB_N_W      : out std_logic
  );
end VGA_cmd_fifo;

architecture rtl of VGA_cmd_fifo is

  type t_cmd_fsm is (idle, update_arrow, update_data, wait_update_arrow, wait_update_data, read, write_inv);
  signal state              : t_cmd_fsm := idle;
  signal next_state         : t_cmd_fsm := idle;

  signal cnt_ROW_s          : unsigned(3 downto 0) := (others => '0');
  signal cnt_ROW_c          : unsigned(3 downto 0);
  signal cnt_ROW_max_d1     : std_logic := '0'; --! if cnt_ROW_s = 11 delayed by one clk -> for byte control signals

  signal sprite_base_addr_c : unsigned(9 downto 0);
  signal sprite_raddr_c     : unsigned(9 downto 0) := (others => '0');

  signal char_addr_c        : unsigned(17 downto 0);
  signal char_addr_s        : unsigned(17 downto 0) := (others => '0');

  signal ROM_data_o         : std_logic_vector(7 downto 0) := (others => '0');

  signal oe_n_c           : std_logic;
  signal ub_n_c           : std_logic;
  signal ub_n_s           : std_logic := '1';
  signal lb_n_c           : std_logic;
  signal lb_n_s           : std_logic := '1';

  signal we_n_d           : std_logic_vector(1 downto 0) := (others => '0');

  -- DATA INOUT
  signal data_out_c       : std_logic_vector(15 downto 0);
  signal data_in_c        : std_logic_vector(15 downto 0);

  -- cursor inversion
  signal cnt_inv_col_s    : unsigned(4 downto 0) := (others => '0');
  signal cnt_inv_col_c    : unsigned(4 downto 0) := (others => '0');
  signal cnt_inv_row_s    : unsigned(3 downto 0) := (others => '0');
  signal cnt_inv_row_c    : unsigned(3 downto 0) := (others => '0');
  signal raddr_c          : unsigned(15 downto 0) := (others => '0');



  -- shreg
  signal char_shreg_s         : t_char_shreg := (others => (others => 0));
  signal char_shreg_last      : t_char_shreg := (others => (others => 0));

  signal col_sys_int          : integer := 0;-- STD_LOGIC_VECTOR (2 downto 0) := (others => '0'); --! Food table column
  signal row_sys_int          : integer := 0;-- STD_LOGIC_VECTOR (5 downto 0) := (others => '0'); --! Food table column

  signal cursor_pos           : t_cursor_pos := (others => 0); 
  signal cursor_pos_shreg     : t_cursor_pos_array(0 to 1) := (others => (others => 0)); 


  signal cnt_char_shreg_s     : unsigned(4 downto 0) := (others => '0');
  signal cnt_char_shreg_c     : unsigned(4 downto 0) := (others => '0');

  signal char             : t_char := (column => 0, row => 0, id => 0);
  constant c_char_rst_val : t_char := (column => 0, row => 0, id => 0);

  signal cell_size        : integer  := 0;
  signal cell_size_last   : integer  := 0;
  signal cell_size_sel    : integer  := 0;
  signal column_dcdr      : integer  := 0;

  signal data_latch       : std_logic := '0';
  signal arrow_latch      : std_logic_vector(1 downto 0) := (others => '0');
  signal arrow_latch_fe   : std_logic := '0';
  signal cell_written     : boolean := false;


  --------------------------------------------------------------------------------
  -- DEBUG
  signal col_debug           : unsigned(c_COL_NUM_BIN-1 downto 0) := (others => '0');
  --------------------------------------------------------------------------------

  
begin

  DATA_IO  <=  data_out_c when true else data_in_c;
  
  data_out_c  <=  (others => 'Z') when state = read else
                  not(bit_reverse(ROM_data_o) & bit_reverse(ROM_data_o))
                    when (cursor_pos_shreg(0).column = col_sys_int and cursor_pos_shreg(0).row = row_sys_int)
                  else (bit_reverse(ROM_data_o) & bit_reverse(ROM_data_o));

  data_in_c   <= DATA_IO when state = read else x"beef";

  RWADDR_C <=  std_logic_vector(raddr_c) when state = read else std_logic_vector(char_addr_c);
  WE_N_D2 <= we_n_d(we_n_d'high) when state /= read else '1';
  LB_N_W  <= lb_n_s;
  UB_N_W  <= ub_n_s;
  VGA_RDY <= '1' when state = idle else '0';

  -- cursor type cast
  cursor_pos.column <= to_integer(unsigned(COL_SYS)); 
  cursor_pos.row    <= to_integer(unsigned(ROW_SYS)); 

  process (CLK)
  begin
    if rising_edge(CLK) then
      if RST = '1' then  -- TODO USE V_PORCH/WRITE ENBALE AS RESET?
        cnt_ROW_s         <= to_unsigned(0, cnt_ROW_s'length);--(others => '0');
        -- char_base_addr_s  <= (others => '0');
        ub_n_s            <= '1';
        lb_n_s            <= '1';
        we_n_d            <= (others => '0');
        cnt_ROW_max_d1    <= '0';
        char_addr_s       <= (others => '0');
        cnt_char_shreg_s  <= (others => '0');
        char_shreg_s      <= (others => (others => 0));
        col_sys_int       <= 0; -- (others => '0');
        row_sys_int       <= 0; -- (others => '0');
        cursor_pos_shreg  <=  ((1, 0),(1, 0));-- (others => (others => 0));
        --------------------------------------------------------------------------------
        -- SYSTEM INTERFACE
        state             <= idle;
        data_latch        <= '0';
        --------------------------------------------------------------------------------
      else
        --------------------------------------------------------------------------------
        -- SYSTEM INTERFACE
        state             <= next_state;

        -- data_latch        <= data_latch;
        -- if UPD_DATA = '1' or arrow_latch_fe = '1' then
        --   data_latch <= '1';
        -- elsif cell_written then
        --   data_latch <= '0';
        -- end if;

        -- if UPD_ARR = '1' then
        --   arrow_latch <= (others => '1');
        -- elsif cell_written then
        --   arrow_latch <= '0' & arrow_latch(arrow_latch'high);
        -- end if;


        
        --------------------------------------------------------------------------------

        char_addr_s       <= char_addr_c;
        -- we_n_d            <= not FIFO_REN & we_n_d(we_n_d'high downto we_n_d'low + 1);

        cnt_ROW_max_d1    <= '0';
        if cnt_ROW_s >= 11 and cnt_ROW_c >= 11 then
          cnt_ROW_max_d1    <= '1';
        end if;

        
        char_shreg_s      <= char_shreg_s;
        -- char_shreg_last   <= char_shreg_last;
        -- if FIFO_REN = '1' then
        --   cnt_ROW_s       <= cnt_ROW_c;
        --   if cnt_ROW_s = 11 and cnt_char_shreg_s /= cell_size_sel then
        --     char_shreg_s      <= char_shreg_s(char_shreg_s'low+1 to char_shreg_s'high) & c_char_rst_val;
        --     cnt_char_shreg_s  <= cnt_char_shreg_c;
        --   end if;
        -- end if;
        cnt_ROW_s         <= cnt_ROW_c;
        cnt_char_shreg_s  <= cnt_char_shreg_c;
        if cnt_ROW_s = 11 then -- and cnt_char_shreg_s /= cell_size_sel
          char_shreg_s      <= char_shreg_s(char_shreg_s'low+1 to char_shreg_s'high) & c_char_rst_val;
        end if;
        ---------------------------------------------------------------------------------

        if UPD_ARR = '1' then -- when cursor position is updated, shift cursor position in shreg + 1 and save new position to 0
          cursor_pos_shreg <= cursor_pos & cursor_pos_shreg(cursor_pos_shreg'low to cursor_pos_shreg'high - 1);
        end if;

        if UPD_DATA = '1' then
          cell_size_last          <=  cell_size;
        end if;

        -- if UPD_DATA = '1' or (UPD_ARR = '1' or arrow_latch_fe = '1') then
        if UPD_DATA = '1' then
          -- cnt_ROW_s               <= (others => '0'); --! reset counters
          -- cnt_char_shreg_s        <= (others => '0'); --! reset counters
          col_sys_int       <= to_integer(unsigned(COL_SYS));
          row_sys_int       <= to_integer(unsigned(ROW_SYS));
          for i in 0 to 31 loop
            char_shreg_s(i).column  <= i;
            char_shreg_s(i).row     <= to_integer(unsigned(ROW_SYS)) + 1;
            char_shreg_s(i).id      <= to_integer(unsigned(DATA_SYS(i)));
            -- if UPD_ARR = '1' then
            --   char_shreg_s(i).column      <= char_shreg_last(i).column;
            --   char_shreg_s(i).row         <= char_shreg_last(i).row;
            --   char_shreg_s(i).id          <= char_shreg_last(i).id;
            -- end if;
            -- -- save cell data of new cursor position
            -- char_shreg_last(i).column   <= column_dcdr + i;
            -- char_shreg_last(i).row      <= to_integer(unsigned(ROW_SYS)) + 1;
            -- char_shreg_last(i).id       <= to_integer(unsigned(DATA_SYS(i)));
          end loop;
        end if;

        if state /= update_data or cell_written then
          ub_n_s            <= '1';
          lb_n_s            <= '1';
        else
          ub_n_s            <= ub_n_c;
          lb_n_s            <= lb_n_c;
        end if;

      end if;
    end if;
  end process;

  -- cell_written <= true when (cnt_char_shreg_s >= cell_size_sel and cnt_ROW_max_d1 = '1') else false;
  cell_written <= true when (cnt_char_shreg_s = 0 and cnt_ROW_max_d1 = '1') else false;

  -- arrow_latch_fe <= '1' when (arrow_latch(arrow_latch'high) = '0' and arrow_latch(arrow_latch'low) = '1') else '0';

  char                <= char_shreg_s(char_shreg_s'low);
  --! char_id decoder
  sprite_base_addr_c  <= to_unsigned(char.ID*12, sprite_base_addr_c'length);
  sprite_raddr_c      <= sprite_base_addr_c + resize(cnt_ROW_s, sprite_raddr_c'length);


  p_SRAM_addr_dcdr: process(char.column, char.row, cnt_ROW_s, column_dcdr)
    variable char_col_addr    : unsigned(c_COL_NUM_BIN-1 downto 0) := (others => '0');
    variable column           : unsigned(c_COL_NUM_BIN-1 downto 0) := (others => '0');
    variable char_base_addr_c : unsigned(17 downto 0) := (others => '0');
  begin
    column            := to_unsigned(char.column + column_dcdr, c_COL_NUM_BIN);
    char_col_addr     := shift_right(column, 1); -- column address: two chars in one address -> divide column value in two to get adress of those 2 bytes
    char_base_addr_c  := resize(char_col_addr, char_base_addr_c'length) + to_unsigned(char.row*12*40, char_base_addr_c'length); -- scan to the row user wants to write to

    ub_n_c            <= not column(column'low);  -- if column odd, write to upper byte
    lb_n_c            <= column(column'low);      -- is column even, write to lower byte    
    char_addr_c       <= char_base_addr_c + resize(resize(cnt_ROW_s, char_addr_c'length)*40, char_addr_c'length); -- scan through the addresses for the char/segment
  
  end process;

  p_SRAM_raddr: process (cnt_inv_col_s, cnt_inv_row_s, cursor_pos_shreg)
  begin
    
  end process;


  p_cnt_ROW: process (cnt_ROW_s, cnt_char_shreg_s, cell_size_sel, state)
  begin
    cnt_ROW_c <= (others => '0');
    if state = update_data then 
      cnt_ROW_c <= cnt_ROW_s + 1;
      if cnt_ROW_s >= 11 then
        cnt_ROW_c <= (others => '0');
        if cnt_char_shreg_s >= cell_size_sel then
          cnt_ROW_c <= cnt_ROW_s;
        end if;
      end if;
    end if;
  end process;

  process (cnt_char_shreg_s, cell_size_sel, cnt_ROW_s, state)
  begin
    cnt_char_shreg_c <= (others => '0');
    if state = update_data then
      cnt_char_shreg_c <= cnt_char_shreg_s;
      if cnt_ROW_s = 11 then 
        cnt_char_shreg_c <= cnt_char_shreg_s + 1;
        if cnt_char_shreg_s >= cell_size_sel then
          cnt_char_shreg_c <= (others => '0');
        end if;
      end if;
    end if;
  end process;


  process (cnt_inv_col_s, state)
  begin
    
    
  end process;
  --------------------------------------------------------------------------------
  -- SYSTEM INTERFACE
  p_cmd_fsm: process (state, FIFO_REN, UPD_ARR, UPD_DATA, cell_written)
  begin
    next_state <= idle;

    oe_n_c <= '1';
    case state is
      --------------------------------------------------------------------------------
      when idle =>
        if UPD_ARR = '1' then 
          next_state <= update_arrow;
          if FIFO_REN = '0' then 
            next_state <= wait_update_arrow;
          end if;
        elsif UPD_DATA = '1' then 
          next_state <= update_data;
          if FIFO_REN = '0' then 
            next_state <= wait_update_data;
          end if;
        end if;

      --------------------------------------------------------------------------------
      when wait_update_arrow =>
        next_state <= wait_update_arrow;
        if FIFO_REN = '1' then 
          next_state <= read;
        end if;
        
      --------------------------------------------------------------------------------
      when read =>
        oe_n_c <= '0';
        -- inv counters are enabled by this state
        
      
      --------------------------------------------------------------------------------
      when wait_update_data =>
      next_state <= wait_update_data;
      if FIFO_REN = '1' then 
        next_state <= update_data;
      end if;

      --------------------------------------------------------------------------------
      when update_data  =>
        next_state <= update_data;
        if cell_written then
          next_state <= idle;
        end if;
        
    
      when others =>
        null;
    end case;
    
  end process;

  cell_size_sel <=  cell_size;  --cell_size_last when arrow_latch(arrow_latch'low) = '1' else
                                --cell_size;

  --! COL_SYS decoder
  cell_size <=  31  when col_sys_int = 0 else
                3   when col_sys_int = 1 else
                2   when col_sys_int > 1 and col_sys_int <= 4 else
                0 ;

  column_dcdr <=  10 when col_sys_int = 0 else
                  43 when col_sys_int = 1 else
                  48 when col_sys_int = 2 else
                  52 when col_sys_int = 3 else
                  56 when col_sys_int = 4 else
                  0;

  --------------------------------------------------------------------------------
  

  fontROM_8x12_inst : entity work.fontROM_8x12
  generic map (
    addrWidth => 10,
    dataWidth => 8
  )
  port map (
    clkA      => CLK,
    addrA     => std_logic_vector(sprite_raddr_c),
    dataOutA  => ROM_data_o
  );

  
end rtl;
