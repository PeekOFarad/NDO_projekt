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
use IEEE.NUMERIC_STD.ALL;
use IEEE.math_real.all;

entity ui_adapter is
    Generic (
           g_FOOD_CNT     : positive;
           g_CLIENTS_CNT  : positive;
           g_NODE_WIDTH   : positive
    );
    Port ( CLK          : in STD_LOGIC;
           RST          : in STD_LOGIC;
           EDIT_ENA     : in STD_LOGIC;
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
           DATA_OUT     : out sprit_buff_t);
end ui_adapter;

architecture Behavioral of ui_adapter is

  type t_fsm_ui_adapter is (cfg, node_upd, run, read);

  signal fsm_c : t_fsm_ui_adapter;
  signal fsm_s : t_fsm_ui_adapter := cfg;

  signal node_sel_s : STD_LOGIC_VECTOR(g_NODE_WIDTH-1 downto 0);

  signal cnt_c : UNSIGNED(4 downto 0);
  signal cnt_s : UNSIGNED(4 downto 0) := (others => '0');

  signal row_in_s : STD_LOGIC_VECTOR (5 downto 0) := (others => '0');
  signal smp_row_ena : STD_LOGIC;
  
  signal digit : digit_t; 

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
          ROW_IN, NODE_SEL, node_sel_s, ACK, row_in_s) begin
    fsm_c        <= fsm_s;
    cnt_c        <= cnt_s;
    UPD_DATA_OUT <= '0';
    UPD_ARR_OUT  <= '0';
    smp_row_ena  <= '0';

    case(fsm_s) is
      when cfg =>
        COL_OUT      <= COL_IN;
        ROW_OUT      <= ROW_IN;
        UPD_ARR_OUT  <= UPD_ARR_IN;
        UPD_DATA_OUT <= UPD_DATA_IN;
        REQ          <= '0';

        if(node_sel_s /= NODE_SEL) then
          fsm_c <= node_upd;
        end if;
        if(EDIT_ENA = '0') then
          fsm_c <= run;
        end if;

      when node_upd =>
        COL_OUT <= "001"; -- select amount column
        ROW_OUT <= '0' & std_logic_vector(cnt_s);
        RW      <= '1';
        REQ     <= '1';

        if(cnt_s = 31) then
          REQ   <= '0';
          cnt_c <= (others => '0');

          if(EDIT_ENA = '0') then
            fsm_c <= run;
          else
            fsm_c <= cfg;
          end if;
        elsif(ACK = '1') then
          UPD_DATA_OUT <= '1';
          cnt_c <= cnt_s + 1;
        end if;
      
        when run =>
          COL_OUT <= "001"; -- select amount column
          ROW_OUT <= ROW_IN;
          RW      <= '1';

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
          RW      <= '1';
          REQ   <= '1';

          if(ACK = '1') then
            REQ          <= '0';
            UPD_DATA_OUT <= '1';
            fsm_c <= run;
          end if;
    end case;
  end process;
      
  -- sprit output decoder
  process(EDIT_ENA, fsm_s, CHAR_BUFF, DIN, digit) begin
    if((EDIT_ENA = '1') and (fsm_s = cfg)) then -- PS2 to sprit ID
      for i in 0 to (g_FOOD_CNT - 1) loop
        case(CHAR_BUFF(i)) is
          when c_0 => DATA_OUT(i) <= STD_LOGIC_VECTOR(TO_UNSIGNED(16#20#, 8));
          when c_1 => DATA_OUT(i) <= STD_LOGIC_VECTOR(TO_UNSIGNED(16#21#, 8));
          when c_2 => DATA_OUT(i) <= STD_LOGIC_VECTOR(TO_UNSIGNED(16#22#, 8));
          when c_3 => DATA_OUT(i) <= STD_LOGIC_VECTOR(TO_UNSIGNED(16#23#, 8));
          when c_4 => DATA_OUT(i) <= STD_LOGIC_VECTOR(TO_UNSIGNED(16#24#, 8));
          when c_5 => DATA_OUT(i) <= STD_LOGIC_VECTOR(TO_UNSIGNED(16#25#, 8));
          when c_6 => DATA_OUT(i) <= STD_LOGIC_VECTOR(TO_UNSIGNED(16#26#, 8));
          when c_7 => DATA_OUT(i) <= STD_LOGIC_VECTOR(TO_UNSIGNED(16#27#, 8));
          when c_8 => DATA_OUT(i) <= STD_LOGIC_VECTOR(TO_UNSIGNED(16#28#, 8));
          when c_9 => DATA_OUT(i) <= STD_LOGIC_VECTOR(TO_UNSIGNED(16#29#, 8));
          when c_min => DATA_OUT(i) <= STD_LOGIC_VECTOR(TO_UNSIGNED(16#1D#, 8));
          when c_eq => DATA_OUT(i) <= STD_LOGIC_VECTOR(TO_UNSIGNED(16#2D#, 8));
          when c_a => DATA_OUT(i) <= STD_LOGIC_VECTOR(TO_UNSIGNED(16#31#, 8));
          when c_b => DATA_OUT(i) <= STD_LOGIC_VECTOR(TO_UNSIGNED(16#32#, 8));
          when c_c => DATA_OUT(i) <= STD_LOGIC_VECTOR(TO_UNSIGNED(16#33#, 8));
          when c_d => DATA_OUT(i) <= STD_LOGIC_VECTOR(TO_UNSIGNED(16#34#, 8));
          when c_e => DATA_OUT(i) <= STD_LOGIC_VECTOR(TO_UNSIGNED(16#35#, 8));
          when c_f => DATA_OUT(i) <= STD_LOGIC_VECTOR(TO_UNSIGNED(16#36#, 8));
          when c_g => DATA_OUT(i) <= STD_LOGIC_VECTOR(TO_UNSIGNED(16#37#, 8));
          when c_h => DATA_OUT(i) <= STD_LOGIC_VECTOR(TO_UNSIGNED(16#38#, 8));
          when c_i => DATA_OUT(i) <= STD_LOGIC_VECTOR(TO_UNSIGNED(16#39#, 8));
          when c_j => DATA_OUT(i) <= STD_LOGIC_VECTOR(TO_UNSIGNED(16#3A#, 8));
          when c_k => DATA_OUT(i) <= STD_LOGIC_VECTOR(TO_UNSIGNED(16#3B#, 8));
          when c_l => DATA_OUT(i) <= STD_LOGIC_VECTOR(TO_UNSIGNED(16#3C#, 8));
          when c_m => DATA_OUT(i) <= STD_LOGIC_VECTOR(TO_UNSIGNED(16#3D#, 8));
          when c_n => DATA_OUT(i) <= STD_LOGIC_VECTOR(TO_UNSIGNED(16#3E#, 8));
          when c_o => DATA_OUT(i) <= STD_LOGIC_VECTOR(TO_UNSIGNED(16#3F#, 8));
          when c_p => DATA_OUT(i) <= STD_LOGIC_VECTOR(TO_UNSIGNED(16#40#, 8));
          when c_q => DATA_OUT(i) <= STD_LOGIC_VECTOR(TO_UNSIGNED(16#41#, 8));
          when c_r => DATA_OUT(i) <= STD_LOGIC_VECTOR(TO_UNSIGNED(16#42#, 8));
          when c_s => DATA_OUT(i) <= STD_LOGIC_VECTOR(TO_UNSIGNED(16#43#, 8));
          when c_t => DATA_OUT(i) <= STD_LOGIC_VECTOR(TO_UNSIGNED(16#44#, 8));
          when c_u => DATA_OUT(i) <= STD_LOGIC_VECTOR(TO_UNSIGNED(16#45#, 8));
          when c_v => DATA_OUT(i) <= STD_LOGIC_VECTOR(TO_UNSIGNED(16#46#, 8));
          when c_w => DATA_OUT(i) <= STD_LOGIC_VECTOR(TO_UNSIGNED(16#47#, 8));
          when c_x => DATA_OUT(i) <= STD_LOGIC_VECTOR(TO_UNSIGNED(16#48#, 8));
          when c_y => DATA_OUT(i) <= STD_LOGIC_VECTOR(TO_UNSIGNED(16#49#, 8));
          when c_z => DATA_OUT(i) <= STD_LOGIC_VECTOR(TO_UNSIGNED(16#4A#, 8));
          when c_lbr => DATA_OUT(i) <= STD_LOGIC_VECTOR(TO_UNSIGNED(16#4B#, 8));
          when c_rbr => DATA_OUT(i) <= STD_LOGIC_VECTOR(TO_UNSIGNED(16#4D#, 8));
          when c_bcksl => DATA_OUT(i) <= STD_LOGIC_VECTOR(TO_UNSIGNED(16#4C#, 8));
          when c_semi => DATA_OUT(i) <= STD_LOGIC_VECTOR(TO_UNSIGNED(16#2B#, 8));
          when c_ap => DATA_OUT(i) <= STD_LOGIC_VECTOR(TO_UNSIGNED(16#17#, 8));
          when c_col => DATA_OUT(i) <= STD_LOGIC_VECTOR(TO_UNSIGNED(16#1C#, 8));
          when c_dot => DATA_OUT(i) <= STD_LOGIC_VECTOR(TO_UNSIGNED(16#1E#, 8));
          when c_slsh => DATA_OUT(i) <= STD_LOGIC_VECTOR(TO_UNSIGNED(16#1F#, 8));
          when others => DATA_OUT(i) <= "00000000";
        end case;
      end loop;
    else -- decimal number to sprit ID
      for i in 0 to 3 loop
        digit(i) <= (UNSIGNED(DIN) / 10**i) rem 10;
        if((i = 0) or (to_integer(digit(i)) /= 0)) then
          case(to_integer(digit(i))) is
            when 0 => DATA_OUT(i) <= STD_LOGIC_VECTOR(TO_UNSIGNED(16#20#, 8));
            when 1 => DATA_OUT(i) <= STD_LOGIC_VECTOR(TO_UNSIGNED(16#21#, 8));
            when 2 => DATA_OUT(i) <= STD_LOGIC_VECTOR(TO_UNSIGNED(16#22#, 8));
            when 3 => DATA_OUT(i) <= STD_LOGIC_VECTOR(TO_UNSIGNED(16#23#, 8));
            when 4 => DATA_OUT(i) <= STD_LOGIC_VECTOR(TO_UNSIGNED(16#24#, 8));
            when 5 => DATA_OUT(i) <= STD_LOGIC_VECTOR(TO_UNSIGNED(16#25#, 8));
            when 6 => DATA_OUT(i) <= STD_LOGIC_VECTOR(TO_UNSIGNED(16#26#, 8));
            when 7 => DATA_OUT(i) <= STD_LOGIC_VECTOR(TO_UNSIGNED(16#27#, 8));
            when 8 => DATA_OUT(i) <= STD_LOGIC_VECTOR(TO_UNSIGNED(16#28#, 8));
            when 9 => DATA_OUT(i) <= STD_LOGIC_VECTOR(TO_UNSIGNED(16#29#, 8));
            when others => DATA_OUT(i) <= "00000000";
          end case;
        else
          DATA_OUT(i) <= "00000000";
        end if;
      end loop;
    end if;
  end process;

end Behavioral;
