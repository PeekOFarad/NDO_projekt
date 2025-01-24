----------------------------------------------------------------------------------
-- client_core.vhd
-- Client part core
-- 11 Jan, 2025
-- Semestral project in the autumn semester of 2024 in MPC-NDO.
-- Artem Gumenyuk (xgumen00@vutbr.cz)
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.client_pkg.all;
use work.ps2_pkg.all;
use work.common_pkg.all;

entity client_core is
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
          SUMM        : out STD_LOGIC_VECTOR (19 downto 0);
          -- from PS2 top
          KEYS     : in t_keys;
          -- buttons (S, Z, E)
          BTN_S    : in STD_LOGIC;
          BTN_Z    : in STD_LOGIC;
          BTN_E    : in STD_LOGIC
        );
end client_core;

architecture Behavioral of client_core is

  component binary_bcd is
    generic(N: positive := 12);
    port(
        clk       : in std_logic;
        rst       : in std_logic;
        new_data  : in std_logic;
        binary_in : in std_logic_vector(N-1 downto 0);
        data_done : out std_logic;
        bcd_out   : out digit_arr_t
    );
  end component;

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

  constant ALL_ZERO_VECTOR_DIN : std_logic_vector(DIN'range) := (others => '0');

  type fsm_t IS(idle, wait4enter, read_amount, read_price, edit_amount);

  type spi_fsm_t IS(idle, wait4rsp, edit_amount);

  signal fsm_c : fsm_t;
  signal fsm_s : fsm_t := idle;

  signal spi_fsm_c : spi_fsm_t;
  signal spi_fsm_s : spi_fsm_t := idle;

  signal row_c : unsigned(5 downto 0);
  signal row_s : unsigned(5 downto 0) := (others => '0');

  -- PRICE CODES: "010" - student, "011" - employee, "100" - external
  signal price_type_c : std_logic_vector(2 downto 0);
  signal price_type_s : std_logic_vector(2 downto 0) := "010"; -- default is a student

  signal amount_buff_c : unsigned(11 downto 0);
  signal amount_buff_s : unsigned(11 downto 0) := (others => '0');

  signal price_buff_c : std_logic_vector(7 downto 0);
  signal price_buff_s : std_logic_vector(7 downto 0) := (others => '0');

  signal summ_c : unsigned(19 downto 0);
  signal summ_s : unsigned(19 downto 0) := (others => '0');

  signal new_summ_c : std_logic;
  signal new_summ_s : std_logic := '0';

  signal bcd_summ_done : std_logic;

  signal bcd_summ_out : summ_digit_arr_t;

  signal out_of_product_flag_c : std_logic;

  signal spi_row_c : unsigned(5 downto 0);
  signal spi_row_s : unsigned(5 downto 0) := (others => '0');

  signal rsp_amount_c : std_logic_vector(3 downto 0);
  signal rsp_amount_s : std_logic_vector(3 downto 0) := (others => '0');

  signal upd_arr_c : std_logic;
  signal upd_arr_s : std_logic := '0';

  signal upd_data_c : std_logic;
  signal upd_data_s : std_logic := '0';

  signal upd_arr_req_c : std_logic;
  signal upd_arr_req_s : std_logic := '0';

  signal upd_data_req_c : std_logic;
  signal upd_data_req_s : std_logic := '0';

  signal upd_summ_req_c : std_logic;
  signal upd_summ_req_s : std_logic := '1';

  signal upd_price_req_c : std_logic;
  signal upd_price_req_s : std_logic := '1';

  signal ui_col_c : unsigned(2 downto 0);
  signal ui_col_s : unsigned(2 downto 0) := (others => '0');

  signal ui_row_c : unsigned(5 downto 0);
  signal ui_row_s : unsigned(5 downto 0) := (others => '0');

  -- binary to BCD
  signal new_data_c     : STD_LOGIC;
  signal bcd_data_done  : STD_LOGIC;
  signal bcd_out        : digit_arr_t;

  signal char_buff_c : summ_buff_t;
  signal char_buff_s : summ_buff_t := (others => (others => '0'));

begin

  process(CLK, RST) begin
    if(RST = '1') then
      fsm_s           <= idle;
      spi_fsm_s       <= idle;
      row_s           <= (others => '0');
      spi_row_s       <= (others => '0');
      price_type_s    <= "010";
      amount_buff_s   <= (others => '0');
      price_buff_s    <= (others => '0');
      summ_s          <= (others => '0');
      rsp_amount_s    <= (others => '0');
      upd_arr_s       <= '0';
      upd_data_s      <= '0';
      upd_arr_req_s   <= '0';
      upd_data_req_s  <= '0';
      upd_summ_req_s  <= '1';
      upd_price_req_s <= '1';
      new_summ_s      <= '0';
      ui_col_s        <= (others => '0');
      ui_row_s        <= (others => '0');
      char_buff_s     <= (others => (others => '0'));
    elsif(rising_edge(CLK)) then
      fsm_s           <= fsm_c;
      spi_fsm_s       <= spi_fsm_c;
      row_s           <= row_c;
      spi_row_s       <= spi_row_c;
      price_type_s    <= price_type_c;
      amount_buff_s   <= amount_buff_c;
      price_buff_s    <= price_buff_c;
      summ_s          <= summ_c;
      rsp_amount_s    <= rsp_amount_c;
      upd_arr_s       <= upd_arr_c;
      upd_data_s      <= upd_data_c;
      upd_arr_req_s   <= upd_arr_req_c;
      upd_data_req_s  <= upd_data_req_c;
      upd_summ_req_s  <= upd_summ_req_c;
      upd_price_req_s <= upd_price_req_c;
      new_summ_s      <= new_summ_c;
      ui_col_s        <= ui_col_c; 
      ui_row_s        <= ui_row_c;
      char_buff_s     <= char_buff_c;
    end if;
  end process;

  process(fsm_s, row_s, EDIT_ENA, KEYS, price_type_s, amount_buff_c, RSP_RDY,
          amount_buff_s, price_buff_c, price_buff_s, summ_s, DIN, ACK_1, RSP_AMOUNT) begin
    fsm_c         <= fsm_s;
    row_c         <= row_s;
    amount_buff_c <= amount_buff_s;
    price_buff_c  <= price_buff_s;
    summ_c        <= summ_s;
    out_of_product_flag_c <= '0';
    RW_1          <= '1';
    COL_OUT_1     <= (others => '0');
    ROW_OUT_1     <= (others => '0');
    REQ_1         <= '0';
    DOUT_1        <= (others => '0');
    new_data_c    <= '0';
    new_summ_c    <= '0';

    case(fsm_s) is
-------------------------------------------------------------------------------
      when idle =>
        row_c  <= (others => '0');

        if(EDIT_ENA = '0') then
          fsm_c <= wait4enter;
        end if;
-------------------------------------------------------------------------------
      when wait4enter =>
        if(EDIT_ENA = '1') then
          fsm_c       <= idle;
          new_summ_c  <= '1';
          summ_c      <= (others => '0');
        else
          -- cursor
          if((KEYS.up = '1') and (row_s /= "000000")) then
            row_c <= row_s - 1;
          elsif((KEYS.down = '1') and (row_s /= to_unsigned(c_FOOD_CNT-1, row_s'length))) then
            row_c <= row_s + 1;
          end if;
          
          -- enter
          if(KEYS.enter = '1') then
            fsm_c   <= read_amount;
            RW_1      <= '1';
            COL_OUT_1 <= "001";
            ROW_OUT_1 <= std_logic_vector(row_s);
            REQ_1     <= '1';
          end if;

          -- products arrived
          if((RSP_RDY = '1') and ((RSP_AMOUNT /= "0000"))) then
            amount_buff_c <= resize(unsigned(RSP_AMOUNT), amount_buff_c'length);
            new_data_c    <= '1';
          end if;
        end if;
-------------------------------------------------------------------------------
      when read_amount =>
        RW_1      <= '1';
        COL_OUT_1 <= "001";
        ROW_OUT_1 <= std_logic_vector(row_s);
        REQ_1     <= '1';

        if(ACK_1 = '1') then
          REQ_1 <= '0';

          if(DIN = ALL_ZERO_VECTOR_DIN) then
            if(EDIT_ENA = '1') then
              fsm_c <= idle;
            else
              fsm_c <= wait4enter;
            end if;
          else
            amount_buff_c <= unsigned(DIN) - 1;
            new_data_c    <= '1';
            fsm_c         <= read_price;
          end if;
        end if;
-------------------------------------------------------------------------------
      when read_price =>
        RW_1      <= '1';
        COL_OUT_1 <= price_type_s;
        ROW_OUT_1 <= std_logic_vector(row_s);
        REQ_1     <= '1';
        
        if(ACK_1 = '1') then
          REQ_1         <= '0';
          price_buff_c  <= DIN(7 downto 0);
          summ_c        <= summ_s + unsigned(DIN(7 downto 0));
          new_summ_c    <= '1';
          fsm_c         <= edit_amount;
        end if;
-------------------------------------------------------------------------------
      when edit_amount =>
        RW_1      <= '0';
        COL_OUT_1 <= "001";
        ROW_OUT_1 <= std_logic_vector(row_s);
        DOUT_1    <= std_logic_vector(amount_buff_s);
        REQ_1     <= '1';

        if(amount_buff_s = TO_UNSIGNED(0, amount_buff_s'length)) then
          out_of_product_flag_c <= '1';
        end if;

        if(ACK_1 = '1') then
          REQ_1 <= '0';
          RW_1  <= '1';

          if(EDIT_ENA = '1') then
            fsm_c <= idle;
          else
            fsm_c <= wait4enter;
          end if;
        end if;
-------------------------------------------------------------------------------
      when others =>
        fsm_c <= idle;
    end case;
  end process;

  -- price select
  process(price_type_s, BTN_S, BTN_Z, BTN_E) begin
    price_type_c <= price_type_s;

    if(BTN_Z = '1') then
      price_type_c <= "011";
    elsif(BTN_E = '1') then
      price_type_c <= "100";
    elsif(BTN_S = '1') then
      price_type_c <= "010";
    end if;
  end process;

  process(spi_fsm_s, row_s, spi_row_s, rsp_amount_s, out_of_product_flag_c,
          RSP_RDY, RSP_AMOUNT, ACK_2) begin
    spi_fsm_c     <= spi_fsm_s;
    spi_row_c     <= spi_row_s;
    rsp_amount_c  <= rsp_amount_s;
    REQ_TO_SERV   <= '0';
    RW_2          <= '1';
    COL_OUT_2     <= (others => '0');
    ROW_OUT_2     <= (others => '0');
    REQ_2         <= '0';
    DOUT_2        <= (others => '0');

    case(spi_fsm_s) is
-------------------------------------------------------------------------------
      when idle =>
        if(out_of_product_flag_c = '1') then
          spi_row_c <= row_s;
          spi_fsm_c <= wait4rsp;
        end if;
-------------------------------------------------------------------------------
      when wait4rsp =>
        REQ_TO_SERV <= '1';

        if(RSP_RDY = '1') then
          REQ_TO_SERV   <= '0';
          rsp_amount_c  <= RSP_AMOUNT;

          if(RSP_AMOUNT = "0000") then
            spi_fsm_c <= idle;
          else
            spi_fsm_c <= edit_amount;
            RW_2      <= '0';
            COL_OUT_2 <= "001";
            ROW_OUT_2 <= std_logic_vector(spi_row_s);
            DOUT_2    <= std_logic_vector(resize(unsigned(RSP_AMOUNT), DOUT_2'length));
            REQ_2     <= '1';
          end if;
        end if;
-------------------------------------------------------------------------------
      when edit_amount =>
        RW_2      <= '0';
        COL_OUT_2 <= "001";
        ROW_OUT_2 <= std_logic_vector(spi_row_s);
        DOUT_2    <= std_logic_vector(resize(unsigned(rsp_amount_s), DOUT_2'length));
        REQ_2     <= '1';

        if(ACK_2 = '1') then
          REQ_2 <= '0';
          spi_fsm_c <= idle;
        end if;
-------------------------------------------------------------------------------
      when others =>
        spi_fsm_c <= idle;
    end case;
  end process;

  -- sprit output decoder
  binary_bcd_i : binary_bcd
  generic map (
    N => 12
  )
  port map(
    clk       => CLK,
    rst       => RST,
    new_data  => new_data_c,
    binary_in => std_logic_vector(amount_buff_c),
    data_done => bcd_data_done,
    bcd_out   => bcd_out
  );

  -- sprit output decoder for summ
  binary_bcd_20_bit_i : binary_bcd_20_bit
  generic map (
    N => 20
  )
  port map(
    clk       => CLK,
    rst       => RST,
    new_data  => new_summ_s,
    binary_in => std_logic_vector(summ_s),
    data_done => bcd_summ_done,
    bcd_out   => bcd_summ_out
  );
  
  -- User interface
  process(upd_arr_req_s, upd_data_req_s, VGA_RDY, bcd_data_done,
          bcd_summ_out, upd_price_req_s, row_c, row_s, bcd_summ_done, bcd_out,
          upd_summ_req_s, upd_data_s, price_type_c, price_type_s
  ) begin
    upd_arr_c             <= '0';
    upd_data_c            <= '0';
    upd_arr_req_c         <= upd_arr_req_s;
    upd_data_req_c        <= upd_data_req_s;
    upd_summ_req_c        <= upd_summ_req_s;
    upd_price_req_c       <= upd_price_req_s;
    ui_col_c              <= "001";
    ui_row_c              <= row_c;
    char_buff_c(0)        <= bcd_out(0);
    char_buff_c(1)        <= bcd_out(1);
    char_buff_c(2)        <= bcd_out(2);
    char_buff_c(3)        <= bcd_out(3);
    char_buff_c(4 to 11)  <= (others => (others => '0'));

    if(VGA_RDY = '1') then
      -- array update
      if((upd_arr_req_s = '1') or (row_c /= row_s)) then
        upd_arr_req_c <= '0';
        upd_arr_c     <= '1';
      end if;

      -- data update
      if((upd_data_req_s = '1') or (bcd_data_done = '1')) then
        upd_data_req_c <= '0';
        upd_data_c     <= '1';
      end if;

      -- summ update
      if((upd_summ_req_s = '1') or (bcd_summ_done = '1')) then
        if((upd_data_req_s = '1') or (bcd_data_done = '1') or (upd_data_s = '1')) then
          upd_summ_req_c <= '1';
        else
          upd_data_c            <= '1';
          ui_col_c              <= "000";
          ui_row_c              <= TO_UNSIGNED(32, ui_row_c'length);
          char_buff_c(0)        <= x"42"; -- S
          char_buff_c(1)        <= x"44"; -- U
          char_buff_c(2)        <= x"3c"; -- M
          char_buff_c(3)        <= x"29"; -- :
          char_buff_c(4)        <= x"00"; --
          upd_summ_req_c        <= '0';

          for i in 5 to 11 loop
            char_buff_c(i)  <= bcd_summ_out(i-5);
          end loop;
        end if;
      end if;

      -- price update
      if((upd_price_req_s = '1') or (price_type_c /= price_type_s)) then
        if((upd_data_req_s = '1') or (bcd_data_done = '1') or
          (upd_summ_req_s = '1') or (bcd_summ_done = '1') or (upd_data_s = '1')
        )then
          upd_price_req_c <= '1';
        else
          upd_data_c          <= '1';
          ui_col_c            <= "001";
          ui_row_c            <= TO_UNSIGNED(32, ui_row_c'length);
          char_buff_c(1 to 3) <= (others => (others => '0'));
          upd_price_req_c     <= '0';

          case(price_type_c) is
            when "011"  => char_buff_c(0) <= x"49"; -- Employee (Z)
            when "100"  => char_buff_c(0) <= x"34"; -- External (E)
            when others => char_buff_c(0) <= x"42"; -- Student  (S)
          end case;
        end if;
      end if;
    else -- save update requests
      -- array update
      if(row_c /= row_s) then
        upd_arr_req_c <= '1';
      end if;
      -- data update
      if(bcd_data_done = '1') then
        upd_data_req_c <= '1';
      end if;
      --summ update
      if(bcd_summ_done = '1') then
        upd_summ_req_c <= '1';
      end if;
      -- price update
      if(price_type_c /= price_type_s) then
        upd_price_req_c <= '1';
      end if;
    end if;
  end process;

  -- output assignments
  REQ_ROW       <= std_logic_vector(spi_row_s);
  COL           <= std_logic_vector(ui_col_s);
  ROW           <= std_logic_vector(ui_row_s);
  CHAR_BUFF(0)  <= char_buff_s(0);
  CHAR_BUFF(1)  <= char_buff_s(1);
  CHAR_BUFF(2)  <= char_buff_s(2);
  CHAR_BUFF(3)  <= char_buff_s(3);
  CHAR_BUFF(4)  <= char_buff_s(4);
  CHAR_BUFF(5)  <= char_buff_s(5);
  CHAR_BUFF(6)  <= char_buff_s(6);
  CHAR_BUFF(7)  <= char_buff_s(7);
  CHAR_BUFF(8)  <= char_buff_s(8);
  CHAR_BUFF(9)  <= char_buff_s(9);
  CHAR_BUFF(10) <= char_buff_s(10);
  CHAR_BUFF(11) <= char_buff_s(11);
   
  CHAR_BUFF(12 to 31) <= (others => (others => '0'));

  UPD_ARR   <= upd_arr_s;
  UPD_DATA  <= upd_data_s;
  SUMM      <= std_logic_vector(summ_s);

end Behavioral;