----------------------------------------------------------------------------------
-- VGA_sram_mux.vhd
-- SRAM read/write multiplexor - write enabled only in VGA vertical blank space
-- 11 Oct, 2024
-- Semestral project in the autumn semester of 2024 in MPC-NDO.
-- Matej Stepan (xstepa67@vutbr.cz)
----------------------------------------------------------------------------------
-- note: Addressable food table is 5x32 cells
-- prices are 3 character each
-- portion amount is 4 chars
-- food type is 9 chars
-- Food name is 32 chars
-- invert last updated cell (for user as cursor) and revert back when cell index changed


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.math_real.all;
use work.VGA_pkg.all;
use work.server_pkg.all;
use work.common_pkg.all;
use work.UI_pkg.all;

entity VGA_sram_mux is
  Port ( 
    CLK         : in  std_logic;
    RST         : in  std_logic;
    --------------------------------------------------------------------------------
    -- SYSTEM INTERFACE
    COL_SYS     : in  STD_LOGIC_VECTOR (2 downto 0);
    ROW_SYS     : in  STD_LOGIC_VECTOR (5 downto 0);
    UPD_ARR     : in  STD_LOGIC;
    UPD_DATA    : in  STD_LOGIC;
    DATA_SYS    : in  char_buff_t;
    VGA_RDY     : out std_logic;
    --------------------------------------------------------------------------------
    COLUMN      : in  std_logic_vector (c_cnt_h_w-1 downto 0);  --! horizontal pixel coordinate
    ROW         : in  std_logic_vector (c_cnt_v_w-1 downto 0);  --! vertical pixel coordinate
    PIXEL_DATA  : out std_logic;
    RW_ADDR     : out std_logic_vector (17 downto 0);
    DATA        : inout  std_logic_vector (15 downto 0);
    CE_N        : out std_logic; --! chip enable, always low
    OE_N        : out std_logic;
    WE_N        : out std_logic; --! always high for reading
    LB_N        : out std_logic; --! Byte selection, always low
    UB_N        : out std_logic; --! Byte selection, always low
    CTRL_EN     : out std_logic  --!
  );
end VGA_sram_mux;

