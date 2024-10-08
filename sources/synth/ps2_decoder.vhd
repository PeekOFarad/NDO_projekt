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

entity ps2_decoder is
    Port ( CLK        : in STD_LOGIC;
           CODE_READY : in STD_LOGIC;
           PS2_CODE   : in STD_LOGIC_VECTOR(7 downto 0);
           KEYS       : out t_keys);
end ps2_decoder;

architecture Behavioral of ps2_decoder is

  signal fsm_c, fsm_s           : t_fsm_dekoder;
  signal keys_c, keys_s         : t_keys;
  
begin

  process(clk) begin
    if(rising_edge(CLK)) then
      fsm_s  <= fsm_c;
      keys_s <= keys_c;
    end if;
  end process;
  
  process(fsm_s, PS2_CODE, CODE_READY) begin
    fsm_c  <= fsm_s;
    keys_c <= keys_s;
    
    case(fsm_s) is
        when idle =>
          keys_c <= (others => '0');
          
          if(CODE_READY = '1') then
            if(PS2_CODE = c_e0) then
              fsm_c <= special_code;
            elsif((PS2_CODE = c_esc) or (PS2_CODE = c_enter)) then
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
            if((PS2_CODE = c_up) or (PS2_CODE = c_down) or (PS2_CODE = c_del)) then
              fsm_c <= set_key;
            else
              fsm_c <= idle;
            end if;
          end if;
        when set_key =>
          case(PS2_CODE) is
            when c_up    => keys_c.up    <= '1';
            when c_down  => keys_c.down  <= '1';
            when c_del   => keys_c.del   <= '1';
            when c_esc   => keys_c.esc   <= '1';
            when c_enter => keys_c.enter <= '1';
            when others  =>
          end case;
          
          fsm_c <= idle;
    end case;
  end process;
  
  KEYS <= keys_s;

end Behavioral;
