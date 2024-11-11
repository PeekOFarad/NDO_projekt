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

entity VGA_cmd_fifo is
  Port ( 
    CLK         : in  std_logic;
    RST         : in  std_logic;
    -- System Interface
    COL_SYS     : in  STD_LOGIC_VECTOR (2 downto 0); --! Food table column
    ROW_SYS     : in  STD_LOGIC_VECTOR (5 downto 0); --! Food table row
    UPD_ARR     : in  STD_LOGIC; --! update cursor position -> shares col_sys and row_sys with upd_data
    UPD_DATA    : in  STD_LOGIC; --! update food table cell -> shares col_sys and row_sys with upd_arr
    DATA_SYS    : in  sprit_buff_t; -- food cell data -> Array of 32 8bit vector, each coresponding to a single char in the cell
    -- SRAM signals
    FIFO_REN    : in  std_logic; -- TODO this "read enable" signal will need to be deasserted sooner than v_porch (12 clocks), because we want to always print whole sprites to SRAM
    WADDR_C     : out std_logic_vector(17 downto 0);
    DATA_O      : out std_logic_vector(15 downto 0);
    WE_N_D2     : out std_logic;
    LB_N_W      : out std_logic;
    UB_N_W      : out std_logic
  );
end VGA_cmd_fifo;

architecture rtl of VGA_cmd_fifo is

  type t_cmd_fsm is (idle, update_arrow, update_data);
  signal state              : t_cmd_fsm := idle;
  signal next_state         : t_cmd_fsm := idle;

  signal cnt_ROW_s          : unsigned(3 downto 0) := (others => '0');
  signal cnt_ROW_c          : unsigned(3 downto 0);
  signal cnt_ROW_max_d1     : std_logic := '0'; --! if cnt_ROW_s = 11 delayed by one clk -> for byte control signals

  signal sprite_base_addr_c : unsigned(9 downto 0);
  signal sprite_base_addr_s : unsigned(9 downto 0) := (others => '0');
  signal sprite_raddr_c     : unsigned(9 downto 0) := (others => '0');

  -- signal char_base_addr_c     : unsigned(17 downto 0) := (others => '0');
  -- signal char_base_addr_s     : unsigned(17 downto 0) := (others => '0');
  signal char_addr_c        : unsigned(17 downto 0);
  signal char_addr_s        : unsigned(17 downto 0) := (others => '0');

  signal ROM_data_o         : std_logic_vector(7 downto 0) := (others => '0');

  signal ub_n_c           : std_logic;
  signal ub_n_s           : std_logic := '1';
  signal lb_n_c           : std_logic;
  signal lb_n_s           : std_logic := '1';

  signal we_n_d           : std_logic_vector(1 downto 0) := (others => '0');

  -- shreg
  signal char_shreg_s         : t_char_fifo := (  others => (others => 0));
  --   (column => 74, row => 39, id => 49),
  --   (column => 75, row => 39, id => 62),
  --   (column => 76, row => 39, id => 62),
  --   (column => 77, row => 39, id => 49),
  --   (column => 78, row => 39, id => 48),
  --   (column => 79, row => 39, id => 66),
  --   (column => 79, row => 39, id => 2)
  -- );
  signal char_shreg_c         : t_char_fifo := (others => (others => 0));

  signal cnt_char_shreg_s     : unsigned(4 downto 0) := (others => '0');
  signal cnt_char_shreg_c     : unsigned(4 downto 0) := (others => '0');

  signal char             : t_char := (column => 0, row => 0, id => 0);
  constant c_char_rst_val : t_char := (column => 0, row => 0, id => 0);


  -- char addr decoder
  -- signal char_col_addr  : unsigned(c_COL_NUM_BIN-1 downto 0) := (others => '0');
  -- signal column         : unsigned(c_COL_NUM_BIN-1 downto 0) := (others => '0');

  signal cell_size        : integer  := 0;
  signal column_dcdr      : integer  := 0;
  -- signal row_dcdr         : integer  := 0;

  
