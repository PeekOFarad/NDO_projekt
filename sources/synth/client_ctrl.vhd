----------------------------------------------------------------------------------
-- client_ctrl.vhd
-- Client part controller
-- 25 Nov, 2024
-- Semestral project in the autumn semester of 2024 in MPC-NDO.
-- Artem Gumenyuk (xgumen00@vutbr.cz)
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.server_pkg.all;
use work.common_pkg.all;

entity client_ctrl is
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
           -- from/to UI_ADAPTER
           VGA_RDY   : in STD_LOGIC;
           UPD_DATA  : out STD_LOGIC;
           COL       : out STD_LOGIC_VECTOR (2 downto 0);
           ROW       : out STD_LOGIC_VECTOR (5 downto 0);
           CHAR_BUFF : out char_buff_t;
           -- from/to bus_arbiter
           RW       : out STD_LOGIC;
           COL_OUT  : out STD_LOGIC_VECTOR (2 downto 0);
           ROW_OUT  : out STD_LOGIC_VECTOR (5 downto 0);
           REQ      : out STD_LOGIC;
           ACK      : in STD_LOGIC;
           DIN      : in STD_LOGIC_VECTOR (11 downto 0);
           DOUT     : out STD_LOGIC_VECTOR (11 downto 0)
        );
end client_ctrl;

architecture Behavioral of client_ctrl is

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
  end component ;

-------------------------------------------------------------------------------

  type fsm_t IS(cfg, wait4ack);

  signal fsm_c : fsm_t;
  signal fsm_s : fsm_t := cfg;

  signal tx_data_c : std_logic_vector (g_DATA_WIDTH-1 downto 0);
  signal tx_data_s : std_logic_vector (g_DATA_WIDTH-1 downto 0) := (others => '0');

  signal upd_data_c : std_logic;
  signal upd_data_s : std_logic := '0';

  signal upd_data_req_c : std_logic;
  signal upd_data_req_s : std_logic := '0';

  signal col_c : std_logic_vector (2 downto 0);
  signal col_s : std_logic_vector (2 downto 0) := (others => '0');

  signal row_c : std_logic_vector (5 downto 0);
  signal row_s : std_logic_vector (5 downto 0) := (others => '0');

  signal last_col_c : std_logic_vector (2 downto 0);
  signal last_col_s : std_logic_vector (2 downto 0) := (others => '0');

  signal last_row_c : std_logic_vector (5 downto 0);
  signal last_row_s : std_logic_vector (5 downto 0) := (others => '0');

  signal char_buff_c : char_buff_t;
  signal char_buff_s : char_buff_t := (others => (others => '0'));

  -- frame parts
  signal frm_rw   : std_logic;
  signal frm_col  : std_logic_vector (2 downto 0);
  signal frm_row  : std_logic_vector (5 downto 0);
  signal frm_data : std_logic_vector (11 downto 0);
  signal frm_par  : std_logic;

  -- cell characters counter
  signal ch_cnt_c : unsigned (4 downto 0); 
  signal ch_cnt_s : unsigned (4 downto 0) := (others => '0');

  -- binary to BCD
  signal new_data_c  : STD_LOGIC;
  signal data_done_c : STD_LOGIC;
  signal bcd_out     : digit_arr_t;

  -- bus arbiter related signals
  signal rw_c : STD_LOGIC;
  signal rw_s : STD_LOGIC := '1';

