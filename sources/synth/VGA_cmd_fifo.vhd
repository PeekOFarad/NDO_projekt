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

entity VGA_cmd_fifo is
  Port ( 
    CLK         : in  std_logic;
    RST         : in  std_logic;
    -- System Interface
    -- COL         : in  STD_LOGIC_VECTOR (2 downto 0);
    -- ROW         : in  STD_LOGIC_VECTOR (5 downto 0);
    -- UPD_ARR     : in  STD_LOGIC;
    -- UPD_DATA    : in  STD_LOGIC;
    -- DATA_OUT    : in  sprit_buff_t;
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

  signal ROM_addr           : unsigned(9 downto 0) := (others => '0');
  signal ROM_data_o         : std_logic_vector(7 downto 0) := (others => '0');

  signal ub_n_c           : std_logic;
  signal ub_n_s           : std_logic := '1';
  signal lb_n_c           : std_logic;
  signal lb_n_s           : std_logic := '1';

  signal we_n_d           : std_logic_vector(1 downto 0) := (others => '0');

  -- fifo
  signal char_fifo          : t_char_fifo := (
    (column => 74, row => 39, id => 49),
    (column => 75, row => 39, id => 62),
    (column => 76, row => 39, id => 62),
    (column => 77, row => 39, id => 49),
    (column => 78, row => 39, id => 48),
    (column => 79, row => 39, id => 66),
    (column => 79, row => 39, id => 2)
  );
  signal fifo_empty					: boolean := true; --! driver fifo util signal
  signal fifo_last					: boolean := true; --! driver fifo util signal
  signal fifo_full					: boolean := false; --! driver fifo util signal
  signal tx_en							: std_logic := '0'; --! tvalid && tready
  signal cnt_fifo_wr_ptr		: integer := c_CHAR_FIFO_SIZE-1; --! write pointer
  signal cnt_fifo_rd_ptr_c	: integer := 0; --! read pointer combinatorial
  signal cnt_fifo_rd_ptr_s	: integer := 0; --! read pointer sequencial (register output)
  signal fifo_utilization		: integer := 0;	--! current fifo utilization

  signal char : t_char := (column => 0, row => 0, id => 0);

  -- char addr decoder
  -- signal char_col_addr  : unsigned(c_COL_NUM_BIN-1 downto 0) := (others => '0');
  -- signal column         : unsigned(c_COL_NUM_BIN-1 downto 0) := (others => '0');


  
begin

  DATA_O  <= bit_reverse(ROM_data_o) & bit_reverse(ROM_data_o);
  WADDR_C <= std_logic_vector(char_addr_c);
  WE_N_D2 <= we_n_d(we_n_d'low);
  LB_N_W  <= lb_n_s;
  UB_N_W  <= ub_n_s;

  process (CLK)
  begin
    if rising_edge(CLK) then
      if RST = '1' then  -- TODO USE V_PORCH/WRITE ENBALE AS RESET?
        cnt_ROW_s         <= to_unsigned(11, cnt_ROW_s'length);--(others => '0');
        -- char_base_addr_s  <= (others => '0');
        char              <= (others => 0); 
        ub_n_s            <= '1';
        lb_n_s            <= '1';
        we_n_d            <= (others => '0');
        cnt_ROW_max_d1    <= '0';
        char_addr_s       <= (others => '0');
      else
        char_addr_s       <= char_addr_c;
        we_n_d            <= not FIFO_REN & we_n_d(we_n_d'high downto we_n_d'low + 1);

        cnt_ROW_max_d1    <= '0';
        if cnt_ROW_s >= 11 then
          cnt_ROW_max_d1    <= '1';
        end if;
        
        if FIFO_REN = '1' then
          if cnt_ROW_s = 11 and not fifo_empty then
            char          <= char_fifo(cnt_fifo_rd_ptr_s);
          end if;  
          cnt_ROW_s       <= cnt_ROW_c;
        end if;

        if fifo_empty and cnt_ROW_max_d1 = '1' then
          ub_n_s            <= '1';
          lb_n_s            <= '1';
        else
          ub_n_s            <= ub_n_c;
          lb_n_s            <= lb_n_c;
        end if;
      end if;
    end if;
  end process;

  --! char_id decoder
  sprite_base_addr_c  <= to_unsigned(char.ID*12, sprite_base_addr_c'length);
  sprite_raddr_c      <= sprite_base_addr_c + resize(cnt_ROW_s, sprite_raddr_c'length);


  p_SRAM_addr_dcdr: process(char.column, char.row, cnt_ROW_s, fifo_empty)
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


  p_cnt_ROW: process (cnt_ROW_s, fifo_empty)
  begin
    cnt_ROW_c <= cnt_ROW_s + 1;
    if cnt_ROW_s >= 11 then
      cnt_ROW_c <= (others => '0');
      if fifo_empty then
        cnt_ROW_c <= cnt_ROW_s;
      end if;
    end if;
  end process;

  --------------------------------------------------------------------------------
  -- CHAR FIFO
  --------------------------------------------------------------------------------
  --! Combinatorial fifo utilization calculation
	p_fifo_util: process (cnt_fifo_rd_ptr_s, cnt_fifo_wr_ptr)
	begin
		if cnt_fifo_wr_ptr < cnt_fifo_rd_ptr_s then
			fifo_utilization <= cnt_fifo_wr_ptr - cnt_fifo_rd_ptr_s + c_CHAR_FIFO_SIZE;
		else
			fifo_utilization <= cnt_fifo_wr_ptr - cnt_fifo_rd_ptr_s;
		end if;
	end process;

	fifo_last		<= true when fifo_utilization = 1 else  false;
	fifo_empty	<= true when fifo_utilization <= 0 else  false;
	fifo_full		<= true when fifo_utilization >= c_CHAR_FIFO_SIZE-1 else false; -- Keep one open fifo

	--! Read pointer register
	p_read_ptr_reg: process
	begin
		wait until rising_edge(CLK);
		cnt_fifo_rd_ptr_s <= cnt_fifo_rd_ptr_c;
	end process;
	--! Combinatorial read pointer calculation
	p_read_ptr: process (cnt_fifo_rd_ptr_s, cnt_ROW_s, FIFO_REN, fifo_empty) 
	begin
			cnt_fifo_rd_ptr_c <= cnt_fifo_rd_ptr_s;
			if (cnt_ROW_s = 11 and FIFO_REN = '1') and not fifo_empty then
				cnt_fifo_rd_ptr_c <= cnt_fifo_rd_ptr_s + 1;
				if cnt_fifo_rd_ptr_s >= c_CHAR_FIFO_SIZE-1 then -- wrap when at the end
					cnt_fifo_rd_ptr_c <= 0;
				end if;
			end if;
	end process;
  --------------------------------------------------------------------------------
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