begin

  DATA_O  <= bit_reverse(ROM_data_o) & bit_reverse(ROM_data_o);
  WADDR_C <= std_logic_vector(char_addr_c); --note did _c to check timing -> this is the correct timing
  WE_N_D2 <= we_n_d(we_n_d'high);
  LB_N_W  <= lb_n_s;
  UB_N_W  <= ub_n_s;

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
        --------------------------------------------------------------------------------
        -- SYSTEM INTERFACE
        state             <= idle;
        --------------------------------------------------------------------------------
      else
        --------------------------------------------------------------------------------
        -- SYSTEM INTERFACE
        state             <= next_state;
        --------------------------------------------------------------------------------

        char_addr_s       <= char_addr_c;
        we_n_d            <= not FIFO_REN & we_n_d(we_n_d'high downto we_n_d'low + 1);

        cnt_ROW_max_d1    <= '0';
        if cnt_ROW_s >= 11 and cnt_ROW_c >= 11 then
          cnt_ROW_max_d1    <= '1';
        end if;

        
        
        if FIFO_REN = '1' then
          cnt_ROW_s       <= cnt_ROW_c;
          if cnt_ROW_s = 11 and cnt_char_shreg_s /= cell_size then
            char_shreg_s      <= char_shreg_s(char_shreg_s'low+1 to char_shreg_s'high) & c_char_rst_val;
            cnt_char_shreg_s  <= cnt_char_shreg_c;
          end if;
        end if;

        if UPD_DATA = '1' and (ub_n_s and lb_n_s) = '1' then
          for i in 0 to 31 loop
            cnt_ROW_s               <= (others => '0'); --! reset counters
            cnt_char_shreg_s        <= (others => '0'); --! reset counters
            char_shreg_s(i).column  <= column_dcdr + i;
            char_shreg_s(i).row     <= to_integer(unsigned(ROW_SYS)) + 1;
            char_shreg_s(i).id      <= to_integer(unsigned(DATA_SYS(i)));
          end loop;
        end if;

        if cnt_char_shreg_s >= cell_size and cnt_ROW_max_d1 = '1' then
          ub_n_s            <= '1';
          lb_n_s            <= '1';
        else
          ub_n_s            <= ub_n_c;
          lb_n_s            <= lb_n_c;
        end if;

      end if;
    end if;
  end process;


  char                <= char_shreg_s(char_shreg_s'low);
  --! char_id decoder
  sprite_base_addr_c  <= to_unsigned(char.ID*12, sprite_base_addr_c'length);
  sprite_raddr_c      <= sprite_base_addr_c + resize(cnt_ROW_s, sprite_raddr_c'length);


  p_SRAM_addr_dcdr: process(char.column, char.row, cnt_ROW_s)
    variable char_col_addr    : unsigned(c_COL_NUM_BIN-1 downto 0) := (others => '0');
    variable column           : unsigned(c_COL_NUM_BIN-1 downto 0) := (others => '0');
    variable char_base_addr_c : unsigned(17 downto 0) := (others => '0');
  begin
    column            := to_unsigned(char.column, c_COL_NUM_BIN);
    char_col_addr     := shift_right(column, 1); -- column address: two chars in one address -> divide column value in two to get adress of those 2 bytes
    char_base_addr_c  := resize(char_col_addr, char_base_addr_c'length) + to_unsigned(char.row*12*40, char_base_addr_c'length); -- scan to the row user wants to write to

    ub_n_c            <= not column(column'low);  -- if column odd, write to upper byte
    lb_n_c            <= column(column'low);      -- is column even, write to lower byte    
    char_addr_c       <= char_base_addr_c + resize(resize(cnt_ROW_s, char_addr_c'length)*40, char_addr_c'length); -- scan through the addresses for the char/segment
  
  end process;


  p_cnt_ROW: process (cnt_ROW_s, cnt_char_shreg_s, cell_size)
  begin
    cnt_ROW_c <= cnt_ROW_s + 1;
    if cnt_ROW_s >= 11 then
      cnt_ROW_c <= (others => '0');
      if cnt_char_shreg_s >= cell_size then
        cnt_ROW_c <= cnt_ROW_s;
      end if;
    end if;
  end process;



  process (cnt_char_shreg_s, cell_size)
  begin
    cnt_char_shreg_c <= cnt_char_shreg_s + 1;
    if cnt_char_shreg_s >= cell_size then
      cnt_char_shreg_c <= (others => '0');
    end if;
  end process;
  --------------------------------------------------------------------------------
  -- SYSTEM INTERFACE
  p_cmd_fsm: process (state, UPD_ARR, UPD_DATA, cnt_char_shreg_s)
  begin
    next_state <= idle;

    case state is
      when idle =>

        if UPD_ARR = '1' then 
          next_state <= update_arrow;
        elsif FIFO_REN = '1' then 
          next_state <= update_data;
        end if;

      when update_arrow =>
        if cnt_char_shreg_s >= 31 then
          next_state <= idle;
        end if;
      
      when update_data  =>
        next_state <= update_data;

        if FIFO_REN = '0' then
          next_state <= idle;
        end if;
        
    
      when others =>
        null;
    end case;
    
  end process;

  --! COL_SYS decoder
  cell_size <=  31  when unsigned(COL_SYS) = 0 else
                3   when unsigned(COL_SYS) = 1 else
                2   when unsigned(COL_SYS) > 1 and unsigned(COL_SYS) <= 4 else
                0 ;

  column_dcdr <=  10 when unsigned(COL_SYS) = 0 else
                  43 when unsigned(COL_SYS) = 1 else
                  48 when unsigned(COL_SYS) = 2 else
                  52 when unsigned(COL_SYS) = 3 else
                  56 when unsigned(COL_SYS) = 4 else
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
