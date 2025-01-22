----------------------------------------------------------------------------------
-- ps2_rx.vhd
-- PS2 receiver.
-- 06 Oct, 2024
-- Semestral project in the autumn semester of 2024 in MPC-NDO.
-- Artem Gumenyuk (xgumen00@vutbr.cz)
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.ps2_pkg.all; 

entity ps2_rx is
    Port ( CLK        : in  STD_LOGIC;
           RST        : in  STD_LOGIC;
           PS2_CLK    : in  STD_LOGIC;
           PS2_DATA   : in  STD_LOGIC;
           CODE_READY : out STD_LOGIC;
           PS2_CODE   : out STD_LOGIC_VECTOR (7 downto 0));
end ps2_rx;

architecture Behavioral of ps2_rx is

  -- clock divider
component clk_divider is
    generic (
        IN_FREQ  : positive;
        OUT_FREQ : positive
    );
    port ( CLK        : in  std_logic;
           RST        : in  STD_LOGIC;
           CLK_DIV_EN : out std_logic
    );
end component;

  -- falling edge detector
  component fall_edge_detector is
    Port ( CLK       : in  std_logic;
           RST       : in  STD_LOGIC;
           INP_SIG   : in  std_logic;
           FALL_EDGE : out std_logic
    );
  end component;
  
----------------------------------------------------------------------------------
  signal clk_div_en  : std_logic;
  signal ps2_clk_deb : std_logic := '0';
  signal ps2_clk_fe  : std_logic;
  signal ps2_clk_reg : std_logic_vector(3 downto 0) := (others => '0');
----------------------------------------------------------------------------------
  signal fsm_c            : t_fsm_ps2rx;
  signal fsm_s            : t_fsm_ps2rx := idle;
  signal ps2_data_parity  : std_logic;
  signal ps2_data_c       : std_logic_vector(7 downto 0);
  signal ps2_data_s       : std_logic_vector(7 downto 0) := (others => '0');
  signal data_cnt_c       : unsigned(3 downto 0);
  signal data_cnt_s       : unsigned(3 downto 0) := (others => '0');
  signal code_ready_c     : std_logic;
  signal code_ready_s     : std_logic := '0';
  
begin

-- divide the clock for debouncer
  clk_div_i: clk_divider
    generic map ( IN_FREQ  => 30, -- 30 MHz
                  OUT_FREQ => 1  --  1 MHz
                )
    port map  ( CLK        => CLK,
                RST        => RST,
                CLK_DIV_EN => clk_div_en
              );
         
-- PS2_clk signal debouncer
  process(clk, rst) begin
    if(rst = '1') then
      ps2_clk_reg <= (others => '0');
      ps2_clk_deb <= '0';
    elsif(rising_edge(clk)) then
      if(clk_div_en = '1') then
        ps2_clk_reg <= PS2_CLK & ps2_clk_reg(3 downto 1);
        
        if(ps2_clk_reg = "1111") then
          ps2_clk_deb <= '1';
        elsif(ps2_clk_reg = "0000") then
          ps2_clk_deb <= '0';
        end if;
      end if;
    end if;
  end process;
  
-- detect falling edge of debounces PS2 CLK signal
  fall_edge_det_i: fall_edge_detector
    port map  ( CLK       => CLK,
                RST       => RST,
                INP_SIG   => ps2_clk_deb,
                FALL_EDGE => ps2_clk_fe
              );
              
----------------------------------------------------------------------------------

  process(clk, rst) begin
    if(rst = '1') then
      fsm_s        <= idle;
      ps2_data_s   <= (others => '0');
      data_cnt_s   <= (others => '0');
      code_ready_s <= '0';
    elsif(rising_edge(clk)) then
      fsm_s        <= fsm_c;
      ps2_data_s   <= ps2_data_c;
      data_cnt_s   <= data_cnt_c;
      code_ready_s <= code_ready_c;
    end if;
  end process;
  
  process(fsm_s, ps2_clk_fe, PS2_DATA, data_cnt_s, ps2_data_s, code_ready_s, ps2_data_parity) begin
    data_cnt_c   <= data_cnt_s;
    ps2_data_c   <= ps2_data_s;
    fsm_c        <= fsm_s;
    code_ready_c <= code_ready_s;
    
    case(fsm_s) is
      when idle =>
        data_cnt_c   <= (others => '0');
        code_ready_c <= '0';
        
        if((ps2_clk_fe = '1') and (PS2_DATA = '0')) then
          ps2_data_c <= (others => '0');
          fsm_c <= receive;
        end if;
      when receive =>
        if(ps2_clk_fe = '1') then
          ps2_data_c <= PS2_DATA & ps2_data_s(7 downto 1);
          data_cnt_c <= data_cnt_s + 1;
        end if;
        if(data_cnt_s = 8) then
          fsm_c <= parity;
        end if;
      when parity =>
        if(ps2_clk_fe = '1') then
          if(PS2_DATA = ps2_data_parity) then
            fsm_c <= stop;
          else
            fsm_c <= idle;
          end if;
        end if;
      when stop =>
        if(ps2_clk_fe = '1') then
          fsm_c <= idle;
          if(PS2_DATA = '1') then
            code_ready_c <= '1';
          end if;
        end if;
    end case;
  end process;
  
  ps2_data_parity <= not (ps2_data_s(0) xor ps2_data_s(1) xor ps2_data_s(2) xor ps2_data_s(3) xor ps2_data_s(4) xor ps2_data_s(5) xor ps2_data_s(6) xor ps2_data_s(7));
  PS2_CODE        <= ps2_data_s;
  CODE_READY      <= code_ready_s;

end Behavioral;
