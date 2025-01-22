----------------------------------------------------------------------------------
-- spi_ctrl.vhd
-- Server part SPI controller
-- 10 Nov, 2024
-- Semestral project in the autumn semester of 2024 in MPC-NDO.
-- Artem Gumenyuk (xgumen00@vutbr.cz)
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.server_pkg.all;
use work.common_pkg.all;

entity spi_ctrl is
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
          SUMM_BCD        : out summ_digit_arr_t
      );
end spi_ctrl;

architecture Behavioral of spi_ctrl is

  component binary_bcd_20_bit is
    generic(N: positive := 20);
    port(
        clk       : in std_logic;
        rst       : in std_logic;
        new_data  : in std_logic;
        binary_in : in std_logic_vector(N-1 downto 0);
        data_done : out std_logic;
        bcd_out   : out summ_digit_arr_t
    );
  end component;

-------------------------------------------------------------------------------

constant ALL_ONES_VECTOR : std_logic_vector(11 downto 0) := (others => '1');

  type fsm_t IS(idle, wait4data, tx_spi, wait4event, polling, read_from_regs, send_products, end_of_the_day_st, display_summ, wait4spi);
  -- IDLE:            idle state.
  --                  Next state: WAIT4DATA (cfg), WAIT4EVENT (run)
  -- WAIT4DATA:       wait for the UPD_DATA.
  --                  Next state: WAIT4EVENT (entered run mode), TX_SPI (if amount column of server node is not selected)
  -- TX_SPI:          concat SPI frame and sent it to the SPI master. Names and prices are sent to all slaves simultaneously.
  --                  Next state: WAIT4DATA
  -- WAIT4EVENT:      Wait for the signal from timer.
  --                  Next state: POLLING
  -- POLLING:         Send SPI frame to the selected slave (in the round).
  --                  Next state: WAIT4EVENT (if no request from the client), READ_FROM_REGS (is slave request send some products from the sever).
  -- READ_FROM_REGS:  Read amount of requested product from the regs.
  --                  Next state: WAIT4EVENT (if server hasn't any requested products), SEND_PRODUCTS (if server has requested products).
  -- SEND_PRODUCTS:   Send up to 10 peaces of requested product.
  --                  Next state: WAIT4EVENT

  signal fsm_c : fsm_t;
  signal fsm_s : fsm_t := idle;

  signal data_s : char_buff_t := (others => (others => '0'));

  signal char_idx_c : unsigned(4 downto 0);
  signal char_idx_s : unsigned(4 downto 0) := (others => '0');

  signal ssel_c     : std_logic_vector(g_SLAVE_CNT-1 downto 0);
  signal ssel_s     : std_logic_vector(g_SLAVE_CNT-1 downto 0) := (others => '1');
  signal single_c   : std_logic;
  signal single_s   : std_logic := '0';
  signal txn_ena_c  : std_logic;
  signal txn_ena_s  : std_logic := '0';
  signal tx_frame_c : std_logic_vector(g_DATA_WIDTH-1 downto 0);
  signal tx_frame_s : std_logic_vector(g_DATA_WIDTH-1 downto 0) := (others => '0');

  signal tx_data_c  : std_logic_vector(11 downto 0);
  signal tx_col_c   : std_logic_vector(2 downto 0);
  signal tx_row_c   : std_logic_vector(5 downto 0);
  signal tx_par_c   : std_logic;
  
  signal number_s   : std_logic_vector(11 downto 0) := (others => '0');

  -- save column and row
  signal col_s      : std_logic_vector(2 downto 0) := (others => '0');
  signal row_s      : std_logic_vector(5 downto 0) := (others => '0');

  -- timer for WAIT4EVENT
  signal timer_c    : unsigned(11 downto 0);
  signal timer_s    : unsigned(11 downto 0) := (others => '0');
  signal tmr_trig   : std_logic;
  signal sel_node_c : unsigned(g_NODE_WIDTH-1 downto 0); 
  signal sel_node_s : unsigned(g_NODE_WIDTH-1 downto 0) := (others => '0'); -- first client is selected by default

  -- POLLING signals
  signal spi_busy_s        : std_logic := '0';
  signal spi_rx_rw         : std_logic;
  signal spi_rx_col        : std_logic_vector(2 downto 0);
  signal spi_rx_row        : std_logic_vector(5 downto 0);
  signal spi_rx_data       : std_logic_vector(11 downto 0);
  signal spi_rx_par        : std_logic;
  signal spi_rx_calc_par_c : std_logic;
  signal spi_amount_data   : unsigned(11 downto 0);
  signal spi_col           : std_logic_vector(2 downto 0);
  signal spi_row           : std_logic_vector(5 downto 0);

  -- DECODING RX data from client:
  -- if COL = "111" and ROW = "111111" it is a special code. TBD
  -- data(11): 0 - client is in the config mode, 1 - client is in the run mode
  -- data(10): 0 - Reserved, 1 - sending "end of the day info"
  -- data(9):  1 - client is out of product on selected row

  signal decremented_din_c : unsigned(11 downto 0);
  signal decremented_din_s : unsigned(11 downto 0) := (others => '0');

  -- update server's amount to UI
  signal upd_data_c        : std_logic;
  signal upd_data_s        : std_logic := '0';

  signal rx_data_s         : std_logic_vector(g_DATA_WIDTH-1 downto 0) := (others => '0');

  -- signals for end of the day
  signal prod_num_c    : unsigned(5 downto 0);
  signal prod_num_s    : unsigned(5 downto 0) := (others => '0');

  signal frst_frm_done_c  : std_logic;
  signal frst_frm_done_s  : std_logic := '0';

  signal end_of_the_day_c  : std_logic;
  signal end_of_the_day_s  : std_logic := '0';

  signal summ_c : unsigned(19 downto 0);
  signal summ_s : unsigned(19 downto 0) := (others => '0');

  signal tx_data_end_c  : std_logic_vector(11 downto 0);
  signal tx_col_end_c   : std_logic_vector(2 downto 0);
  signal tx_row_end_c   : std_logic_vector(5 downto 0);

  -- binary to BCD
  signal new_data_c  : STD_LOGIC;
  signal new_data_s  : STD_LOGIC := '0';

  signal data_done_c : STD_LOGIC;
  signal bcd_out     : summ_digit_arr_t;
begin

-------------------------------------------------------------------------------
  -- sample DATA from ui_adapter when valid
  process(CLK, RST) begin
    if(RST = '1') then
      data_s <= (others => (others => '0'));
    elsif(rising_edge(CLK)) then
      if(UPD_DATA = '1') then
        col_s    <= COL;
        row_s    <= ROW;
        data_s   <= DATA;
        number_s <= NUMBER;
      end if;
    end if;
  end process;

-------------------------------------------------------------------------------

  process(CLK, RST) begin
    if(RST = '1') then
      fsm_s             <= idle;
      char_idx_s        <= (others => '0');
      ssel_s            <= (others => '1');
      single_s          <= '0';
      txn_ena_s         <= '0';
      tx_frame_s        <= (others => '0');
      timer_s           <= (others => '0');
      sel_node_s        <= (others => '0');
      spi_busy_s        <= '0';
      decremented_din_s <= (others => '0');
      upd_data_s        <= '0';
      prod_num_s        <= (others => '0');
      frst_frm_done_s   <= '0';
      summ_s            <= (others => '0');
      new_data_s        <= '0';
      end_of_the_day_s  <= '0';
    elsif(rising_edge(CLK)) then
      fsm_s             <= fsm_c;
      char_idx_s        <= char_idx_c;
      ssel_s            <= ssel_c;
      single_s          <= single_c;
      txn_ena_s         <= txn_ena_c;
      tx_frame_s        <= tx_frame_c;
      timer_s           <= timer_c;
      sel_node_s        <= sel_node_c;
      spi_busy_s        <= BUSY;
      upd_data_s        <= upd_data_c;
      prod_num_s        <= prod_num_c;
      frst_frm_done_s   <= frst_frm_done_c;
      summ_s            <= summ_c;
      new_data_s        <= new_data_c;
      end_of_the_day_s  <= end_of_the_day_c;

      if(ACK = '1') then
        decremented_din_s <= decremented_din_c;
      end if;

      if((not BUSY and spi_busy_s) = '1') then
        rx_data_s <= RX_DATA;
      end if;
    end if;
  end process;

-------------------------------------------------------------------------------

  process(fsm_s, EDIT_ENA, BUSY, UPD_DATA, char_idx_s, COL, ROW, NODE, data_s, col_s, row_s, spi_busy_s,
          txn_ena_s, tx_frame_s, tx_data_c, tx_row_c, tx_col_c, tx_par_c, single_s, prod_num_s, summ_s, VGA_RDY,
          tmr_trig, sel_node_s, spi_rx_par, spi_rx_calc_par_c, spi_rx_data, tx_col_c, frst_frm_done_s, rx_data_s,
          spi_rx_row, DIN, ACK, decremented_din_c, decremented_din_s, NODE_UPD_ACTIVE, end_of_the_day_s) begin
    fsm_c             <= fsm_s;
    char_idx_c        <= char_idx_s;
    ssel_c            <= (others => '1');
    single_c          <= single_s;
    txn_ena_c         <= '0';
    tx_frame_c        <= tx_frame_s;
    sel_node_c        <= sel_node_s;
    spi_col           <= "001";
    spi_row           <= (others => '0');
    spi_amount_data   <= (others => '0');
    upd_data_c        <= '0';
    -- bus_arbiter
    RW                <= '1';
    COL_OUT           <= (others => '0');
    ROW_OUT           <= (others => '0');
    NODE_OUT          <= (others => '0');
    REQ               <= '0';
    DOUT              <= (others => '0');
    prod_num_c        <= prod_num_s;
    frst_frm_done_c   <= frst_frm_done_s;
    summ_c            <= summ_s;
    new_data_c        <= '0';
    end_of_the_day_c  <= end_of_the_day_s;

    case(fsm_s) is
      when idle =>
        if(EDIT_ENA = '1') then
          fsm_c <= wait4data;
        else
          fsm_c <= wait4event;
        end if;
      ---------------------------------------------------------------------------
      when wait4data =>
        if(EDIT_ENA = '0') then
          fsm_c <= wait4event;
        elsif(UPD_DATA = '1' and NODE_UPD_ACTIVE = '0' and
              not(COL = "001" and (TO_INTEGER(unsigned(NODE)) = 0)))
        then
          if(COL /= col_s or ROW /= row_s) then
            char_idx_c <= (others => '0');
          end if;
          fsm_c <= tx_spi;
        end if;
      ---------------------------------------------------------------------------
      when tx_spi =>
        if(BUSY = '0') then -- if SPI is not busy
          if(COL = "001") then -- send amount to selected client
            ssel_c <= (others => '1');
            ssel_c(TO_INTEGER(unsigned(NODE) - 1)) <= '0';
            single_c  <= '1';
          else -- send dishes names and prices to all slaves in one time
            ssel_c    <= (others => '0');
            single_c  <= '0';
          end if;

          tx_frame_c <= tx_par_c & tx_data_c & ROW & COL & '0'; -- 1b'rw, 9b'addr, 12b'data, 1b'parity
          txn_ena_c <= '1';
          fsm_c <= wait4data;
          
          if(data_s(0) /= x"00") then
            char_idx_c <= char_idx_s + 1;
          end if;
        end if;
      ---------------------------------------------------------------------------
      when wait4event =>
        if(EDIT_ENA = '1') then -- end of the day
          fsm_c             <= end_of_the_day_st;
          end_of_the_day_c  <= '1';
          sel_node_c        <= (others => '0');
          prod_num_c        <= (others => '0');
        elsif(tmr_trig = '1') then
          fsm_c <= polling;
          ssel_c <= (others => '1');
          ssel_c(TO_INTEGER(sel_node_s)) <= '0';
          single_c  <= '1';
          -- TODO: check parity bit corectness
          tx_frame_c <= '0' & "111111111111" & "111111" & "111" & '1'; -- 1b'rw, 9b'addr, 12b'data, 1b'parity
          txn_ena_c  <= '1';
        end if;
      ---------------------------------------------------------------------------
      when polling =>
        -- wait for falling edge of SPI BUSY
        if((not BUSY and spi_busy_s) = '1') then
          if( (spi_rx_par = spi_rx_calc_par_c) and                        -- check parity
              ((spi_rx_data(11) = '1') and (spi_rx_data(10) = '0')) and   -- check that server is in the run, non-"end of day" mode
              (spi_rx_data(9) = '1')) then                                -- client request send a product from server
                fsm_c <= read_from_regs;
                -- read from regs
                RW       <= '1';
                COL_OUT  <= "001"; -- amount column
                ROW_OUT  <= spi_rx_row;
                NODE_OUT <= (others => '0');
                REQ      <= '1';
          else
            fsm_c <= wait4event;
            -- increment selected client
            if(sel_node_s = (g_SLAVE_CNT-1)) then
              sel_node_c <= (others => '0');
            else
              sel_node_c <= sel_node_s + 1;
            end if;
          end if;
        end if;
      ---------------------------------------------------------------------------
      when read_from_regs =>
        RW       <= '1';
        COL_OUT  <= "001"; -- amount column
        ROW_OUT  <= spi_rx_row;
        NODE_OUT <= (others => '0');
        REQ      <= '1';

        --wait for ACK
        if(ACK = '1') then
          if(TO_INTEGER(UNSIGNED(DIN)) = 0) then -- no products
            fsm_c <= wait4event;
            REQ   <= '0';

            -- send frame with zero amount
            ssel_c <= (others => '1');
            ssel_c(TO_INTEGER(sel_node_s)) <= '0';
            single_c  <= '1';
            spi_amount_data <= (others => '0');
            spi_row    <= spi_rx_row;
            tx_frame_c <= tx_par_c & tx_data_c & tx_row_c & tx_col_c & '0'; -- 1b'rw, 9b'addr, 12b'data, 1b'parity
            txn_ena_c  <= '1';

            -- increment selected client
            if(sel_node_s = (g_SLAVE_CNT-1)) then
              sel_node_c <= (others => '0');
            else
              sel_node_c <= sel_node_s + 1;
            end if;
          else -- server can send at least 1 peace of product 
            fsm_c <= send_products;
            REQ   <= '0';
            
            -- send frame with some amount of product
            ssel_c <= (others => '1');
            ssel_c(TO_INTEGER(sel_node_s)) <= '0';
            single_c   <= '1';
            spi_row    <= spi_rx_row;
            tx_frame_c <= tx_par_c & tx_data_c & tx_row_c & tx_col_c & '0'; -- 1b'rw, 9b'addr, 12b'data, 1b'parity
            txn_ena_c  <= '1';
            if(TO_INTEGER(UNSIGNED(DIN)) >= 10) then
              spi_amount_data <= to_unsigned(10, spi_amount_data'length);
            else
              spi_amount_data <= UNSIGNED(DIN);
            end if;
          end if;
        end if;
      ---------------------------------------------------------------------------
      when send_products =>
        -- re-write amount in the register
        REQ      <= '1';
        RW       <= '0';
        COL_OUT  <= "001"; -- amount column
        ROW_OUT  <= spi_rx_row;
        NODE_OUT <= (others => '0');
        -- NODE_OUT <= std_logic_vector(sel_node_s + 1);
        DOUT     <= std_logic_vector(decremented_din_s);

        --wait for ACK
        if(ACK = '1') then
          fsm_c       <= wait4event;
          REQ         <= '0';
          RW          <= '1';
          upd_data_c  <= '1';

          -- increment selected client
          if(sel_node_s = (g_SLAVE_CNT-1)) then
            sel_node_c <= (others => '0');
          else
            sel_node_c <= sel_node_s + 1;
          end if;
        end if;
      ---------------------------------------------------------------------------
      when end_of_the_day_st =>
        if((sel_node_s = (g_SLAVE_CNT-1)) and (prod_num_s = 32)) then
          -- write last amount to the memory
          REQ      <= '1';
          RW       <= '0';
          COL_OUT  <= "001"; -- amount column
          ROW_OUT  <= spi_rx_row;
          NODE_OUT <= std_logic_vector(sel_node_s + 1);
          DOUT     <= "00" & std_logic_vector(spi_rx_data(9 downto 0));

          if(ACK = '1') then
            REQ <= '0';
            RW  <= '1';
            fsm_c <= display_summ;
          end if;
        elsif(prod_num_s = 32) then
          -- write last amount to the memory
          REQ      <= '1';
          RW       <= '0';
          COL_OUT  <= "001"; -- amount column
          ROW_OUT  <= spi_rx_row;
          NODE_OUT <= std_logic_vector(sel_node_s + 1);
          DOUT     <= "00" & std_logic_vector(spi_rx_data(9 downto 0));

          if(ACK = '1') then
            REQ <= '0';
            RW  <= '1';
            sel_node_c      <= sel_node_s + 1;
            prod_num_c      <= (others => '0');
            frst_frm_done_c <= '0';
          end if;
        elsif(prod_num_s = 0) then -- send first frame to the client
          if(frst_frm_done_s = '0') then -- send the "end of the day" CMD
            -- SPI frame
            ssel_c          <= (others => '1');
            ssel_c(TO_INTEGER(sel_node_s)) <= '0';
            single_c        <= '1';
            tx_data_end_c   <= "001111111111"; -- "end of the day" CMD
            tx_col_end_c    <= "111";
            tx_row_end_c    <= "111111";
            tx_frame_c      <= tx_par_c & tx_data_c & tx_row_c & tx_col_c & '0'; -- 1b'rw, 9b'addr, 12b'data, 1b'parity
            txn_ena_c       <= '1';
            frst_frm_done_c <= '1';
            fsm_c           <= wait4spi;
          else -- send frame with first amount request
            -- SPI frame
            ssel_c          <= (others => '1');
            ssel_c(TO_INTEGER(sel_node_s)) <= '0';
            single_c        <= '1';
            tx_data_end_c   <= "101111111111"; -- read amount request
            tx_col_end_c    <= "001";
            tx_row_end_c    <= std_logic_vector(prod_num_s);
            tx_frame_c      <= tx_par_c & tx_data_c & tx_row_c & tx_col_c & '1'; -- 1b'rw, 9b'addr, 12b'data, 1b'parity
            txn_ena_c       <= '1';
            fsm_c           <= wait4spi;
            prod_num_c      <= prod_num_s + 1;
          end if;
        elsif(prod_num_s = 1) then -- get responce with the summ
          if(spi_rx_data(10) = '1') then -- check "end of the day flag"
            -- SPI frame
            ssel_c          <= (others => '1');
            ssel_c(TO_INTEGER(sel_node_s)) <= '0';
            single_c        <= '1';
            tx_data_end_c   <= "101111111111"; -- read amount request
            tx_col_end_c    <= "001";
            tx_row_end_c    <= std_logic_vector(prod_num_s);
            tx_frame_c      <= tx_par_c & tx_data_c & tx_row_c & tx_col_c & '1'; -- 1b'rw, 9b'addr, 12b'data, 1b'parity
            txn_ena_c       <= '1';
            fsm_c           <= wait4spi;
            prod_num_c      <= prod_num_s + 1;
            
            new_data_c      <= '1';
            summ_c          <= summ_s + unsigned(rx_data_s(19 downto 0));
          else -- incorrect responce
            if(sel_node_s = (g_SLAVE_CNT-1)) then
              fsm_c <= display_summ;
            else
              sel_node_c <= sel_node_s + 1;
              prod_num_c <= (others => '0');
            end if;
          end if;
        else  -- get responces with the amounts of products
          if(spi_rx_data(10) = '1') then -- check "end of the day flag"
            -- write amount to the memory
            REQ      <= '1';
            RW       <= '0';
            COL_OUT  <= "001"; -- amount column
            ROW_OUT  <= spi_rx_row;
            NODE_OUT <= std_logic_vector(sel_node_s + 1);
            DOUT     <= std_logic_vector(spi_rx_col(1 downto 0)) &
                        std_logic_vector(spi_rx_data(9 downto 0));

            if(ACK = '1') then
              REQ <= '0';
              RW  <= '1';
              -- SPI frame
              ssel_c          <= (others => '1');
              ssel_c(TO_INTEGER(sel_node_s)) <= '0';
              single_c        <= '1';
              tx_data_end_c   <= "101111111111"; -- read amount request
              tx_col_end_c    <= "001";
              tx_row_end_c    <= std_logic_vector(prod_num_s);
              tx_frame_c      <= tx_par_c & tx_data_c & tx_row_c & tx_col_c & '1'; -- 1b'rw, 9b'addr, 12b'data, 1b'parity
              txn_ena_c       <= '1';
              fsm_c           <= wait4spi;
              prod_num_c      <= prod_num_s + 1;
            end if;
          else -- incorrect responce
            if(sel_node_s = (g_SLAVE_CNT-1)) then
              fsm_c <= display_summ;
            else
              sel_node_c <= sel_node_s + 1;
              prod_num_c <= (others => '0');
            end if;
          end if;
        end if;
      ---------------------------------------------------------------------------
      when wait4spi =>
        -- wait for falling edge of SPI BUSY
        if((not BUSY and spi_busy_s) = '1') then
          fsm_c <= end_of_the_day_st;
        end if;
      ---------------------------------------------------------------------------
      when display_summ =>
        if(VGA_RDY = '1') then
          upd_data_c        <= '1';
          fsm_c             <= wait4data;
          end_of_the_day_c  <= '0';
        end if;
      ---------------------------------------------------------------------------
      when others => fsm_c <= idle;
    end case;
  end process;

  -- timer
  process(timer_s) begin
    timer_c  <= timer_s;
    tmr_trig <= '0';

    if(std_logic_vector(timer_s) = ALL_ONES_VECTOR) then
      timer_c  <= (others => '0');
      tmr_trig <= '1';
    else
      timer_c <= timer_s + 1;
    end if;
  end process;

  -- calculate TX
  process(COL, ROW, data_s, char_idx_s, number_s, EDIT_ENA,
          spi_amount_data, spi_col, spi_row, fsm_s, tx_data_end_c, tx_col_end_c, tx_row_end_c) begin
    if(EDIT_ENA = '1') then
      if((fsm_s = idle) or (fsm_s = wait4data) or (fsm_s = tx_spi)) then
        if(COL = "000") then
          tx_data_c <= "0000" & data_s(TO_INTEGER(char_idx_s));
        else
          tx_data_c <= number_s;
        end if;
        tx_col_c <= COL;
        tx_row_c <= ROW;   
      else
        tx_data_c <= tx_data_end_c;
        tx_col_c  <= tx_col_end_c;
        tx_row_c  <= tx_row_end_c;
      end if;
    else
      tx_data_c <= std_logic_vector(spi_amount_data);
      tx_col_c  <= spi_col;
      tx_row_c  <= spi_row;
    end if;
  end process;

  -- calculate decremented DIN. Maximum by 10
  process(DIN) begin
    if(unsigned(DIN) >= 10) then
      decremented_din_c <= unsigned(DIN) - 10;
    else
      decremented_din_c <= (others => '0');
    end if;
  end process;

  tx_par_c  <=  not ('0' xor tx_col_c(0) xor tx_col_c(1) xor tx_col_c(2) xor tx_row_c(0) xor
                tx_row_c(1) xor tx_row_c(2) xor tx_row_c(3) xor tx_row_c(4) xor tx_row_c(5) xor
                tx_data_c(0) xor tx_data_c(1) xor tx_data_c(2) xor tx_data_c(3) xor
                tx_data_c(4) xor tx_data_c(5) xor tx_data_c(6) xor tx_data_c(7) xor
                tx_data_c(8) xor tx_data_c(9) xor tx_data_c(10) xor tx_data_c(11));

  spi_rx_calc_par_c <=  not ('0' xor spi_rx_col(0) xor spi_rx_col(1) xor spi_rx_col(2) xor spi_rx_row(0) xor
                        spi_rx_row(1) xor spi_rx_row(2) xor spi_rx_row(3) xor spi_rx_row(4) xor spi_rx_row(5) xor
                        spi_rx_data(0) xor spi_rx_data(1) xor spi_rx_data(2) xor spi_rx_data(3) xor
                        spi_rx_data(4) xor spi_rx_data(5) xor spi_rx_data(6) xor spi_rx_data(7) xor
                        spi_rx_data(8) xor spi_rx_data(9) xor spi_rx_data(10) xor spi_rx_data(11));

  -- output assignments
  SSEL    <= ssel_s;
  SINGLE  <= single_s;
  TXN_ENA <= txn_ena_s;
  TX_DATA <= tx_frame_s;

  -- RX SPI frame
  process(fsm_s, RX_DATA, rx_data_s) begin
    if(fsm_s = polling) then
      spi_rx_rw   <= RX_DATA(0);
      spi_rx_col  <= RX_DATA(3 downto 1);
      spi_rx_row  <= RX_DATA(9 downto 4); 
      spi_rx_data <= RX_DATA(21 downto 10);
      spi_rx_par  <= RX_DATA(22);
    else
      spi_rx_rw   <= rx_data_s(0);
      spi_rx_col  <= rx_data_s(3 downto 1);
      spi_rx_row  <= rx_data_s(9 downto 4); 
      spi_rx_data <= rx_data_s(21 downto 10);
      spi_rx_par  <= rx_data_s(22);
    end if;
  end process;

  -- sprit output decoder
  binary_bcd_20_bit_i : binary_bcd_20_bit
  generic map (
    N => 20
  )
  port map(
    clk       => CLK,
    rst       => RST,
    new_data  => new_data_s,
    binary_in => std_logic_vector(summ_s),
    data_done => data_done_c,
    bcd_out   => bcd_out
  );

  -- output assignments 
  UPD_DATA_OUT    <= upd_data_s;
  END_OF_THE_DAY  <= end_of_the_day_s;
  SUMM_BCD        <= bcd_out;

end Behavioral;
