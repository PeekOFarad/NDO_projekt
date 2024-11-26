----------------------------------------------------------------------------------
-- client_pkg.vhd
-- Client package
-- 26 Nov, 2024
-- Semestral project in the autumn semester of 2024 in MPC-NDO.
-- Artem Gumenyuk (xgumen00@vutbr.cz)
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.math_real.all;

package client_pkg is

  subtype amount_t is std_logic_vector(11 downto 0);
  
  subtype price_t is std_logic_vector(7 downto 0);
  
  subtype char_t is std_logic_vector(7 downto 0);
  
  constant c_FOOD_CNT     : integer := 32;
  constant c_CLIENTS_CNT  : integer := 1;
  constant c_NODE_WIDTH   : integer := 1;
  constant c_NUM_BLOCKS   : integer := 1;
  constant c_SPI_WIDTH    : integer := 23;
  
  type amount_table_t is array(0 to c_CLIENTS_CNT, 0 to (c_FOOD_CNT - 1)) of amount_t;
  type price_table_t is array(0 to (c_FOOD_CNT - 1)) of price_t;

  type block_bit_t is array(0 to c_NUM_BLOCKS-1) of STD_LOGIC;
  type block_col_t is array(0 to c_NUM_BLOCKS-1) of STD_LOGIC_VECTOR (2 downto 0);
  type block_row_t is array(0 to c_NUM_BLOCKS-1) of STD_LOGIC_VECTOR (5 downto 0);
  type block_node_t is array(0 to c_NUM_BLOCKS-1) of STD_LOGIC_VECTOR (c_NODE_WIDTH-1 downto 0);
  type block_data_t is array(0 to c_NUM_BLOCKS-1) of STD_LOGIC_VECTOR (11 downto 0);
  
  type digit_arr_t is array(0 to 3) of char_t;

end client_pkg;

package body client_pkg is
 
end client_pkg;