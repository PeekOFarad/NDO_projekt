----------------------------------------------------------------------------------
-- ps2_if_ctrl_TB.vhd
-- Server controller TB.
-- 15 Oct, 2024
-- Semestral project in the autumn semester of 2024 in MPC-NDO.
-- Artem Gumenyuk (xgumen00@vutbr.cz)
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.ps2_pkg.all;
use work.server_pkg.all;
use IEEE.Std_Logic_Arith.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ps2_if_ctrl_TB is
end ps2_if_ctrl_TB;

architecture Behavioral of ps2_if_ctrl_TB is

  component ps2_if_ctrl is
    Generic (
           g_FOOD_CNT     : positive;
           g_CLIENTS_CNT  : positive;
           g_NODE_WIDTH   : positive
    );
    Port ( CLK          : in STD_LOGIC;
           RST          : in STD_LOGIC;
           EDIT_ENA     : in STD_LOGIC;
           KEYS         : in t_keys;
           NUMBER       : in STD_LOGIC_VECTOR(3 downto 0);
           PS2_CODE     : in STD_LOGIC_VECTOR (7 downto 0);
           START_DAY    : out STD_LOGIC;
           BUFF_RDY     : out STD_LOGIC;
           NODE_SEL     : out STD_LOGIC_VECTOR(g_NODE_WIDTH downto 0);
           SEL_CELL_COL : out STD_LOGIC_VECTOR (2 downto 0);
           SEL_CELL_ROW : out STD_LOGIC_VECTOR (5 downto 0);
           CHAR_BUFF    : out char_buff_t;
           AMOUNT       : out amount_table_t;
           ST_PRICE     : out price_table_t;
           EM_PRICE     : out price_table_t;
           EX_PRICE     : out price_table_t
           );
  end component;
  
--------------------------------------------------------------------------------

  constant clk_per              : time := 1 ns; 
  constant ps2_clk_per          : time := 1000 ns;
  signal   simulation_finished  : BOOLEAN := FALSE;

  signal   clk                  : std_logic := '0';
  signal   rst                  : std_logic := '0';
  signal   edit_ena             : std_logic := '0';
  signal   keys                 : t_keys := (others => '0');
  signal   number               : std_logic_vector(3 downto 0) := (others => '0');
  signal   ps2_code             : std_logic_vector(7 downto 0) := (others => '0');
  
  signal   start_day            : std_logic;
  signal   buff_rdy             : std_logic;
  signal   node_sel             : std_logic_vector(1 downto 0);
  signal   sel_cell_col         : std_logic_vector(2 downto 0);
  signal   sel_cell_row         : std_logic_vector(5 downto 0);
  signal   char_buff            : char_buff_t;
  signal   amount               : amount_table_t;
  signal   st_price             : price_table_t;
  signal   em_price             : price_table_t;
  signal   ex_price             : price_table_t;

begin

  process begin
    clk <= '0'; wait for clk_per/2;
    clk <= '1'; wait for clk_per/2;
    if simulation_finished then
      wait;
    end if;
  end process;

--------------------------------------------------------------------------------

  ps2_if_ctrl_i : ps2_if_ctrl
  generic map(
    g_FOOD_CNT    => c_FOOD_CNT,
    g_CLIENTS_CNT => c_CLIENTS_CNT,
    g_NODE_WIDTH  => 1
  )
  port map(
    CLK          => clk,
    RST          => rst ,
    EDIT_ENA     => edit_ena,
    KEYS         => keys,
    NUMBER       => number,
    PS2_CODE     => ps2_code,
    START_DAY    => start_day,
    BUFF_RDY     => buff_rdy,
    NODE_SEL     => node_sel,
    SEL_CELL_COL => sel_cell_col,
    SEL_CELL_ROW => sel_cell_row,
    CHAR_BUFF    => char_buff,
    AMOUNT       => amount,
    ST_PRICE     => st_price,
    EM_PRICE     => em_price,
    EX_PRICE     => ex_price
  );

--------------------------------------------------------------------------------

  proc_stim : PROCESS BEGIN
    wait until rising_edge(clk);
    wait for clk_per * 10;
    
    edit_ena <= '1';
    wait for clk_per;
    
    -- go to the amount cell of first row
    keys.right <= '1'; 
    wait for clk_per;
    keys.right <= '0';
    wait for clk_per * 5;