begin

  process(CLK, RST) begin
    if(RST = '1') then
      fsm_s           <= cfg;
      upd_data_s      <= '0';
      col_s           <= (others => '0');
      last_col_s      <= (others => '0');
      row_s           <= (others => '0');
      last_row_s      <= (others => '0');
      char_buff_s     <= (others => (others => '0'));
      ch_cnt_s        <= (others => '0');
      rw_s            <= '1';
      upd_data_req_s  <= '0';
    elsif(rising_edge(CLK)) then
      fsm_s           <= fsm_c;
      upd_data_s      <= upd_data_c;
      col_s           <= col_c;
      last_col_s      <= last_col_c;
      row_s           <= row_c;
      last_row_s      <= last_row_c;
      char_buff_s     <= char_buff_c;
      ch_cnt_s        <= ch_cnt_c;
      rw_s            <= rw_c;
      upd_data_req_s  <= upd_data_req_c;
    end if;
  end process;

  process(fsm_s, frm_col, frm_row, frm_data, upd_data_s, col_s, row_s, char_buff_s, ch_cnt_s,
          DATA_RDY, data_done_c, bcd_out, ACK, rw_s, last_col_s, last_row_s, upd_data_req_s, VGA_RDY) begin
    fsm_c           <= fsm_s;
    upd_data_c      <= '0';
    col_c           <= col_s;
    last_col_c      <= last_col_s;
    row_c           <= row_s;
    last_row_c      <= last_row_s;
    char_buff_c     <= char_buff_s;
    ch_cnt_c        <= ch_cnt_s;
    new_data_c      <= '0';
    RW              <= '1';
    REQ             <= '0';
    rw_c            <= rw_s;

    if(VGA_RDY = '1' and upd_data_req_s = '1') then -- set UPD_DATA if request is active and clear request
      upd_data_c     <= '1';
      upd_data_req_c <= '0';
    else
      upd_data_req_c  <= upd_data_req_s; -- wait
    end if;

    case(fsm_s) is
-------------------------------------------------------------------------------
      when cfg =>

        if(DATA_RDY = '1') then
          -- save last position of cursor
          last_col_c <= col_s;
          last_row_c <= row_s;
          
          -- clear char buffer if cell is changed
          if((frm_col /= last_col_s) or (frm_row /= last_row_s)) then
            char_buff_c <= (others => (others => '0'));
          end if;

          if(frm_col = "000") then -- char
            col_c      <= frm_col;
            row_c      <= frm_row;

            if((frm_col = col_s) and (frm_row = row_s)) then
              ch_cnt_c <= ch_cnt_s + 1;
              char_buff_c(TO_INTEGER(ch_cnt_s)) <= frm_data(7 downto 0);
            else
              ch_cnt_c <= (others => '0');
              char_buff_c(0) <= frm_data(7 downto 0);
            end if;

            -- assign UPD_DATA if VGA is ready, else save a request and wait
            if(VGA_RDY = '1') then
              upd_data_c <= '1';
            else
              upd_data_req_c <= '1';
            end if;
          else -- number
            new_data_c <= '1';
          end if;
        elsif(data_done_c = '1') then
          col_c          <= frm_col;
          row_c          <= frm_row;
          char_buff_c(0) <= bcd_out(0);
          char_buff_c(1) <= bcd_out(1);
          char_buff_c(2) <= bcd_out(2);
          char_buff_c(3) <= bcd_out(3);

          -- assign UPD_DATA if VGA is ready, else save a request and wait
          if(VGA_RDY = '1') then
            upd_data_c <= '1';
          else
            upd_data_req_c <= '1';
          end if;
          
          -- save number to the register
          fsm_c   <= wait4ack;
          RW      <= '0';
          rw_c    <= '0';
          REQ     <= '1';
        end if;
-------------------------------------------------------------------------------
      when wait4ack =>
        REQ     <= '1';
        RW      <= rw_s;

        if(ACK = '1') then
          fsm_c <= cfg;
        end if;
    end case;
  end process;

  -- divide frame on parts
  frm_rw   <= RX_DATA(0);
  frm_col  <= RX_DATA(3 downto 1);
  frm_row  <= RX_DATA(9 downto 4);
  frm_data <= RX_DATA(21 downto 10);
  frm_par  <= RX_DATA(22);

  -- sprit output decoder
  binary_bcd_i : binary_bcd
  generic map (
    N => 12
  )
  port map(
    clk       => CLK,
    rst       => RST,
    new_data  => new_data_c,
    binary_in => frm_data,
    data_done => data_done_c,
    bcd_out   => bcd_out
  );
  
  -- output assignments
  UPD_DATA    <= upd_data_s;
  COL         <= col_s;
  ROW         <= row_s;
  CHAR_BUFF   <= char_buff_s;
  COL_OUT     <= col_s;
  ROW_OUT     <= row_s;
  DOUT        <= frm_data;

end Behavioral;