----------------------------------------------------------------------------------
-- ui_adapter.vhd
-- Server part User Interface adapter
-- 31 Oct, 2024
-- Semestral project in the autumn semester of 2024 in MPC-NDO.
-- Artem Gumenyuk (xgumen00@vutbr.cz)
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.ps2_pkg.all;
use work.server_pkg.all;
use work.common_pkg.all;
use IEEE.NUMERIC_STD.ALL;
use IEEE.math_real.all;

entity ui_adapter is
    Generic (
           g_FOOD_CNT     : positive := c_FOOD_CNT;
           g_CLIENTS_CNT  : positive := c_CLIENTS_CNT;
           g_NODE_WIDTH   : positive := c_NODE_WIDTH
    );
    Port ( CLK          : in STD_LOGIC;
           RST          : in STD_LOGIC;
           EDIT_ENA     : in STD_LOGIC;
           VGA_RDY      : in STD_LOGIC;
           UPD_ARR_IN   : in STD_LOGIC;
           UPD_DATA_IN  : in STD_LOGIC;
           ACK          : in STD_LOGIC;
           COL_IN       : in STD_LOGIC_VECTOR (2 downto 0);
           ROW_IN       : in STD_LOGIC_VECTOR (5 downto 0);
           CHAR_BUFF    : in char_buff_t;
           NODE_SEL     : in STD_LOGIC_VECTOR(g_NODE_WIDTH-1 downto 0);
           DIN          : in STD_LOGIC_VECTOR (11 downto 0);
           REQ          : out STD_LOGIC;
           RW           : out STD_LOGIC;
           UPD_ARR_OUT  : out STD_LOGIC;
           UPD_DATA_OUT : out STD_LOGIC;
           COL_OUT      : out STD_LOGIC_VECTOR (2 downto 0);
           ROW_OUT      : out STD_LOGIC_VECTOR (5 downto 0);
           DATA_OUT     : out char_buff_t);
end ui_adapter;

architecture Behavioral of ui_adapter is

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

  type t_fsm_ui_adapter is (cfg, node_upd, wait4BCD, run, read);

  signal fsm_c : t_fsm_ui_adapter;
  signal fsm_s : t_fsm_ui_adapter := cfg;

  signal node_sel_s : STD_LOGIC_VECTOR(g_NODE_WIDTH-1 downto 0) := (others => '0');

  signal cnt_c : UNSIGNED(5 downto 0);
  signal cnt_s : UNSIGNED(5 downto 0) := (others => '0');

  signal row_in_s : STD_LOGIC_VECTOR (5 downto 0) := (others => '0');
  signal smp_row_ena : STD_LOGIC;
  
-------------------------------------------------------------------------------
-- binary to BCD
  signal new_data_c  : STD_LOGIC;
  signal data_done_c : STD_LOGIC;
  signal bcd_out     : digit_arr_t;

begin

  process(CLK, RST) begin
    if(RST = '1') then
      fsm_s      <= cfg;
      node_sel_s <= (others => '0');
      cnt_s      <= (others => '0');
      row_in_s   <= (others => '0');
    elsif(rising_edge(CLK)) then
      fsm_s      <= fsm_c;
      node_sel_s <= NODE_SEL;
      cnt_s      <= cnt_c;
      if(smp_row_ena = '1') then
        row_in_s   <= ROW_IN;
      end if;
    end if;
  end process;

  process(fsm_s, cnt_s, EDIT_ENA, UPD_ARR_IN, UPD_DATA_IN, COL_IN,
          ROW_IN, NODE_SEL, node_sel_s, ACK, row_in_s, data_done_c) begin
    fsm_c        <= fsm_s;
    cnt_c        <= cnt_s;
    UPD_DATA_OUT <= '0';
    UPD_ARR_OUT  <= '0';
    smp_row_ena  <= '0';
    REQ          <= '0';
    RW           <= '1';
    new_data_c   <= '0';

    case(fsm_s) is
      when cfg =>
        COL_OUT      <= COL_IN;
        ROW_OUT      <= ROW_IN;
        UPD_ARR_OUT  <= UPD_ARR_IN;
        UPD_DATA_OUT <= UPD_DATA_IN;

        if(node_sel_s /= NODE_SEL) then
          fsm_c <= node_upd;
        end if;
        if(EDIT_ENA = '0') then
          fsm_c <= run;
        end if;

      when node_upd =>
        if(VGA_RDY = '1') then -- wait for VGA ready
          COL_OUT <= "001"; -- select amount column
          ROW_OUT <= std_logic_vector(cnt_s);
          REQ     <= '1';

          if(cnt_s = 32) then
            REQ   <= '0';
            cnt_c <= (others => '0');

            if(EDIT_ENA = '0') then
              fsm_c <= run;
            else
              fsm_c <= cfg;
            end if;
          elsif(ACK = '1') then
            new_data_c <= '1';
            fsm_c      <= wait4BCD;
          end if;
        end if;
      when wait4BCD =>
        if(data_done_c = '1') then
          cnt_c <= cnt_s + 1;
          UPD_DATA_OUT <= '1';
          fsm_c        <= node_upd;
        end if;

      when run =>
        COL_OUT <= "001"; -- select amount column
        ROW_OUT <= ROW_IN;

        if(EDIT_ENA = '1') then
          fsm_c <= cfg;
        elsif(UPD_DATA_IN = '1') then
          fsm_c <= read;
          REQ   <= '1';
          smp_row_ena <= '1';
        end if;
        
      when read =>
        COL_OUT <= "001"; -- select amount column
        ROW_OUT <= row_in_s;
        REQ   <= '1';

        if(ACK = '1') then
          REQ          <= '0';
          UPD_DATA_OUT <= '1';
          fsm_c <= run;
        end if;
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
    binary_in => DIN,
    data_done => data_done_c,
    bcd_out   => bcd_out
  );

  process(EDIT_ENA, fsm_s, CHAR_BUFF, bcd_out) begin
    DATA_OUT <= (others => (others => '0'));

    if((EDIT_ENA = '1') and (fsm_s = cfg)) then
      DATA_OUT <= CHAR_BUFF;
    else -- decimal number to sprit ID
      for i in 0 to 3 loop
        DATA_OUT(i) <= bcd_out(3 - i);
      end loop;
    end if;
  end process;

end Behavioral;
