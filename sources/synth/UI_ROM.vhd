library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.UI_pkg.all;


entity UI_ROM is
	port(
		clkA			: in std_logic;
		addrA			: in std_logic_vector(c_UI_ADDR_W-1 downto 0);
		dataOutA	: out std_logic_vector(6 downto 0)
	);
end UI_ROM;

architecture Behavioral of UI_ROM is

	-- ROM definition
	signal ROM: t_ui_LUT := c_ui_LUT;
begin

	-- addr register to infer block RAM
	setRegA: process (clkA)
	begin
		if rising_edge(clkA) then
			-- Read from it
			dataOutA <= std_logic_vector(ROM(to_integer(unsigned(addrA))));

		end if;
	end process;
	
end Behavioral;