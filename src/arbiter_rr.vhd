----------------------------------------------------------------------------------------------------------------------------------------------------
-- Company:  FPGA'er
-- Engineer: Claudio Avi Chami - FPGA'er Website
--           http://fpgaer.tech
-- Create Date: 05.10.2022 
-- Module Name: arbiter_rr.vhd
-- Description: Round-robin arbiter
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

entity arbiter_rr is
	port (
		clk: 		in std_logic;
		rstn: 	in std_logic;
		
		-- inputs
		req:		in std_logic_vector;
		
		-- outputs
		gnt:		out std_logic_vector
	);
end arbiter_rr;

architecture rtl of arbiter_rr is

	signal double_req : unsigned(2*req'left+1 downto 0);
	signal double_gnt : unsigned(2*req'left+1 downto 0);
	signal priority : unsigned(req'left downto 0);
	signal last_req : std_logic_vector(req'left downto 0);
	
	begin 

double_req	<= unsigned(req & req);
double_gnt  <= double_req and not (double_req-priority);	

arbiter_pr: process (clk) 
	begin 
    if (rising_edge(clk)) then
      if (rstn = '0') then 
        priority(req'left downto 1) <= (others => '0');
        priority(0)	<= '1';
        last_req	  <= (others => '0');
        gnt			    <= (others => '0');
      elsif (last_req /= req) then
        priority(req'left downto 1) <= priority(req'left-1 downto 0);
        priority(0) <= priority(req'left);
        last_req	  <= req;
        gnt 		    <= std_logic_vector(double_gnt(req'left downto 0) or double_gnt(2*req'left+1 downto req'left+1));
      end if;	
    end if;
end process arbiter_pr;

end rtl;