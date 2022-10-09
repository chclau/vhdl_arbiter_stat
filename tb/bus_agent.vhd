----------------------------------------------------------------------------------
-- Company:  FPGA'er
-- Engineer: Claudio Avi Chami - FPGA'er Website
--           http://fpgaer.tech
-- Create Date: 09.10.2022 
-- Module Name: bus_agent.vhd
-- Description: Simulation file for testing an arbiter
--              Generates realistic req vs gnt behavior for a 
--              master connected to an arbiter
--              
-- Dependencies: none
-- 
-- Revision: 1
-- Revision  1 - Initial release
-- 
----------------------------------------------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bus_agent is
  port (
    clk                : in  std_logic;
    rstn               : in  std_logic;

    -- inputs
    gnt                : in  std_logic;
    busy_in            : in  std_logic;

    -- outputs
    req                : out std_logic;
    busy               : out std_logic;

    -- statistic outputs
    no_of_transactions : out integer;
    max_latency        : out integer;
    timeouts           : out integer
  );
end bus_agent;

architecture rtl of bus_agent is

  constant DURATION : natural := 6;
  constant PAUSE : natural := 30;
  constant TIMEOUT : natural := 127;

  type st_T is (idle, pause_st, req_st, timeout_st, send);
  signal st : st_T;
  signal packet_duration : integer;
  signal packet_pause : integer;
  signal latency : integer;
begin

  -- generate requests
  gen_req_pr : process (clk)
  begin
    if (rising_edge(clk)) then
      if (rstn = '0') then
        req <= '0';
        no_of_transactions <= 0;
        max_latency <= 0;
        timeouts <= 0;
        busy <= '0';
        st <= idle;
      else
        case st is
          when idle =>
            latency <= 0;
            st <= req_st;
          when req_st =>
            req <= '1';
            if (latency = TIMEOUT) then
              req <= '0';
              st <= timeout_st;
            elsif (gnt = '1' and busy_in = '0') then
              -- Grant received, update max_latency
              if (latency > max_latency) then
                max_latency <= latency;
              end if;
              no_of_transactions <= no_of_transactions + 1;
              packet_duration <= DURATION - 1;
              busy <= '1';
              st <= send;
            else
              latency <= latency + 1;
            end if;
          when timeout_st =>
            timeouts <= timeouts + 1;
            packet_pause <= pause;
            st <= pause_st;
          when send =>
            req <= '0';
            if (packet_duration = 0) then
              packet_pause <= PAUSE - 1;
              busy <= '0';
              st <= pause_st;
            else
              packet_duration <= packet_duration - 1;
            end if;
          when pause_st =>
            if (packet_pause = 0) then
              st <= idle;
            else
              packet_pause <= packet_pause - 1;
            end if;
        end case;
      end if;
    end if;
  end process gen_req_pr;

end rtl;