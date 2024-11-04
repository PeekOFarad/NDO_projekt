--! Verification BFM for AXI4-Stream

library ieee, work;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.handshake_pkg.all;
use work.AXIS_bfm_pkg.all;
entity AXIS_bfm is
	generic (
		g_RST   : std_logic := '1';
    g_TDATA_W : integer := C_TDATA_W;
    g_TUSER_W : integer := C_TUSER_W;
    g_TDEST_W : integer := C_TDEST_W;
    g_TID_W 	: integer := C_TID_W
	);
	port (
		-- MASTER INTERFACES
			M00_AXIS_ACLK   : in  std_logic;
			M00_AXIS_ARESET : in  std_logic;
			M00_AXIS_TDATA  : out std_logic_vector(g_TDATA_W-1 downto 0);
			M00_AXIS_TVALID : out std_logic;
			M00_AXIS_TREADY : in  std_logic;
		-- SLAVE INTERFACES
      S00_AXIS_ACLK     : in  std_logic; --! Use same clock as for master
      S00_AXIS_ARESET   : in  std_logic;
			S00_AXIS_TDATA    : in  std_logic_vector(g_TDATA_W-1 downto 0);
			S00_AXIS_TUSER    : in  std_logic_vector(g_TUSER_W-1 downto 0); --! Timestamp
			S00_AXIS_TDEST    : in  std_logic_vector(g_TDEST_W-1 downto 0); --! Beam ID
			S00_AXIS_TID      : in  std_logic_vector(g_TID_W-1 downto 0); --! Board ID
			S00_AXIS_TVALID   : in  std_logic;
			S00_AXIS_TREADY   : out std_logic
);
end AXIS_bfm;

architecture bfm of AXIS_bfm is                             
----------------------------------------------------------
--	USER DEFINITIONS
----------------------------------------------------------
-- Generator
type t_drive_mode is (idle, random_stim, read_fifo); 
signal driver_mode_cmd 	  : t_drive_mode := idle; --! Driven by controller
signal driver_mode 			  : t_drive_mode := idle;	--! Is *_cmd or idle when reset
  
signal m_axis_tvalid_c		  : std_logic := '0'; --! internal signal
signal m_axis_tvalid_s		  : std_logic := '0'; --! internal signal
signal m_axis_tdata_c			  : std_logic_vector(g_TDATA_W-1 downto 0) := (others => '0'); --! internal signal
signal m_axis_tdata_s			: std_logic_vector(g_TDATA_W-1 downto 0) := (others => '0'); --! internal signal
signal rng_out					  : std_logic_vector(g_TDATA_W-1 downto 0) := (others => '0'); --! internal signal

-- Fifo
signal fifo_mem						: t_fifo_mem := (others => (others => '0')); --! driver fifo
signal fifo_empty					: boolean := true; --! driver fifo util signal
signal fifo_last					: boolean := true; --! driver fifo util signal
signal fifo_full					: boolean := false; --! driver fifo util signal
signal fifo_tvalid				: std_logic := '0'; --! Data on fifo output valid
signal tx_en							: std_logic := '0'; --! tvalid && tready
signal cnt_fifo_wr_ptr		: integer := 0; --! write pointer
signal cnt_fifo_rd_ptr_c	: integer := 0; --! read pointer combinatorial
signal cnt_fifo_rd_ptr_s	: integer := 0; --! read pointer sequencial (register output)
signal fifo_utilization		: integer := 0;	--! current fifo utilization

-- Monitor
type t_monitor_mode is (idle, receive, compare_fifo, compare_file);
signal monitor_mode_cmd 	: t_monitor_mode := idle; --! Driven by controller
signal monitor_mode 			: t_monitor_mode := idle; --! Is *_cmd or idle when reset

