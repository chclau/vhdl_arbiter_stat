------------------------------------------------------------------
-- Name	       : tb_arb_rr.vhd
-- Description : Testbench for round-robin arbiter
-- Designed by : Claudio Avi Chami - FPGA Site
-- Version     : 01
------------------------------------------------------------------
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.std_logic_textio.all;
    use ieee.numeric_std.ALL;
    use std.textio.all;
    
entity tb_arb_gen is
end entity;

architecture test of tb_arb_gen is

  constant PERIOD     : time   := 20 ns;
  constant ARBITER_W  : natural := 4;
	
  signal clk          : std_logic := '0';
  signal rst          : std_logic := '1';
  signal req          : std_logic_vector(ARBITER_W-1 downto 0) := (others => '0');
  signal gnt          : std_logic_vector(ARBITER_W-1 downto 0) := (others => '0');
  signal t_stamp      : std_logic_vector(31 downto 0);
  signal endSim	      : boolean   := false;

  type STAT_ARR1  is array (0 to ARBITER_W-1) of real;  
  type STAT_ARR2  is array (0 to ARBITER_W-1) of std_logic_vector(31 downto 0);
  
  signal no_of_transactions : STAT_ARR1;
  signal max_latency        : STAT_ARR1;
  signal max_latency_tstamp : STAT_ARR2;
  signal ave_latency        : STAT_ARR1;
  signal accum_duration     : STAT_ARR1;  
  
  component arbiter_gen  is
    generic (
      ARBITER_W		: natural := 4
    );
    port (
      clk: 		in std_logic;
      rst: 		in std_logic;
      
      -- inputs
      req:		in std_logic_vector(ARBITER_W-1 downto 0);
      
      -- outputs
      gnt:		out std_logic_vector(ARBITER_W-1 downto 0)
    );
  end component;  

  component timestamp is
    port (
      clk: 		 in  std_logic;
      rst: 		 in  std_logic;
      
      -- outputs
      t_stamp: out std_logic_vector(31 downto 0)
    );
  end component timestamp;

  component bus_agent is
    port (
      clk: 		 in std_logic;
      rst: 		 in std_logic;
      
      -- inputs
      gnt:		 in std_logic;
      t_stamp: in std_logic_vector(31 downto 0);
		  stat_no: in integer;
      
      -- outputs
      req:		 out std_logic;
      
      -- statistic outputs
      no_of_transactions   : out real;
      max_latency          : out real;
      max_latency_tstamp   : out std_logic_vector(31 downto 0);
      accum_duration       : out real;  
      ave_latency          : out real  
    );
  end component bus_agent;

begin
    clk     <= not clk after PERIOD/2;
    rst     <= '0' after  PERIOD*10;

    GEN_AGENT: 
      for I in 0 to ARBITER_W-1 generate
        bus_agent_i : bus_agent
          port map(
            clk 		            => clk 		       ,
            rst 		            => rst 		       ,  
            gnt 		            => gnt(I)        , 		         
            t_stamp             => t_stamp       ,   
            stat_no             => (I+1)         ,   
            req 		            => req(I)        ,		         
                             
            -- statistic outputs
            no_of_transactions  => no_of_transactions(I)  ,
            max_latency         => max_latency(I)         ,
            max_latency_tstamp  => max_latency_tstamp(I)  , 
            ave_latency         => ave_latency(I)         ,
            accum_duration      => accum_duration(I)       
      );
    end generate GEN_AGENT; 

	-- Main simulation process
	process 
	begin   
		for I in 0 to 5000 loop
			wait until (rising_edge(clk));
		end loop;	
		endSim  <= true;
	end	process;	

	-- Calculate global statistics
	process 
    variable global_req          : integer;
    variable no_of_global_trans  : real;
    variable global_duration     : real;
    variable ave_global_duration : real;
    variable ave_global_latency  : real;
	begin   
    no_of_global_trans  := 0.0;
    global_duration     := 0.0;
    ave_global_duration := 0.0;
    ave_global_latency  := 0.0;   
    global_req          := 0;   

    -- Wait a while until there is a transaction
		wait until (unsigned(gnt) > 0);
    wait until (rising_edge(clk));
		wait until (rising_edge(clk));
  
    while(true) loop
      no_of_global_trans  := 0.0;
      global_duration     := 0.0;
      ave_global_duration := 0.0;
      ave_global_latency  := 0.0;
      global_req          := 0;

      for I in 0 to ARBITER_W-1 loop
        if (req(I) = '1') then
          global_req  := global_req + 1;
        end if;  
        no_of_global_trans := no_of_global_trans + no_of_transactions(I);
        global_duration    := global_duration + accum_duration(I);
        ave_global_latency := ave_global_latency + ave_latency(I);
      end loop;	
      ave_global_duration  := global_duration / no_of_global_trans;
      ave_global_latency   := ave_global_latency / real(ARBITER_W);
      
      wait until (rising_edge(clk));
    end loop;  
	end	process;	 
  
	-- End the simulation
	process 
	begin
		if (endSim) then
			assert false 
				report "End of simulation." 
				severity failure; 
		end if;
		wait until (rising_edge(clk));
	end process;	

  arb_inst : arbiter_gen
    generic map (
	  	ARBITER_W	 => ARBITER_W
	  )
    port map (
        clk      => clk,
        rst	     => rst,
		
        req  	   => req,
        gnt      => gnt
    );
    
  tstamp_i : timestamp
    port map (
      clk       => clk      ,
      rst       => rst      ,
      
      -- outputs
      t_stamp   => t_stamp
    );

end architecture;