--    keys.right <= '1'; 
--    wait for clk_per;
--    keys.right <= '0';
--    wait for clk_per * 5;
    
    -- start editing
    keys.enter <= '1'; 
    wait for clk_per;
    keys.enter <= '0';
    wait for clk_per * 5;
    
    -- first digit
    number <= conv_std_logic_vector(2, 4);
    wait for clk_per;
    keys.number <= '1'; 
    wait for clk_per;
    keys.number <= '0';
    wait for clk_per * 5;
    
    -- second digit
    number <= conv_std_logic_vector(5, 4);
    wait for clk_per;
    keys.number <= '1'; 
    wait for clk_per;
    keys.number <= '0';
    wait for clk_per * 5;
    
    -- backspace
    keys.bckspc <= '1'; 
    wait for clk_per;
    keys.bckspc <= '0';
    wait for clk_per * 5;
    
    -- second digit
    number <= conv_std_logic_vector(1, 4);
    wait for clk_per;
    keys.number <= '1'; 
    wait for clk_per;
    keys.number <= '0';
    wait for clk_per * 5;
    
    -- finish editing amount
    keys.enter <= '1'; 
    wait for clk_per;
    keys.enter <= '0';
    wait for clk_per * 5;

    -- go to the name cell of first row
    keys.left <= '1'; 
    wait for clk_per;
    keys.left <= '0';
    wait for clk_per * 5;

    -- start editing
    keys.enter <= '1'; 
    wait for clk_per;
    keys.enter <= '0';
    wait for clk_per * 5;

    -- first char 'a'
    ps2_code <= conv_std_logic_vector(16#1C#, 8);
    wait for clk_per;
    keys.char <= '1'; 
    wait for clk_per;
    keys.char <= '0';
    wait for clk_per * 5;

    -- second char 'b'
    ps2_code <= conv_std_logic_vector(16#32#, 8);
    wait for clk_per;
    keys.char <= '1'; 
    wait for clk_per;
    keys.char <= '0';
    wait for clk_per * 5;

    -- third char 'c'
    ps2_code <= conv_std_logic_vector(16#21#, 8);
    wait for clk_per;
    keys.char <= '1'; 
    wait for clk_per;
    keys.char <= '0';
    wait for clk_per * 5;

    -- fourth char 'x'
    ps2_code <= conv_std_logic_vector(16#22#, 8);
    wait for clk_per;
    keys.char <= '1'; 
    wait for clk_per;
    keys.char <= '0';
    wait for clk_per * 5;

    -- backspace
    keys.bckspc <= '1'; 
    wait for clk_per;
    keys.bckspc <= '0';
    wait for clk_per * 5;

    -- finish editing name
    keys.esc <= '1'; 
    wait for clk_per;
    keys.esc <= '0';
    wait for clk_per * 5;

    -- go to the student price cell of first row
    keys.right <= '1'; 
    wait for clk_per;
    keys.right <= '0';
    wait for clk_per * 5;
    keys.right <= '1'; 
    wait for clk_per;
    keys.right <= '0';
    wait for clk_per * 5;

    -- start editing
    keys.enter <= '1'; 
    wait for clk_per;
    keys.enter <= '0';
    wait for clk_per * 5;
    
    -- first digit
    number <= conv_std_logic_vector(6, 4);
    wait for clk_per;
    keys.number <= '1'; 
    wait for clk_per;
    keys.number <= '0';
    wait for clk_per * 5;
    
    -- second digit
    number <= conv_std_logic_vector(0, 4);
    wait for clk_per;
    keys.number <= '1'; 
    wait for clk_per;
    keys.number <= '0';
    wait for clk_per * 5;

    -- finish editing student price by right arrow - col cursor should move right
    keys.right <= '1'; 
    wait for clk_per;
    keys.right <= '0';
    wait for clk_per * 5;

    -- go to the next node button row (32)
    for i in 1 to 32 loop
      keys.down <= '1'; 
      wait for clk_per;
      keys.down <= '0';
      wait for clk_per * 3;
    end loop;

    -- swith to the next node (first client)
    keys.enter <= '1'; 
    wait for clk_per;
    keys.enter <= '0';
    wait for clk_per * 5;

    -- go to the first row (0)
    for i in 1 to 32 loop
      keys.up <= '1'; 
      wait for clk_per;
      keys.up <= '0';
      wait for clk_per * 3;
    end loop;

    keys.left <= '1'; 
    wait for clk_per;
    keys.left <= '0';
    wait for clk_per * 5;

    -- try to modify student price (clients cannot modify prices)
    -- start editing
    keys.enter <= '1'; 
    wait for clk_per;
    keys.enter <= '0';
    wait for clk_per * 5;
    
    -- first digit
    number <= conv_std_logic_vector(3, 4);
    wait for clk_per;
    keys.number <= '1'; 
    wait for clk_per;
    keys.number <= '0';
    wait for clk_per * 5;
    
    -- second digit
    number <= conv_std_logic_vector(2, 4);
    wait for clk_per;
    keys.number <= '1'; 
    wait for clk_per;
    keys.number <= '0';
    wait for clk_per * 5;

    -- finish editing student price by left arrow - col cursor should move left
    keys.left <= '1'; 
    wait for clk_per;
    keys.left <= '0';
    wait for clk_per * 5;
    
    simulation_finished <= TRUE;
    WAIT;
  END PROCESS;

end Behavioral;
