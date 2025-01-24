-- binary_bcd_20_bit.vhd
-- Binary to BCD (in sprit format) converter. 20bit version
-- 20 Jan, 2024
-- Semestral project in the autumn semester of 2024 in MPC-NDO.
-- Artem Gumenyuk (xgumen00@vutbr.cz)
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;
use work.common_pkg.all;
 
entity binary_bcd_20_bit is
    generic(N: positive := 20);
    port(
        clk       : in std_logic;
        rst       : in std_logic;
        new_data  : in std_logic;
        binary_in : in std_logic_vector(N-1 downto 0);
        data_done : out std_logic;
        bcd_out   : out summ_digit_arr_t
    );
end binary_bcd_20_bit;
 
architecture behaviour of binary_bcd_20_bit is
    type fsm_t is (start, shift, done);
    signal fsm_c : fsm_t;
    signal fsm_s : fsm_t := start;
 
    signal binary_c   : std_logic_vector(N-1 downto 0);
    signal binary_s   : std_logic_vector(N-1 downto 0) := (others => '0');

    signal bcds_c     : unsigned(27 downto 0);
    signal bcds_s     : unsigned(27 downto 0) := (others => '0');
    signal bcds_reg_c : unsigned(27 downto 0);
    -- output register keep output constant during conversion
    signal bcds_out_c : unsigned(55 downto 0);
    signal bcds_out_s : unsigned(55 downto 0) := (others => '0');
    -- need to keep track of shifts
    signal shft_cnt_c : natural range 0 to N;
    signal shft_cnt_s : natural range 0 to N := 0;

    signal data_done_c : std_logic;
    signal data_done_s : std_logic := '0';

begin
 
    process(clk, rst)
    begin
        if rst = '1' then
          binary_s    <= (others => '0');
          bcds_s      <= (others => '0');
          fsm_s       <= start;
          bcds_out_s  <= (others => '0');
          shft_cnt_s  <= 0;
          data_done_s <= '0';
        elsif rising_edge(clk) then
          binary_s    <= binary_c;
          bcds_s      <= bcds_c;
          fsm_s       <= fsm_c;
          bcds_out_s  <= bcds_out_c;
          shft_cnt_s  <= shft_cnt_c;
          data_done_s <= data_done_c;
        end if;
    end process;
 
    process(fsm_s, binary_s, new_data, binary_in, bcds_s, bcds_reg_c,shft_cnt_s, data_done_s)
    begin
      fsm_c       <= fsm_s;
      bcds_c      <= bcds_s;
      binary_c    <= binary_s;
      shft_cnt_c  <= shft_cnt_s;
      data_done_c <= '0';

      case fsm_s is
        when start =>
          if(new_data = '1') then
            fsm_c      <= shift;
            binary_c   <= binary_in;
            bcds_c     <= (others => '0');
            shft_cnt_c <= 0;
          end if;
        when shift =>
          if shft_cnt_s = N then
            fsm_c <= done;
          else
            binary_c   <= binary_s(N-2 downto 0) & 'L';
            bcds_c     <= bcds_reg_c(26 downto 0) & binary_s(N-1);
            shft_cnt_c <= shft_cnt_s + 1;
          end if;
        when done =>
          fsm_c       <= start;
          data_done_c <= '1';
      end case;
    end process;
    
    bcds_reg_c(27 downto 24) <= bcds_s(27 downto 24) + 3 when bcds_s(27 downto 24) > 4 else
                                bcds_s(27 downto 24);
    bcds_reg_c(23 downto 20) <= bcds_s(23 downto 20) + 3 when bcds_s(23 downto 20) > 4 else
                                bcds_s(23 downto 20);
    bcds_reg_c(19 downto 16) <= bcds_s(19 downto 16) + 3 when bcds_s(19 downto 16) > 4 else
                                bcds_s(19 downto 16);
    bcds_reg_c(15 downto 12) <= bcds_s(15 downto 12) + 3 when bcds_s(15 downto 12) > 4 else
                                bcds_s(15 downto 12);
    bcds_reg_c(11 downto 8) <= bcds_s(11 downto 8) + 3 when bcds_s(11 downto 8) > 4 else
                                bcds_s(11 downto 8);
    bcds_reg_c(7 downto 4) <= bcds_s(7 downto 4) + 3 when bcds_s(7 downto 4) > 4 else
                              bcds_s(7 downto 4);
    bcds_reg_c(3 downto 0) <= bcds_s(3 downto 0) + 3 when bcds_s(3 downto 0) > 4 else
                              bcds_s(3 downto 0);
    
    -- convert directly on sprit number
    process(bcds_s) begin
      for i in 0 to 6 loop
        if(bcds_s((((6-i) * 4) + 3) downto ((6-i) * 4)) = x"0") then
          bcds_out_c(((i * 8) + 7) downto (i * 8)) <= (others => '0');
        else
          bcds_out_c(((i * 8) + 7) downto (i * 8))  <= (bcds_s((((6-i) * 4) + 3) downto ((6-i) * 4)) + x"1F");
        end if;
      end loop;
    end process;
 
    bcd_out(0) <= STD_LOGIC_VECTOR(bcds_out_s(7 downto 0));
    bcd_out(1) <= STD_LOGIC_VECTOR(bcds_out_s(15 downto 8));
    bcd_out(2) <= STD_LOGIC_VECTOR(bcds_out_s(23 downto 16));
    bcd_out(3) <= STD_LOGIC_VECTOR(bcds_out_s(31 downto 24));
    bcd_out(4) <= STD_LOGIC_VECTOR(bcds_out_s(39 downto 32));
    bcd_out(5) <= STD_LOGIC_VECTOR(bcds_out_s(47 downto 40));
    bcd_out(6) <= STD_LOGIC_VECTOR(bcds_out_s(55 downto 48));

    data_done <= data_done_s;
 
end behaviour;
