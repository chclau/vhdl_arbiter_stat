------------------------------------------------------------------
-- Name		   : arbiter.vhd
-- Description : Very simple arbiter with fixed priority
-- Designed by : Claudio Avi Chami - FPGA Site
-- Date        : 13/04/2016
-- Version     : 01
------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity arbiter_gen is
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
end arbiter_gen;


architecture rtl of arbiter_gen is

begin 

  arbiter_pr: process (clk, rst) 
    variable prio_req : std_logic;
  begin 
    if (rst = '1') then 
      gnt <= (others => '0');
    elsif (rising_edge(clk)) then
      gnt(0) <= req(0);
      for I in 1 to ARBITER_W-1 loop
        prio_req := '0';
        for J in 1 to I loop
          prio_req := prio_req or req(J-1);
        end loop;
        gnt(I) <= req(I) and not prio_req;
      end loop;
    end if;
  end process arbiter_pr;

end rtl;