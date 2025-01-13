----------------------------------------------------------------------------------
-- server_regs_if.vhd
-- Server part registers interface.
-- 26 Oct, 2024
-- Semestral project in the autumn semester of 2024 in MPC-NDO.
-- Artem Gumenyuk (xgumen00@vutbr.cz)
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.server_pkg.all;
use work.common_pkg.all;
use IEEE.NUMERIC_STD.ALL;

entity server_regs_if is
    Generic (
           g_FOOD_CNT     : positive;
           g_CLIENTS_CNT  : positive;
           g_NODE_WIDTH   : positive
    );
    Port ( CLK      : in STD_LOGIC;
           RST      : in STD_LOGIC;
           RW       : in STD_LOGIC;
           COL      : in STD_LOGIC_VECTOR (2 downto 0);
           ROW      : in STD_LOGIC_VECTOR (5 downto 0);
           NODE     : in STD_LOGIC_VECTOR (g_NODE_WIDTH-1 downto 0);
           DIN      : in STD_LOGIC_VECTOR (11 downto 0); -- max width constrained by amount
           DOUT     : out STD_LOGIC_VECTOR (11 downto 0));
end server_regs_if;

architecture Behavioral of server_regs_if is

  signal amount_c       : amount_table_t;
  signal amount_s       : amount_table_t := (others => (others => (others => '0')));
  signal st_price_c     : price_table_t;
  signal st_price_s     : price_table_t := (others => (others => '0'));
  signal em_price_c     : price_table_t;
  signal em_price_s     : price_table_t := (others => (others => '0'));
  signal ex_price_c     : price_table_t;
  signal ex_price_s     : price_table_t := (others => (others => '0'));

begin

    process(CLK, RST) begin
      if(RST = '1') then
        amount_s       <= (others => (others => (others => '0')));
        st_price_s     <= (others => (others => '0'));
        em_price_s     <= (others => (others => '0'));
        ex_price_s     <= (others => (others => '0'));
      elsif(rising_edge(CLK)) then
        amount_s       <= amount_c;
        st_price_s     <= st_price_c;
        em_price_s     <= em_price_c;
        ex_price_s     <= ex_price_c;
      end if;
    end process;

    process(RW, COL, ROW, NODE, amount_s, st_price_s, em_price_s, ex_price_s, DIN) begin
        amount_c    <= amount_s;
        st_price_c  <= st_price_s;
        em_price_c  <= em_price_s;
        ex_price_c  <= ex_price_s;
        DOUT        <= (others => '0');

        if(TO_INTEGER(UNSIGNED(ROW)) < g_FOOD_CNT) then
            if(RW = '0') then
                if(UNSIGNED(COL) = 1) then
                    if(TO_INTEGER(UNSIGNED(NODE)) <= g_CLIENTS_CNT) then
                        amount_c(TO_INTEGER(UNSIGNED(NODE)), TO_INTEGER(UNSIGNED(ROW))) <= DIN;
                    end if;
                elsif(UNSIGNED(COL) = 2) then
                    st_price_c(TO_INTEGER(UNSIGNED(ROW))) <= DIN(7 downto 0);
                elsif(UNSIGNED(COL) = 3) then
                    em_price_c(TO_INTEGER(UNSIGNED(ROW))) <= DIN(7 downto 0);
                elsif(UNSIGNED(COL) = 4) then
                    ex_price_c(TO_INTEGER(UNSIGNED(ROW))) <= DIN(7 downto 0);
                end if;
            else
                if(UNSIGNED(COL) = 1) then
                    DOUT <= amount_s(TO_INTEGER(UNSIGNED(NODE)), TO_INTEGER(UNSIGNED(ROW)));
                elsif(UNSIGNED(COL) = 2) then
                    DOUT <= "0000" & st_price_s(TO_INTEGER(UNSIGNED(ROW)));
                elsif(UNSIGNED(COL) = 3) then
                    DOUT <= "0000" & em_price_s(TO_INTEGER(UNSIGNED(ROW)));
                elsif(UNSIGNED(COL) = 4) then
                    DOUT <= "0000" & ex_price_s(TO_INTEGER(UNSIGNED(ROW)));
                end if;
            end if;
        end if;
    end process;

end Behavioral;
