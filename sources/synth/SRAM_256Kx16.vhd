-- library IEEE;
-- use IEEE.STD_LOGIC_1164.ALL;
-- use IEEE.NUMERIC_STD.ALL;
-- use ieee.math_real.all;
-- use work.VGA_pkg.all;

-- entity SRAM_256Kx16 is
--   Port (
--     CLK      : in  std_logic;
--     RW_ADDR  : in  std_logic_vector(17 downto 0);
--     DATA     : inout  std_logic_vector(15 downto 0);
--     CE_N     : in  std_logic;
--     OE_N     : in  std_logic;
--     WE_N     : in  std_logic;
--     LB_N     : in  std_logic; 
--     UB_N     : in  std_logic
--   );
-- end SRAM_256Kx16;

-- architecture Behavioral of SRAM_256Kx16 is
--   type memory_type is array (0 to 262143) of std_logic_vector(15 downto 0);
--   signal memory : memory_type := (others => (others => '0'));

--   signal data_out : std_logic_vector(15 downto 0);
--   signal data_in : std_logic_vector(15 downto 0);

-- begin
--   -- Process for handling read and write operations
--   process (CLK)
--   begin
--     if rising_edge(CLK) then
--       -- Check if Chip Enable is active
--       if CE_N = '0' then
--         -- Write operation (WE_N is active low)
--         if WE_N = '0' then
--           if LB_N = '0' then
--             memory(to_integer(unsigned(RW_ADDR)))(7 downto 0) <= DATA(7 downto 0);
--           end if;
--           if UB_N = '0' then
--             memory(to_integer(unsigned(RW_ADDR)))(15 downto 8) <= DATA(15 downto 8);
--           end if;
--         end if;

--         -- Read operation (OE_N is active low, WE_N is high)
--         if WE_N = '1' and OE_N = '0' then
--           data_out <= memory(to_integer(unsigned(RW_ADDR)));
--         else
--           data_out <= (others => 'Z');
--         end if;
--       else
--         data_out <= (others => 'Z');
--       end if;
--     end if;
--   end process;

--   -- Drive the DATA bus based on data_out
--   DATA <= data_out when (CE_N = '0' and OE_N = '0' and WE_N = '1') else (others => 'Z');

-- end Behavioral;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.math_real.all;
use work.VGA_pkg.all;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity SRAM_256Kx16 is
  Port (
    RW_ADDR     : in  std_logic_vector (17 downto 0);      -- 18-bit address for 256K memory locations
    DATA        : inout std_logic_vector (15 downto 0);    -- 16-bit bidirectional data bus
    CE_N        : in  std_logic;                           -- Chip Enable, active low
    OE_N        : in  std_logic;                           -- Output Enable, active low
    WE_N        : in  std_logic;                           -- Write Enable, active low
    LB_N        : in  std_logic;                           -- Lower Byte Enable, active low
    UB_N        : in  std_logic                            -- Upper Byte Enable, active low
  );
end SRAM_256Kx16;

architecture Behavioral of SRAM_256Kx16 is
  type memory_array is array (0 to 262143) of std_logic_vector(15 downto 0); -- 256K memory locations of 16 bits each
  signal memory : memory_array := (others => (others => '0'));               -- Initialize memory to zeroes
  signal data_out : std_logic_vector(15 downto 0);
begin
  process (CE_N, OE_N, WE_N, RW_ADDR, DATA, LB_N, UB_N)
  begin
    if CE_N = '0' then                                 -- Chip Enable active
      if WE_N = '0' then                               -- Write operation
        -- Writing lower byte (D[7:0]) if LB_N is active
        if LB_N = '0' then
          memory(conv_integer(RW_ADDR))(7 downto 0) <= DATA(7 downto 0);
        end if;
        -- Writing upper byte (D[15:8]) if UB_N is active
        if UB_N = '0' then
          memory(conv_integer(RW_ADDR))(15 downto 8) <= DATA(15 downto 8);
        end if;
      elsif OE_N = '0' then                           -- Read operation
        -- Reading lower byte (D[7:0]) if LB_N is active
        if LB_N = '0' then
          data_out(7 downto 0) <= memory(conv_integer(RW_ADDR))(7 downto 0);
        else
          data_out(7 downto 0) <= (others => 'Z');    -- High impedance if LB_N is inactive
        end if;
        -- Reading upper byte (D[15:8]) if UB_N is active
        if UB_N = '0' then
          data_out(15 downto 8) <= memory(conv_integer(RW_ADDR))(15 downto 8);
        else
          data_out(15 downto 8) <= (others => 'Z');   -- High impedance if UB_N is inactive
        end if;
      else
        data_out <= (others => 'Z');                  -- High impedance if not reading or writing
      end if;
    else
      data_out <= (others => 'Z');                    -- High impedance if chip not enabled
    end if;
  end process;

  -- Drive DATA bus with data_out in read mode, else it should be 'Z'
  DATA <= data_out when (CE_N = '0' and OE_N = '0' and WE_N = '1') else (others => 'Z');
end Behavioral;