signal s_axis_tready_c		: std_logic := '0'; --! internal signal
signal s_axis_tready_s		: std_logic := '0'; --! internal signal
signal s_axis_tdata				: std_logic_vector(g_TDATA_W-1 downto 0) := (others => '0'); --! internal signal
signal s_axis_tuser				: std_logic_vector(g_TUSER_W-1 downto 0) := (others => '0'); --! internal signal
signal s_axis_tdest				: std_logic_vector(g_TDEST_W-1 downto 0) := (others => '0'); --! internal signal
signal s_axis_tid					: std_logic_vector(g_TID_W-1 downto 0) := (others => '0'); --! internal signal
signal rx_en							: std_logic := '0'; --! tvalid && tready

-- Reference fifo
signal reference_sig		: std_logic_vector(g_TDATA_W-1 downto 0) := (others => '0');
signal reference				: t_fifo_mem := (others => (others => '0')); --! monitor reference fifo
signal ref_utilization	: integer := 0;	--! current reference fifo utilization
signal ref_empty				: boolean := true; --! ref util signal
signal ref_last					: boolean := true; --! ref util signal
signal ref_full					: boolean := false; --! ref util signal
signal cnt_ref_wr_ptr		: integer := 0; --! write pointer
signal cnt_ref_rd_ptr_c	: integer := 0; --! read pointer combinatorial
signal cnt_ref_rd_ptr_s	: integer := 0; --! read pointer sequencial (register output)



