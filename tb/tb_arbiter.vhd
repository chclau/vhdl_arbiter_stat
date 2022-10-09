----------------------------------------------------------------------------------
-- Company:  FPGA'er
-- Engineer: Claudio Avi Chami - FPGA'er Website
--           http://fpgaer.tech
-- Create Date: 25.09.2022 
-- Module Name: tb_arbiter.vhd
-- Description: testbench for round-robin arbiter + fixed width priority arbiter
--              uses agents to emulate request-grant behavior
--
-- Dependencies: arbiter_rr.vhd
--               arbiter_unc.vhd
--               bus_agent.vhd
-- 
-- Revision: 1
-- Revision  1 - Initial version
-- 
----------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;
use ieee.numeric_std.all;
use std.textio.all;

entity tb_arbiter is
end entity;

architecture test of tb_arbiter is

  constant PERIOD : time := 20 ns;
  constant ARBITER_W : natural := 3;

  signal clk : std_logic := '0';
  signal rstn : std_logic := '0';
  
  -- rr - Round robin signals
  signal busy_rr : std_logic := '0';
  signal req_rr : std_logic_vector(ARBITER_W - 1 downto 0) := (others => '0');
  signal gnt_rr : std_logic_vector(ARBITER_W - 1 downto 0);
  signal busy_arr_rr : std_logic_vector(ARBITER_W - 1 downto 0);

  -- fp = Fixed priority signals
  signal busy_fp : std_logic := '0';
  signal req_fp : std_logic_vector(ARBITER_W - 1 downto 0) := (others => '0');
  signal gnt_fp : std_logic_vector(ARBITER_W - 1 downto 0);
  signal busy_arr_fp : std_logic_vector(ARBITER_W - 1 downto 0);

  type int_arr_T is array (0 to 2*ARBITER_W-1) of integer;
  type real_arr_T is array (0 to 2*ARBITER_W-1) of real;
  signal num_trans_arr : int_arr_T;
  signal max_lat_arr   : int_arr_T;
  signal timeouts_arr   : int_arr_T;
  
  signal endSim : boolean := false;

  component arbiter_rr is
    port (
      clk  : in  std_logic;
      rstn : in  std_logic;

      -- inputs
      req  : in  std_logic_vector;

      -- outputs
      gnt  : out std_logic_vector
    );
  end component;

  component arbiter_unc is
    port (
      clk  : in  std_logic;
      rstn : in  std_logic;

      -- inputs
      busy : in  std_logic;
      req  : in  std_logic_vector;

      -- outputs
      gnt  : out std_logic_vector
    );
  end component;

  component bus_agent is
    port (
      clk: 		 in std_logic;
      rstn: 	 in std_logic;
      
      -- inputs
      busy_in: in std_logic;
      gnt:		 in std_logic;
      
      -- outputs
      req:		 out std_logic;
      
      -- 
      busy:		 out std_logic;
      
      -- statistic outputs
      no_of_transactions   : out integer;
      max_latency          : out integer;
      timeouts             : out integer    
    );
  end component;
  
begin
  clk  <= not clk after PERIOD/2;
  rstn <= '1' after PERIOD * 10;

  busy_rr_pr : process (busy_arr_rr)
    variable busy_var : std_logic;
  begin
    busy_var := busy_arr_rr(0);
    for i in 1 to ARBITER_W-1 loop
      busy_var := busy_var or busy_arr_rr(i);
    end loop;
    busy_rr <= busy_var;
  end process;

  busy_rr_fp : process (busy_arr_fp)
    variable busy_var : std_logic;
  begin
    busy_var := busy_arr_fp(0);
    for i in 1 to ARBITER_W-1 loop
      busy_var := busy_var or busy_arr_fp(i);
    end loop;
    busy_fp <= busy_var;
  end process;
  
  -- Main simulation process
  process
  begin
    wait until (rstn = '1');
    wait until (rising_edge(clk));
    wait for 200 us; 
    
    endSim <= true;
  end process;

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

  rr_arb_inst : arbiter_rr
  port map(
    clk  => clk,
    rstn => rstn,

    req  => req_rr,
    gnt  => gnt_rr
  );
  
  fp_arb_inst : arbiter_unc
  port map(
    clk  => clk,
    rstn => rstn,

    busy => busy_fp,
    req  => req_fp,
    gnt  => gnt_fp
  );

  gen_agent_rr : for i in 0 to ARBITER_W-1 generate
    bus_agent_i : bus_agent
      port map (
        clk      => clk   ,
        rstn     => rstn  ,
        gnt      => gnt_rr(i),
        req      => req_rr(i),
        busy_in  => busy_rr,
        busy     => busy_arr_rr(i),
        no_of_transactions   => num_trans_arr(i)   ,
        max_latency          => max_lat_arr(i)   ,
        timeouts             => timeouts_arr(i)     
     );
  end generate gen_agent_rr;  
  
  gen_agent_fp : for i in 0 to ARBITER_W-1 generate
    bus_agent_i : bus_agent
      port map (
        clk      => clk   ,
        rstn     => rstn  ,
        gnt      => gnt_fp(i),
        req      => req_fp(i),
        busy_in  => busy_fp,
        busy     => busy_arr_fp(i),
        no_of_transactions   => num_trans_arr(ARBITER_W+i)    ,
        max_latency          => max_lat_arr(ARBITER_W+i)   ,
        timeouts             => timeouts_arr(ARBITER_W+i)        
     );
  end generate gen_agent_fp;    

end architecture;