architecture rtl of VGA_sram_mux is

  -- SYSTEM INTERFACE
  

  type t_fsm_sram_mux is (init, READ, WRITE);
    
  signal state, next_state : t_fsm_sram_mux := init;

  signal we_n_int       : std_logic := '1';
  signal oe_n_int       : std_logic := '1';
  signal ub_n_int       : std_logic := '0';
  signal lb_n_int       : std_logic := '1';
  signal byte_ctrl      : std_logic := '0';
  signal byte_ctrl_d1   : std_logic := '0';
  signal data_o_int     : std_logic_vector(15 downto 0) := (others => '0');

  signal ctrl_en_int    : std_logic := '0';

  signal VGA_buffer_s   : std_logic_vector(15 downto 0) := (others => '0'); --! buffer
  signal VGA_buffer_c   : std_logic_vector(15 downto 0); --! buffer

  signal cnt_shift_s    : unsigned(3 downto 0) := (others => '0');
  signal cnt_shift_c    : unsigned(3 downto 0);
  signal sram_re_n      : std_logic := '1'; 
  signal shreg_empty_n  : std_logic := '1';
  signal v_porch_n_c    : std_logic := '1';
  signal h_porch_n      : std_logic := '1';

  signal cnt_raddr_s    : unsigned(17 downto 0) := (others => '0');
  signal cnt_raddr_c    : unsigned(17 downto 0);
  signal rw_addr_s      : std_logic_vector(17 downto 0) := (others => '0');
  signal rw_addr_c      : std_logic_vector(17 downto 0);

  signal cnt_waddr_s    : unsigned(17 downto 0) := (others => '0');
  signal cnt_waddr_c    : unsigned(17 downto 0);
  signal cnt_line_s     : unsigned(17 downto 0) := (others => '0');
  signal cnt_line_c     : unsigned(17 downto 0);

  signal init_rw_addr_s : unsigned(17 downto 0) := (others => '0');
  signal init_rw_addr_c : unsigned(17 downto 0);

  --------------------------------------------------------------------------------
  -- UI ROM
  --------------------------------------------------------------------------------
  signal cnt_UI_addr_s      : unsigned(c_UI_ADDR_W-1 downto 0) := (others => '0');
  signal cnt_UI_addr_c      : unsigned(c_UI_ADDR_W-1 downto 0);
  signal UI_addr_c          : unsigned(c_UI_ADDR_W-1 downto 0);
  signal UI_char_index      : std_logic_vector(6 downto 0);
  signal char_base_addr_c   : unsigned(9 downto 0);
  
  signal cnt_ROW_s2           : unsigned(3 downto 0) := (others => '0');
  signal cnt_ROW_s            : unsigned(3 downto 0) := (others => '0');
  signal cnt_ROW_c            : unsigned(3 downto 0);
  --------------------------------------------------------------------------------
  signal cnt_ROM_col_s  : unsigned(11 downto 0) := (others => '0');
  signal cnt_ROM_col_c  : unsigned(11 downto 0);

  signal cnt_ROM_row_s  : unsigned(11 downto 0) := (others => '0');
  signal cnt_ROM_row_c  : unsigned(11 downto 0);

  signal cnt_init_s     : unsigned(11 downto 0) := (others => '0');
  signal cnt_init_c     : unsigned(11 downto 0);
  signal u_column       : unsigned(c_cnt_h_w-1 downto 0) := (others => '0');
  signal u_row          : unsigned(c_cnt_v_w-1 downto 0) := (others => '0');

  signal dataOutA       : std_logic_vector(7 downto 0)  := (others => '0');


  -- fifo
  signal RWADDR_C        : std_logic_vector(17 downto 0);
  signal DATA_IO         : std_logic_vector(15 downto 0);
  signal data_int        : std_logic_vector(15 downto 0);
  signal OE_N_W         : std_logic;
  signal WE_N_W         : std_logic;
  signal LB_N_W         : std_logic;
  signal UB_N_W         : std_logic;

  signal fifo_ren       : std_logic;

