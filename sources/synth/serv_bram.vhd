-- Single-Port Block RAM Write-First Mode (recommended template)
--
-- File: rams_sp_wf.vhd
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rams_sp_wf is
  port(
        clk : in std_logic;
        --rst : in std_logic;
        we : in std_logic;
        en : in std_logic;
        addr : in std_logic_vector(9 downto 0);
        di : in std_logic_vector(15 downto 0);
        do : out std_logic_vector(15 downto 0)
      );
end rams_sp_wf;

architecture syn of rams_sp_wf is
  attribute ram_style : string;
  
  type ram_type is array (1023 downto 0) of std_logic_vector(15 downto 0);
  signal RAM : ram_type := (others => (others => '0'));

  attribute ram_style of RAM : signal is "block";
begin
  process(clk)--, rst)
  begin
    -- if rst = '1' then
    --   RAM <= (others => (others => '0'));
    -- els
    if clk'event and clk = '1' then
      if en = '1' then
        if we = '1' then
          RAM(to_integer(unsigned(addr))) <= di;
          do <= di;
        else
          do <= RAM(to_integer(unsigned(addr)));
        end if;
      end if;
    end if;
  end process;
end syn;