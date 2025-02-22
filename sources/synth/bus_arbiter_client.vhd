----------------------------------------------------------------------------------
-- bus_arbiter_client.vhd
-- Registers bus arbiter. Client version.
-- 26 Nov, 2024
-- Semestral project in the autumn semester of 2024 in MPC-NDO.
-- Artem Gumenyuk (xgumen00@vutbr.cz)
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.client_pkg.all;
use work.common_pkg.all;
use IEEE.NUMERIC_STD.ALL;

entity bus_arbiter_client is
    Generic (
        g_NUM_BLOCKS : positive
    );
    Port(  CLK        : in STD_LOGIC;
           RST        : in STD_LOGIC;
           REQ        : in block_bit_t;
           block_RW   : in block_bit_t;
           block_COL  : in block_col_t;
           block_ROW  : in block_row_t;
           block_DIN  : in block_data_t;
           ACK        : out block_bit_t;
           -- to register interface
           RW         : out STD_LOGIC;
           EN         : out STD_LOGIC;
           COL        : out STD_LOGIC_VECTOR (2 downto 0);
           ROW        : out STD_LOGIC_VECTOR (5 downto 0);
           DIN        : out STD_LOGIC_VECTOR (11 downto 0)
        );
end bus_arbiter_client;

architecture Behavioral of bus_arbiter_client is

    signal grant : integer := -1;  -- Track which block currently has access
    signal ack_s : block_bit_t := (others => '0');
    signal ack_dly_s : block_bit_t := (others => '0');
    signal ack_dly2_s : block_bit_t := (others => '0');
    signal en_s : std_logic := '0';

begin
    process(CLK, RST) begin
        if(RST = '1') then
            ack_dly_s   <= (others => '0');
            ack_dly2_s  <= (others => '0');
        elsif(rising_edge(CLK)) then
            ack_dly_s  <= ack_s;
            ack_dly2_s <= ack_dly_s;
        end if;
    end process;

    process(CLK, RST) begin
        if(RST = '1') then
            grant <= -1;
            ack_s   <= (others => '0');
            en_s      <= '0';
        elsif(rising_edge(CLK)) then
            if(grant = -1) then
                for i in 0 to (g_NUM_BLOCKS - 1) loop
                    if(REQ(i)) = '1' then
                        en_s     <= '1';
                        grant  <= i;
                        ack_s(i) <= '1';
                        exit;
                    end if;
                end loop;
            elsif(REQ(grant) = '1') then
                ack_s(grant) <= '1';
                en_s           <= '1';
            else
                ack_s(grant) <= '0';
                en_s           <= '0';
                grant        <= -1;
            end if;
        end if;
    end process;

    process(grant, block_RW, block_COL, block_ROW, block_DIN) begin
        if(grant = -1) then
            RW   <= '0';
            COL  <= (others => '0');
            ROW  <= (others => '0');
            DIN  <= (others => '0');
        else
            RW   <= block_RW(grant);
            COL  <= block_COL(grant);
            ROW  <= block_ROW(grant);
            DIN  <= block_DIN(grant);
        end if;
    end process;
    
    EN  <= en_s;

    process(ack_dly_s, ack_dly2_s) begin
      for i in 0 to (g_NUM_BLOCKS-1) loop
        ACK(i) <= ack_dly_s(i) and not ack_dly2_s(i);
      end loop;
    end process;

end Behavioral;