begin

  process (CLK)
	begin
		if rising_edge(CLK) then

			
      if RST = '1' then
        ctrl_en_int <= '0';
        byte_ctrl <= '0';
      else
        if cnt_ROW_s = 0 then 
          byte_ctrl <= NOT byte_ctrl;
        end if;
          byte_ctrl_d1 <= byte_ctrl;
        if state = READ and cnt_shift_s >= 15 then
          ctrl_en_int <= '1';
        end if;
      end if;
		end if;
	end process;

  CTRL_EN <= ctrl_en_int;



  u_column  <= unsigned(COLUMN);
  u_row     <= unsigned(ROW);

  DATA <= bit_reverse(dataOutA) & bit_reverse(dataOutA) when state = init else
          (others => 'Z');

  -- data_int <= (others => 'Z') when state = init else
  --             DATA;

  init_rw_addr_c <= resize(cnt_waddr_s + cnt_line_s + (resize(cnt_ROW_s, cnt_waddr_s'length)*40), rw_addr_c'length);    

  rw_addr_c <=  std_logic_vector(init_rw_addr_s) when (state = init) else
                -- RWADDR_C when state = WRITE else
                std_logic_vector(cnt_raddr_c);

  RW_ADDR <= RWADDR_C when state = WRITE else rw_addr_s; -- give timing control to cmd_fifo 

  OE_N    <= oe_n_int;-- shreg_empty_n;-- sram_re_n; 
  CE_N    <= CLK;
  WE_N    <= we_n_int; --! write enable signal 
  UB_N    <= ub_n_int;
  LB_N    <= lb_n_int;


  PIXEL_DATA <= VGA_buffer_s(VGA_buffer_s'low);


  p_reg: process (CLK)
  begin
  if rising_edge(CLK) then
    if RST = '1' then
      state           <= init;
      VGA_buffer_s    <= (others => '0');
      cnt_raddr_s     <= (others => '0');
      cnt_shift_s     <= (others => '0');
      cnt_ROM_col_s   <= (others => '0');
      cnt_ROW_s2       <= (others => '0');
      cnt_ROW_s       <= (others => '0');
      cnt_waddr_s     <= (others => '0');
      init_rw_addr_s  <= (others => '0');
      rw_addr_s       <= (others => '0');
      cnt_line_s      <= (others => '0');
    else
      state           <= next_state;
      init_rw_addr_s  <= init_rw_addr_c;
      rw_addr_s       <= rw_addr_c;
      cnt_shift_s     <= cnt_shift_c;
      VGA_buffer_s    <= VGA_buffer_c;
      cnt_raddr_s     <= cnt_raddr_c;
      cnt_waddr_s     <= cnt_waddr_c;
      cnt_UI_addr_s   <= cnt_UI_addr_c;
      cnt_ROW_s2       <= cnt_ROW_s;
      cnt_ROW_s       <= cnt_ROW_c;
      cnt_line_s      <= cnt_line_c;  
    end if;
  end if;
  end process;


  
  shreg_empty_n <= '0' when cnt_shift_s = 2**cnt_shift_s'length-1 else '1'; -- when cnt_shift_s = 15
  sram_re_n     <= (NOT shreg_empty_n) NAND v_porch_n_c; -- sram_re_n active when shreg is empty and we're not in vert porch

  VGA_buffer_c  <= DATA when (shreg_empty_n = '0' and state = READ) else
                   '0' & VGA_buffer_s(VGA_buffer_s'high downto VGA_buffer_s'low+1);
  

  
  --! Generates sram read address and v_porch_n signal that allows write opperations
  p_cnt: process (cnt_raddr_s, u_row, u_column, cnt_waddr_s, state, cnt_ROW_s, cnt_shift_s, cnt_UI_addr_s, cnt_line_s, byte_ctrl)
  begin
    --------------------------------------------------------------------------------
    -- SRAM INIT
    --------------------------------------------------------------------------------
      -- SRAM write address incrementaions
      cnt_waddr_c <= cnt_waddr_s;
      if state = init then
        if cnt_ROW_s >= 11 and std_logic(cnt_UI_addr_s(cnt_UI_addr_s'low)) = '1' then -- increment adress when finished writing both bytes 
          cnt_waddr_c <= cnt_waddr_s + 1;
        end if;
        if cnt_waddr_s = 39 and (cnt_ROW_s >= 11 and byte_ctrl = '0') then 
          cnt_waddr_c <= (others => '0');
        end if;
      end if;

      cnt_line_c <= cnt_line_s;
      if state = init then 
        if cnt_waddr_s = 39 and (cnt_ROW_s >= 11 and byte_ctrl = '0') then 
          cnt_line_c <= cnt_line_s + 480;
        end if;
      end if;

      cnt_ROW_c <= cnt_ROW_s;
      if state = init then 
        cnt_ROW_c <= cnt_ROW_s + 1;
        if cnt_ROW_s >= 11 then 
          cnt_ROW_c <= (others => '0');
        end if;
      end if;

      cnt_UI_addr_c <= cnt_UI_addr_s;
      if state = init then 
        if cnt_ROW_s = 11 then -- move to new char when finished reading previous
          cnt_UI_addr_c <= cnt_UI_addr_s + 1;
        end if;
        if cnt_UI_addr_s >= 3199 then 
          cnt_UI_addr_c <= cnt_UI_addr_s;
        end if;
      end if;

    --------------------------------------------------------------------------------
    -- SRAM READING
    --------------------------------------------------------------------------------

      cnt_shift_c <= cnt_shift_s;
      if state = READ then 
        cnt_shift_c <= cnt_shift_s + 1;
      end if;
      
      
      cnt_raddr_c <= cnt_raddr_s;
      -- cnt_raddr_c <= (others => '0');
      if (((u_column < c_H_PIXELS and u_row < c_V_PIXELS) or (u_column = c_LINE-1 and u_row = c_FRAME-1)) and (state = READ) and (cnt_shift_s = 14)) then
        cnt_raddr_c <= cnt_raddr_s + 1;
      end if;
      if u_column < c_LINE-1 and u_row >= c_FRAME-1 then
        cnt_raddr_c <= (others => '0');
      end if;

      
      v_porch_n_c   <= '1';
      if u_row >= c_V_PIXELS then
        v_porch_n_c   <= '0';
      end if;

      h_porch_n   <= '1';
      if u_column >= c_H_PIXELS then
        h_porch_n   <= '0';
      end if;
    ---------------------------------------------------------------------------------
  end process;

  fifo_ren <= '1' when ((u_row >= c_V_PIXELS) and not (u_row = c_FRAME-1 and u_column >= c_LINE - 16 - 1)) else '0';



  p_fsm: process (state, u_row, u_column, WE_N_W, UB_N_W, LB_N_W, shreg_empty_n, OE_N_W, byte_ctrl, cnt_UI_addr_s, cnt_ROW_s)
  begin
    oe_n_int  <= '1';
    we_n_int  <= '1';
    ub_n_int  <= '1';
    lb_n_int  <= '1';
    next_state <= init;

    case state is

      when init =>
        oe_n_int  <= shreg_empty_n;
        we_n_int  <= '0';
        ub_n_int  <= byte_ctrl_d1;
        lb_n_int  <= NOT byte_ctrl_d1;
        
        if (cnt_UI_addr_s >= 3199 and cnt_ROW_s >= 11) then 
          next_state <= READ;
        end if;

      when READ =>
        oe_n_int    <= shreg_empty_n;
        ub_n_int    <= '0';
        lb_n_int    <= '0';
        next_state <= READ;
        if u_row >= c_V_PIXELS-1 and u_column >= c_LINE-1 then
          next_state <= WRITE;
        end if;

      when WRITE =>
      
        oe_n_int    <= OE_N_W;
        we_n_int    <= WE_N_W;
        ub_n_int    <= UB_N_W;
        lb_n_int    <= LB_N_W;
        next_state <= WRITE;
        if u_row >= c_FRAME-1 and u_column >= c_LINE-1 then
          next_state <= READ;
        end if;
    
      when others =>
        null;
    end case;
    
  end process;

  fontROM_8x12_inst : entity work.fontROM_8x12
  generic map (
    addrWidth => 10,
    dataWidth => 8
  )
  port map (
    clkA      => CLK,
    addrA     => std_logic_vector(char_base_addr_c),
    dataOutA  => dataOutA
  );

  char_base_addr_c <= resize((unsigned(UI_char_index)*12) + cnt_ROW_s2, char_base_addr_c'length);

  UI_ROM_inst_0 : entity work.UI_ROM
  port map (
    clkA => CLK,
    addrA => std_logic_vector(cnt_UI_addr_s),
    dataOutA => UI_char_index
  );


  VGA_cmd_fifo_inst : entity work.VGA_cmd_fifo
  port map (
    CLK       => CLK,
    RST       => RST,
    COL_SYS   => COL_SYS,     
    ROW_SYS   => ROW_SYS,     
    UPD_ARR   => UPD_ARR,
    UPD_DATA  => UPD_DATA,
    DATA_SYS  => DATA_SYS,
    VGA_RDY   => VGA_RDY,
    FIFO_REN  => fifo_ren,
    RWADDR_C  => RWADDR_C,
    DATA_IO   => DATA,
    OE_N_W    => OE_N_W,
    WE_N_D2   => WE_N_W,
    LB_N_W    => LB_N_W,
    UB_N_W    => UB_N_W
  );

  
end rtl;
