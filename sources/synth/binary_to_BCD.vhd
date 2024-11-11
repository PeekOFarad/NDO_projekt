----------------------------------------------------------------------------------
-- binary_to_BCD.vhd
-- Binary to BCD (in sprit format) converter
-- 11 Nov, 2024
-- Semestral project in the autumn semester of 2024 in MPC-NDO.
-- Artem Gumenyuk (xgumen00@vutbr.cz)
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.server_pkg.all;

entity binary_to_BCD is
    Port ( binary_in : in  STD_LOGIC_VECTOR (11 downto 0);
           BCD_out   : out digit_arr_t
        );
end binary_to_BCD;

architecture Behavioral of binary_to_BCD is

    type bcd_array is array (0 to 3) of unsigned(3 downto 0);
    signal bcd_digits : bcd_array := (others => "0000");
    signal binary     : STD_LOGIC_VECTOR(11 downto 0);

begin

  process (binary_in) begin
    -- Initialize
    binary     <= binary_in;
    bcd_digits <= (others => (others => '0'));

    -- Double Dabble Algorithm
    for i in 11 downto 0 loop
      -- Shift all BCD digits left by 1 bit
      bcd_digits(3) <= bcd_digits(3)(2 downto 0) & bcd_digits(2)(3);
      bcd_digits(2) <= bcd_digits(2)(2 downto 0) & bcd_digits(1)(3);
      bcd_digits(1) <= bcd_digits(1)(2 downto 0) & bcd_digits(0)(3);
      bcd_digits(0) <= bcd_digits(0)(2 downto 0) & binary(11);
      binary <= binary(10 downto 0) & '0';

      -- Add 3 if any BCD digit is >= 5
      for j in 0 to 3 loop
        if bcd_digits(j) >= "0101" then
          bcd_digits(j) <= bcd_digits(j) + "0011";
        end if;
      end loop;
    end loop;
  end process;

  -- decode into sprit format
  process(bcd_digits) begin
    BCD_out <= (others => (others => '0'));

    for i in 0 to 3 loop
      case(to_integer(bcd_digits(i))) is
        when 0 => BCD_OUT(i) <= x"1f";
        when 1 => BCD_OUT(i) <= x"20";
        when 2 => BCD_OUT(i) <= x"21";
        when 3 => BCD_OUT(i) <= x"22";
        when 4 => BCD_OUT(i) <= x"23";
        when 5 => BCD_OUT(i) <= x"24";
        when 6 => BCD_OUT(i) <= x"25";
        when 7 => BCD_OUT(i) <= x"26";
        when 8 => BCD_OUT(i) <= x"27";
        when 9 => BCD_OUT(i) <= x"28";
        when others => BCD_OUT(i) <= x"00";
      end case;
    end loop;
  end process;

end Behavioral;
