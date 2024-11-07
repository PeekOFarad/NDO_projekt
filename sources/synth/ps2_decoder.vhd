----------------------------------------------------------------------------------
-- ps2_decoder.vhd
-- PS2 output decoder.
-- 06 Oct, 2024
-- Semestral project in the autumn semester of 2024 in MPC-NDO.
-- Artem Gumenyuk (xgumen00@vutbr.cz)
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.ps2_pkg.all;
use IEEE.NUMERIC_STD.ALL;

entity ps2_decoder is
    Port ( CLK        : in  STD_LOGIC;
           CODE_READY : in  STD_LOGIC;
           PS2_CODE   : in  STD_LOGIC_VECTOR(7 downto 0);
           NUMBER     : out STD_LOGIC_VECTOR(3 downto 0);
           KEYS       : out t_keys);
end ps2_decoder;

architecture Behavioral of ps2_decoder is

  signal fsm_c, fsm_s    : t_fsm_dekoder;
  signal keys_c, keys_s  : t_keys;
  signal number_c        : unsigned(3 downto 0);
  signal number_s        : unsigned(3 downto 0) := (others => '0');
  
begin

  process(clk) begin
    if(rising_edge(CLK)) then
      fsm_s  <= fsm_c;
      keys_s <= keys_c;
      number_s <= number_c;
    end if;
  end process;
  
  process(fsm_s, PS2_CODE, CODE_READY) begin
    fsm_c    <= fsm_s;
    keys_c   <= keys_s;
    number_c <= number_s;
    
    case(fsm_s) is
        when idle =>
          keys_c <= (others => '0');
          
          if(CODE_READY = '1') then
            if(PS2_CODE = c_e0) then
              fsm_c <= special_code;
            elsif((PS2_CODE = c_esc) or (PS2_CODE = c_enter) or (PS2_CODE = c_bckspc) or
            ((unsigned(PS2_CODE) >= unsigned(c_q)) and (unsigned(PS2_CODE) < unsigned(c_shft))))
            then
              fsm_c <= set_key;
            elsif(PS2_CODE = c_f0) then
              fsm_c <= end_code;
            end if;
          end if;
        when end_code =>
          if(CODE_READY = '1') then
            fsm_c <= idle;
          end if;
        when special_code =>
          if(CODE_READY = '1') then
            if((PS2_CODE = c_left) or (PS2_CODE = c_right) or (PS2_CODE = c_up) or
               (PS2_CODE = c_down) or (PS2_CODE = c_del)) then
              fsm_c <= set_key;
            else
              fsm_c <= idle;
            end if;
          end if;
        when set_key =>
          case(PS2_CODE) is
            when c_up     => keys_c.up     <= '1';
            when c_down   => keys_c.down   <= '1';
            when c_left   => keys_c.left   <= '1';
            when c_right  => keys_c.right  <= '1';
            when c_del    => keys_c.del    <= '1';
            when c_bckspc => keys_c.bckspc <= '1';
            when c_esc    => keys_c.esc    <= '1';
            when c_enter  => keys_c.enter  <= '1';
            when c_0      => keys_c.number <= '1'; number_c <= TO_UNSIGNED(0, 4);
            when c_1      => keys_c.number <= '1'; number_c <= TO_UNSIGNED(1, 4);
            when c_2      => keys_c.number <= '1'; number_c <= TO_UNSIGNED(2, 4);
            when c_3      => keys_c.number <= '1'; number_c <= TO_UNSIGNED(3, 4);
            when c_4      => keys_c.number <= '1'; number_c <= TO_UNSIGNED(4, 4);
            when c_5      => keys_c.number <= '1'; number_c <= TO_UNSIGNED(5, 4);
            when c_6      => keys_c.number <= '1'; number_c <= TO_UNSIGNED(6, 4);
            when c_7      => keys_c.number <= '1'; number_c <= TO_UNSIGNED(7, 4);
            when c_8      => keys_c.number <= '1'; number_c <= TO_UNSIGNED(8, 4);
            when c_9      => keys_c.number <= '1'; number_c <= TO_UNSIGNED(9, 4);
            when others   =>
              if((unsigned(PS2_CODE) >= unsigned(c_q)) and
                (unsigned(PS2_CODE) < unsigned(c_shft)) and not(keys_c.number = '1')) then
                keys_c.char <= '1';
              end if;
          end case;
          
          fsm_c <= idle;
    end case;
  end process;
  
  KEYS   <= keys_s;
  NUMBER <= std_logic_vector(number_s);

end Behavioral;
