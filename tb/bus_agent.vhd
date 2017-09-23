------------------------------------------------------------------
-- Name		     : bus_agent.vhd
-- Description : Agent for testing of arbiter
-- Designed by : Claudio Avi Chami - FPGA Site
--               http://fpgasite.blogspot.com
-- Version     : 01
------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;


entity bus_agent is
	port (
		clk: 		 in std_logic;
		rst: 		 in std_logic;
		
		-- inputs
		gnt:		  in std_logic;
		t_stamp:  in std_logic_vector(31 downto 0);
		stat_no:  in integer;
		
		-- outputs
		req:		  out std_logic;
    
    -- statistic outputs
    no_of_transactions   : out real;
    max_latency          : out real;
    max_latency_tstamp   : out std_logic_vector(31 downto 0);
    ave_latency          : out real;  
    accum_duration       : out real  
	);
end bus_agent;

architecture rtl of bus_agent is

  constant MIN_DURATION : natural := 7;
  constant MAX_DURATION : natural := 15;
  signal   THRESHOLD_LO : real;
  signal   THRESHOLD_HI : real;
  signal   THRESHOLD    : real := 0.04;
  
  signal   req_i        : std_logic;
  signal   gnt_d        : std_logic;
  signal   gnt_re       : std_logic;
  signal   gnt_re_d     : std_logic;
  signal   no_of_transactions_i : real;
  
begin 

  -- generate requests
  gen_req_pr: process (clk, rst) 
    variable seed1, seed2: positive;            -- seed values for random generator
    variable rand: real;                        -- random real-number value in range 0 to 1.0  
    variable duration: integer range 0 to 100;                   
    variable accum_duration_i: real;                   
  begin 
    if (rst = '1') then 
      req_i		         <= '0';
      accum_duration_i := 0.0;
      
      -- The thresholds are assigned values dependant on their station value so each station will start
      -- random requests at different times
      THRESHOLD_LO <= real(stat_no)/10.0;
      THRESHOLD_HI <= real(stat_no)/10.0+THRESHOLD;
    elsif (rising_edge(clk)) then
      if (gnt = '1') then
        -- Keep track of duration of current 'transaction'
        if (duration > 0) then
          duration := duration - 1;
        else
          req_i    <= '0';
        end if;          
      elsif (req_i = '0') then
        uniform(seed1, seed2, rand);            -- generate random number
        if (rand > THRESHOLD_LO) and (rand < THRESHOLD_HI) then
          uniform(seed1, seed2, rand);          -- generate random number
          duration := MIN_DURATION + integer(rand*(real(MAX_DURATION - MIN_DURATION)));
          accum_duration_i := accum_duration_i + real(duration);
          req_i    <= '1';
        end if;          
      end if;
    end if;   
    accum_duration <= accum_duration_i;
    
  end process gen_req_pr;

  req <= req_i;
  
  -- keep track of values for statistics
  -- grant signal rising edge
  gnt_pr: process (clk, rst) 
  begin 
    if (rst = '1') then 
      gnt_d		  <= '0';
      gnt_re_d	<= '0';
    elsif (rising_edge(clk)) then
      gnt_d     <= gnt;
      gnt_re_d  <= gnt_re;
    end if;
  end process gnt_pr;
  
  gnt_re <= '1' when gnt_d = '0' and gnt = '1' else '0';
  
  -- calculate latency
  lat_pr: process (rst, clk) 
    variable latency : real;
    variable max_latency_i : real;
    variable accum_latency : real;
  begin 
    if (rst = '1') then 
      max_latency_i  := 0.0;
      accum_latency  := 0.0;
      max_latency_tstamp <= (others => '0');
      ave_latency   <= 0.0; 
    elsif (rising_edge(clk)) then
      if (req_i = '0') then
        latency := 0.0;
      else
        if (gnt = '0') then
          latency := latency + 1.0; 
        elsif (gnt_re_d = '1') then
          -- Update statistic counters    
          if (latency > max_latency_i) then
            max_latency_i      := latency;
            max_latency_tstamp <= t_stamp;
          end if;
          
          accum_latency := accum_latency + latency;
          ave_latency   <= accum_latency / no_of_transactions_i;
        end if;  
      end if;    
        
    end if;
    max_latency <= max_latency_i;
  end process lat_pr;
  
  -- count transactions
  transaction_cnter_pr: process (rst, clk) 
  begin
    if (rst = '1') then 
      no_of_transactions_i  <= 0.0;
    elsif (rising_edge(clk)) then
      if (gnt_re) = '1' then
        no_of_transactions_i  <= no_of_transactions_i + 1.0;
      end if;
    end if;
  end process transaction_cnter_pr;
  no_of_transactions <= no_of_transactions_i;  
  
end rtl;