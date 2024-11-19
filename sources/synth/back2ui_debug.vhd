
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity back2ui_debug is
    Port ( CLK : in STD_LOGIC;
           RST : in STD_LOGIC;
           UPD_ARR : in STD_LOGIC;
           UPD_DATA : in STD_LOGIC;
           LED0 : out STD_LOGIC;
           LED1 : out STD_LOGIC);
end back2ui_debug;

architecture Behavioral of back2ui_debug is

  type t_fsm is (idle, wait4cnt);

  signal cnt_c : unsigned(25 downto 0);
  signal cnt_s : unsigned(25 downto 0) := (others => '0');

  signal fsm_c : t_fsm;
  signal fsm_s : t_fsm := idle;

  signal led0_c, led1_c : std_logic;
  signal led0_s, led1_s : std_logic := '0';

begin

  process(CLK, RST) begin
    if(RST = '1') then
      fsm_s  <= idle;
      cnt_s  <= (others => '0');
      led0_s <= '0';
      led1_s <= '0';
    elsif(rising_edge(CLK)) then
      fsm_s  <= fsm_c;
      cnt_s  <= cnt_c;
      led0_s <= led0_c;
      led1_s <= led1_c;
    end if;
  end process;

  process(UPD_ARR, UPD_DATA, fsm_s, cnt_s, led0_s, led1_s) begin
    fsm_c  <= fsm_s;
    cnt_c  <= cnt_s;
    led0_c <= led0_s;
    led1_c <= led1_s;

    case(fsm_s) is
      when idle =>
        led0_c <= '0';
        led1_c <= '0';
        cnt_c  <= (others => '0');

        if(UPD_ARR = '1') then
          led0_c <= '1';
          fsm_c <= wait4cnt;
        end if;
        if(UPD_DATA = '1') then
          led1_c <= '1';
          fsm_c <= wait4cnt;
        end if;
      when wait4cnt =>
        cnt_c <= cnt_s + 1;
        if(cnt_s = x"3FFFFFF") then
          fsm_c <= idle;
        end if;
      when others =>
        fsm_c <= idle;
        cnt_c <= (others => '0');
        led0_c <= '0';
        led1_c <= '0';
    end case;
  end process;

  LED0 <= led0_s;
  LED1 <= led1_s;

end Behavioral;
