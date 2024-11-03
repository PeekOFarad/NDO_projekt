----------------------------------------------------------------------------------
-- bus_arbiter_TB.vhd
-- Registers interface bus arbiter TB.
-- 29 Oct, 2024
-- Semestral project in the autumn semester of 2024 in MPC-NDO.
-- Artem Gumenyuk (xgumen00@vutbr.cz)
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.server_pkg.all;
use IEEE.NUMERIC_STD.ALL;

entity bus_arbiter_TB is
--  Port ( );
end bus_arbiter_TB;

architecture Behavioral of bus_arbiter_TB is

component bus_arbiter is
    Generic (
        g_NUM_BLOCKS : positive;
        g_NODE_WIDTH : positive
    );
    Port(  CLK        : in STD_LOGIC;
           RST        : in STD_LOGIC;
           REQ        : in block_bit_t;
           block_RW   : in block_bit_t;
           block_COL  : in block_col_t;
           block_ROW  : in block_row_t;
           block_NODE : in block_node_t;
           block_DIN  : in block_data_t;
           ACK        : out block_bit_t;
           -- to register interface
           RW         : out STD_LOGIC;
           COL        : out STD_LOGIC_VECTOR (2 downto 0);
           ROW        : out STD_LOGIC_VECTOR (5 downto 0);
           NODE       : out STD_LOGIC_VECTOR (g_NODE_WIDTH downto 0);
           DIN        : out STD_LOGIC_VECTOR (11 downto 0)
        );
end component;

--------------------------------------------------------------------------------

component server_regs_if is
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
           NODE     : in STD_LOGIC_VECTOR (g_NODE_WIDTH downto 0);
           DIN      : in STD_LOGIC_VECTOR (11 downto 0); -- max width constrained by amount
           DOUT     : out STD_LOGIC_VECTOR (11 downto 0));
  end component;

--------------------------------------------------------------------------------

constant clk_per              : time := 1 ns; 
constant ps2_clk_per          : time := 1000 ns;
signal   simulation_finished  : BOOLEAN := FALSE;

signal   clk                  : std_logic := '0';
signal   rst                  : std_logic := '0';

signal   node                 : std_logic_vector(1 downto 0);
signal   col                  : std_logic_vector(2 downto 0);
signal   row                  : std_logic_vector(5 downto 0);

signal   rw                   : std_logic;
signal   din                  : std_logic_vector(11 downto 0);
signal   dout                 : std_logic_vector(11 downto 0);

signal   REQ        :  block_bit_t;
signal   block_RW   :  block_bit_t;
signal   block_COL  :  block_col_t;
signal   block_ROW  :  block_row_t;
signal   block_NODE :  block_node_t;
signal   block_DIN  :  block_data_t;
signal   ACK        :  block_bit_t;

begin

    process begin
        clk <= '0'; wait for clk_per/2;
        clk <= '1'; wait for clk_per/2;
        if simulation_finished then
          wait;
        end if;
      end process;
    
    --------------------------------------------------------------------------------
    
      bus_arbiter_i : bus_arbiter
      generic map(
        g_NUM_BLOCKS  => 2,
        g_NODE_WIDTH  => 1
      )
      port map(
        CLK          => clk,
        RST          => rst,
        REQ          => REQ,
        block_RW     => block_RW,
        block_COL    => block_COL,
        block_ROW    => block_ROW,
        block_NODE   => block_NODE,
        block_DIN    => block_DIN,
        ACK          => ACK,
        RW           => rw,
        COL          => col,
        ROW          => row,
        node         => node,
        DIN          => din
      );

--------------------------------------------------------------------------------

    server_regs_if_i : server_regs_if
    generic map(
    g_FOOD_CNT    => c_FOOD_CNT,
    g_CLIENTS_CNT => c_CLIENTS_CNT,
    g_NODE_WIDTH  => 1
    )
    port map(
    CLK    => clk,
    RST    => rst,
    RW     => rw,
    COL    => col,
    ROW    => row,
    NODE   => node,
    DIN    => din,
    DOUT   => dout
    );

--------------------------------------------------------------------------------

    proc_stim : PROCESS BEGIN
        REQ        <= (others => '0');
        block_RW   <= (others => '0');
        block_COL  <= (others => (others => '0'));
        block_ROW  <= (others => (others => '0'));
        block_NODE <= (others => (others => '0'));
        block_DIN  <= (others => (others => '0'));

        wait until rising_edge(clk);
        wait for clk_per * 10;

        -- write req from 0 block
        REQ(0) <= '1';
        block_RW(0) <= '0';
        block_COL(0) <= "001";
        block_DIN(0) <= "000000000011";

        wait for clk_per;
        REQ(0) <= '0';
        wait for clk_per * 10;

        -- read req from 1 block
        REQ(1) <= '1';
        block_RW(1) <= '1';
        block_COL(1)  <= "001";

        wait for clk_per;
        REQ(1) <= '0';
        wait for clk_per * 10;

        -- both write
        REQ(0) <= '1';
        REQ(1) <= '1';
        block_RW(0) <= '0';
        block_RW(1) <= '0';
        block_COL(1) <= "010";
        block_DIN(0) <= "000000000001";
        block_DIN(1) <= "000000010111";

        wait for clk_per * 2;
        REQ(0) <= '0';

        wait for clk_per * 2;
        REQ(1) <= '0';
        wait for clk_per * 10;

        simulation_finished <= TRUE;
        WAIT;
  END PROCESS;

end Behavioral;