begin
----------------------------------------------------------
--	GENERATOR
----------------------------------------------------------

	--! Generator driver controller
	p_gen_ctrl: process 
	begin
		pkg_handles(0).ack <= '0';
		report "AXIS BFM Generator initialized";

		loop

			bfm_wait_for_request(pkg_handles(0));
			bfm_ack_request(pkg_handles(0));

			case bfm_cmd(0).op is

				when idle =>
					driver_mode_cmd <= idle;

				when random_stim =>
					driver_mode_cmd <= random_stim;

				when read_fifo =>
					driver_mode_cmd <= read_fifo;
				
				when write_fifo =>
				-- report("Pre-if Writing: "&integer'image(to_integer(unsigned(bfm_cmd(0).data)))&" to WP: "&integer'image(cnt_fifo_wr_ptr)& ", RP is: "&integer'image(cnt_fifo_rd_ptr_s)& " fifo_full: "&boolean'image(fifo_full)& " fifo_util: "&integer'image(fifo_utilization));
					if not fifo_full then
						fifo_mem(cnt_fifo_wr_ptr) <= bfm_cmd(0).data;
						-- Write pointer			
						if cnt_fifo_wr_ptr >= C_FIFO_MEM_SIZE-1 then -- wrap when at the end
							cnt_fifo_wr_ptr <= 0;
						else
							cnt_fifo_wr_ptr <= cnt_fifo_wr_ptr + 1;
						end if;
						-- report("Written: "&to_hex(bfm_cmd(0).data)&" to WP: "&integer'image(cnt_fifo_wr_ptr)& ", RP is: "&integer'image(cnt_fifo_rd_ptr)& " fifo_full: "&boolean'image(fifo_full)& " fifo_util: "&integer'image(fifo_utilization));
					else
						report("Error: Write failed, fifo is full");
					end if;
				
				when others =>
					null;

			end case;	
		end loop;
	end process;
	------------------------------------------------------------------------------
	
	-- DRIVER
	M00_AXIS_TVALID	<= m_axis_tvalid_s;
	M00_AXIS_TDATA 	<= m_axis_tdata_s;
	-- driver_mode reset asynchronous to controller commands
	driver_mode <=	idle when M00_AXIS_ARESET = g_RST else driver_mode_cmd;
	
	--! Generator driver process, actually drives port signals
	p_gen_driver: process
	begin
		wait until rising_edge(M00_AXIS_ACLK);                                                      
		if M00_AXIS_ARESET = g_RST then                                                                                                            
			m_axis_tvalid_s	<= '0';
			m_axis_tdata_s 	<= (others => '0');                                                                                                              
		else
			m_axis_tvalid_s	<= m_axis_tvalid_c;
			m_axis_tdata_s 	<= m_axis_tdata_c;
		end if;
	end process;


	process (driver_mode, m_axis_tdata_s, M00_AXIS_TREADY, m_axis_tvalid_s, fifo_tvalid, cnt_fifo_rd_ptr_c)
	begin
		m_axis_tvalid_c	<= '0';
		m_axis_tdata_c 	<= m_axis_tdata_s; -- output register
			-- driver_mode		<= driver_mode_cmd;
			case driver_mode is

				when idle =>
					m_axis_tvalid_c	<= '0';
					m_axis_tdata_c	<= m_axis_tdata_s;

				when random_stim =>
					m_axis_tvalid_c	<= '1';
					m_axis_tdata_c	<= rand_slv(g_TDATA_W);
					-- TODO: comment toggle the 3 lines below to test property asserts
					if m_axis_tvalid_s = '1' and M00_AXIS_TREADY = '0' then -- if slave not ready
						m_axis_tdata_c	<= m_axis_tdata_s;
					end if;

				when read_fifo =>
					m_axis_tvalid_c	<= fifo_tvalid;
					m_axis_tdata_c	<= fifo_mem(cnt_fifo_rd_ptr_c);
					if m_axis_tvalid_s = '1' and M00_AXIS_TREADY = '0' then -- if slave not ready
						m_axis_tdata_c	<= m_axis_tdata_s;
					end if;
			
				when others =>
					null;

			end case;
	end process;
	------------------------------------------------------------------------------
	
	
	--! Combinatorial fifo utilization calculation
	p_fifo_util: process (cnt_fifo_rd_ptr_s, cnt_fifo_wr_ptr)
	begin
		if cnt_fifo_wr_ptr < cnt_fifo_rd_ptr_s then
			fifo_utilization <= cnt_fifo_wr_ptr - cnt_fifo_rd_ptr_s + C_FIFO_MEM_SIZE;
		else
			fifo_utilization <= cnt_fifo_wr_ptr - cnt_fifo_rd_ptr_s;
		end if;
	end process;

	fifo_last		<= true when fifo_utilization = 1 else  false;
	fifo_empty	<= true when fifo_utilization <= 0 else  false;
	fifo_full		<= true when fifo_utilization >= C_FIFO_MEM_SIZE-1 else false; -- Keep one open fifo

	push_fifo_util(0,fifo_utilization, fifo_full, fifo_empty, fifo_last); -- Push fifo utilization with every change
	--  or fifo_last
	fifo_tvalid <= '1' when ((driver_mode = read_fifo) and (not (fifo_empty or fifo_last))) else '0';
	-- tx_en <= fifo_tvalid and M00_AXIS_TREADY;
	tx_en <= m_axis_tvalid_s and M00_AXIS_TREADY;

	--! Read pointer register
	p_read_ptr_reg: process
	begin
		wait until rising_edge(M00_AXIS_ACLK);
		cnt_fifo_rd_ptr_s <= cnt_fifo_rd_ptr_c;
	end process;
	--! Combinatorial read pointer calculation
	p_read_ptr: process (cnt_fifo_rd_ptr_s, tx_en, fifo_last) 
	begin
			cnt_fifo_rd_ptr_c <= cnt_fifo_rd_ptr_s;
			if tx_en = '1' or fifo_last then
				cnt_fifo_rd_ptr_c <= cnt_fifo_rd_ptr_s + 1;
				if cnt_fifo_rd_ptr_s >= C_FIFO_MEM_SIZE-1 then -- wrap when at the end
					cnt_fifo_rd_ptr_c <= 0;
				end if;
			end if;
	end process;
	------------------------------------------------------------------------------
----------------------------------------------------------
--	MONITOR
----------------------------------------------------------
	--! Monitor controller process, governs the driver process
	p_mntr_ctrl: process
	begin

		pkg_handles(1).ack <= '0';
		report "AXIS BFM Monitor initialized";
		wait for 0 ns;

		loop
			bfm_wait_for_request(pkg_handles(1));
			bfm_ack_request(pkg_handles(1));
			------------------------------
			case bfm_cmd(1).op is
				when idle =>
					monitor_mode_cmd <= idle;
				
				when receive =>
					monitor_mode_cmd <= receive;

				when compare_fifo =>
					monitor_mode_cmd <= compare_fifo;

				when compare_file =>
					monitor_mode_cmd <= compare_file;

				when write_ref =>
					if not ref_full then
						reference(cnt_ref_wr_ptr) <= bfm_cmd(1).data;
						-- Write pointer			
						if cnt_ref_wr_ptr >= C_FIFO_MEM_SIZE-1 then -- wrap when at the end
							cnt_ref_wr_ptr <= 0;
						else
							cnt_ref_wr_ptr <= cnt_ref_wr_ptr + 1;
						end if;
						-- report("Written: "&to_hex(bfm_cmd(0).data)&" to WP: "&integer'image(cnt_fifo_wr_ptr)& ", RP is: "&integer'image(cnt_fifo_rd_ptr)& " fifo_full: "&boolean'image(fifo_full)& " fifo_util: "&integer'image(fifo_utilization));
					else
						report("Error: Write failed, reference fifo is full");
					end if;
					
				when others =>
					null;

			end case;
		end loop;
	end process;

	-- monitor_mode reset asynchronous to controller commands
	monitor_mode <=	idle when S00_AXIS_ARESET = g_RST else monitor_mode_cmd;
	
	-- note: "The destination interface can freely assert and deassert ready at any time.
	-- However, it is beneficial to have the destination interface assert ready as soon
	-- as it can accept data, before the source interface asserts valid,
	-- to shorten handshakes to a single cycle. For the same reason,
	-- the source interface should assert and hold steady valid as soon as it has data to send."
	rx_en <= s_axis_tready_s and S00_AXIS_TVALID;
	S00_AXIS_TREADY <= s_axis_tready_s;
	--! Monitor driver process, actually drives monitor port signals
	p_monitor_driver: process
		variable err_cnt : integer := 0;
	begin
		wait until rising_edge(S00_AXIS_ACLK);
		if S00_AXIS_ARESET = g_RST then
			s_axis_tready_s	<= '0';
			s_axis_tdata 	<= (others => '0');
			s_axis_tuser 	<= (others => '0');
			s_axis_tdest 	<= (others => '0');
			s_axis_tid 		<= (others => '0');
			reference_sig <= (others => '0');
		else
			s_axis_tready_s <= s_axis_tready_c;
			if rx_en = '1' then
				s_axis_tdata 	<= S00_AXIS_TDATA;
				s_axis_tuser 	<= S00_AXIS_TUSER;
				s_axis_tdest 	<= S00_AXIS_TDEST;
				s_axis_tid 		<= S00_AXIS_TID;

				-- assert data vs fifo(cnt_fifo_rd_ptr_s) when compare_fifo
				-- (or when just switched to idle, which is asynchronous)
  			-- note: Why the long conditions? -> So that it doesn't matter whether
				-- the fifo and ref is written to after rising or falling edge
				if (monitor_mode = compare_fifo
					or monitor_mode'delayed(clk_period) = compare_fifo
					or (monitor_mode'delayed(clk_period*2) = compare_fifo and monitor_mode = idle)) then 
						if S00_AXIS_TDATA /= fifo_mem(cnt_fifo_rd_ptr_s) then
							err_cnt := err_cnt + 1;
							assert false
								report("ERROR: data stored: "&integer'image(to_integer(unsigned(S00_AXIS_TDATA)))
											&"; fifo mem: "&integer'image(to_integer(unsigned(fifo_mem(cnt_fifo_rd_ptr_s))))
											&"; at: "&integer'image(cnt_fifo_rd_ptr_s))
								severity Error;
						else
							report("NOTE: data stored: "&integer'image(to_integer(unsigned(S00_AXIS_TDATA)))
										&"; fifo mem: "&integer'image(to_integer(unsigned(fifo_mem(cnt_fifo_rd_ptr_s))))
										&"; at: "&integer'image(cnt_fifo_rd_ptr_s));
						end if;
				elsif (monitor_mode = compare_file
					or monitor_mode'delayed(clk_period) = compare_file
					or (monitor_mode'delayed(clk_period*2) = compare_file and monitor_mode = idle)) then
						reference_sig <= reference(cnt_ref_rd_ptr_s); -- for debugging purposes
						if S00_AXIS_TDATA /= reference(cnt_ref_rd_ptr_s)	then
							err_cnt := err_cnt + 1;
							assert false
								report("ERROR: data stored: "&integer'image(to_integer(unsigned(S00_AXIS_TDATA)))
											&"; ref mem: "&integer'image(to_integer(unsigned(reference(cnt_ref_rd_ptr_s))))
											&"; at: "&integer'image(cnt_ref_rd_ptr_s))
								severity Error;
						else
							report("NOTE: data stored: "&integer'image(to_integer(unsigned(S00_AXIS_TDATA)))
											&"; ref mem: "&integer'image(to_integer(unsigned(reference(cnt_ref_rd_ptr_s))))
											&"; at: "&integer'image(cnt_ref_rd_ptr_s));
						end if;
				end if;
			end if;
			push_err_cnt(err_cnt); -- update error counter in package
		end if;
	end process;


	--! Monitor s_axis_tready combinatorial process
	process (monitor_mode)
	begin
		s_axis_tready_c	<= '0';
		case monitor_mode is
			
			when idle =>
			
			when receive =>
				s_axis_tready_c	<= '1';
				
			when compare_fifo => -- self check
				s_axis_tready_c	<= '1';

			when compare_file =>
				s_axis_tready_c	<= '1';
				
			when others =>
				null;

		end case;
	end process;


	--! Combinatorial reference fifo utilization calculation
	p_ref_fifo_util: process (cnt_ref_rd_ptr_s, cnt_ref_wr_ptr)
	begin
		if cnt_ref_wr_ptr < cnt_ref_rd_ptr_s then
			ref_utilization <= cnt_ref_wr_ptr - cnt_ref_rd_ptr_s + C_FIFO_MEM_SIZE;
		else
			ref_utilization <= cnt_ref_wr_ptr - cnt_ref_rd_ptr_s;
		end if;
	end process;

	ref_last		<= true when ref_utilization = 1 else  false;
	ref_empty		<= true when ref_utilization <= 0 else  false;
	ref_full		<= true when ref_utilization >= C_FIFO_MEM_SIZE-1 else false; -- Keep one open fifo

	push_fifo_util(1, ref_utilization, ref_full, ref_empty, ref_last); -- Push ref (1 refers to monitor) fifo utilization with every change

	--! Read pointer register
	p_ref_read_ptr_reg: process
	begin
		wait until rising_edge(S00_AXIS_ACLK);
		cnt_ref_rd_ptr_s <= cnt_ref_rd_ptr_c;
	end process;
	--! Combinatorial read pointer calculation
	p_ref_read_ptr: process (cnt_ref_rd_ptr_s, rx_en, ref_last) 
	begin
			cnt_ref_rd_ptr_c <= cnt_ref_rd_ptr_s;
			if rx_en = '1' or ref_last then
				cnt_ref_rd_ptr_c <= cnt_ref_rd_ptr_s + 1;
				if cnt_ref_rd_ptr_s >= C_FIFO_MEM_SIZE-1 then -- wrap when at the end
					cnt_ref_rd_ptr_c <= 0;
				end if;
			end if;
	end process;


	--! Formal verification of control signals
	--! Properties:
	--! 
	--! Property 1: TDATA CANNOT change when TVALID is asserted and tx did not occur
	p_prop_ver: process
	begin
		wait until rising_edge(M00_AXIS_ACLK);
		loop
			wait until rising_edge(M00_AXIS_ACLK);
			-- SIGNAL STABILITY CHECK BETWEEN CLOCKS
			-- TDATA MUST be stable between clocks
			assert S00_AXIS_TDATA'stable(clk_period)
				report ("S00_AXIS_TDATA not stable")
				severity failure;
			-- TUSER MUST be stable between clocks
			assert S00_AXIS_TUSER'stable(clk_period)
				report ("S00_AXIS_TUSER not stable")
				severity failure;
			-- TDEST MUST be stable between clocks
			assert S00_AXIS_TDEST'stable(clk_period)
				report ("S00_AXIS_TDEST not stable")
				severity failure;
			-- TID MUST be stable between clocks
			assert S00_AXIS_TID'stable(clk_period)
				report ("S00_AXIS_TID not stable")
				severity failure;
			-- TUSER MUST be stable between clocks
			assert S00_AXIS_TUSER'stable(clk_period)
				report ("S00_AXIS_TUSER not stable")
				severity failure;
			-- TTID MUST be stable between clocks
			assert S00_AXIS_TID'stable(clk_period)
				report ("S00_AXIS_TID not stable")
				severity failure;
			-- TVALID MUST be stable between clocks
			assert S00_AXIS_TVALID'stable(clk_period)
				report ("S00_AXIS_TVALID not stable")
				severity failure;
			-- TREADY MUST be stable between clocks
			assert M00_AXIS_TREADY'stable(clk_period)
				report ("M00_AXIS_TREADY not stable")
				severity failure;

			-- Property 1 - note when is it ok for TDATA, TUSER, TDEST, TID to NOT be stable?
			-- if (TVALID '1' & TVALID'stable(2*clk)) and (TREADY xor TREADY'stable(2*clk))  
			-- i.e.: first sample or link stall -> assert TDATA is has been stable for two clocks
			if	(S00_AXIS_TVALID = '1' and S00_AXIS_TVALID'stable(clk_period*2)) 
					and (to_bool(M00_AXIS_TREADY) xor M00_AXIS_TREADY'stable(clk_period*2)) then
						-- report time'image(now) severity Warning;
						assert S00_AXIS_TDATA'stable(clk_period*2)
							report ("TDATA not stable when link stall")
							severity failure;
			end if;

			if	(S00_AXIS_TVALID = '1' and S00_AXIS_TVALID'stable(clk_period*2)) 
					and (to_bool(M00_AXIS_TREADY) xor M00_AXIS_TREADY'stable(clk_period*2)) then
						-- report time'image(now) severity Warning;
						assert S00_AXIS_TUSER'stable(clk_period*2)
							report ("TUSER not stable when link stall")
							severity failure;
			end if;   

			if	(S00_AXIS_TVALID = '1' and S00_AXIS_TVALID'stable(clk_period*2)) 
					and (to_bool(M00_AXIS_TREADY) xor M00_AXIS_TREADY'stable(clk_period*2)) then
						-- report time'image(now) severity Warning;
						assert S00_AXIS_TDEST'stable(clk_period*2)
							report ("TDEST not stable when link stall")
							severity failure;
			end if;

			if	(S00_AXIS_TVALID = '1' and S00_AXIS_TVALID'stable(clk_period*2)) 
					and (to_bool(M00_AXIS_TREADY) xor M00_AXIS_TREADY'stable(clk_period*2)) then
						-- report time'image(now) severity Warning;
						assert S00_AXIS_TID'stable(clk_period*2)
							report ("TID not stable when link stall")
							severity failure;
			end if;

		end loop;
	end process;
	
end bfm;