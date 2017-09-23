------------------------------------------------------------------
-- Name		     : timestamp.vhd
-- Description : Timestamp for testing of arbiter
-- Designed by : Claudio Avi Chami - FPGA Site
--               http://fpgasite.blogspot.com
-- Version     : 01
------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity timestamp is
	port (
		clk: 		 in  std_logic;
		rst: 		 in  std_logic;
		
		-- outputs
		t_stamp: out std_logic_vector(31 downto 0)
		
	);
end timestamp;


architecture rtl of timestamp is

begin 

  tstamp_pr: process (clk, rst) 
    variable cnt      : integer range 0 to 9;
    variable tstamp_i : unsigned(31 downto 0);
  begin 
    if (rst = '1') then 
      cnt   		:= 0;
      tstamp_i  := (others => '0');
    elsif (rising_edge(clk)) then
      if (cnt < 9) then
        cnt := cnt + 1;
      else
        tstamp_i := tstamp_i + 1;
        cnt      := 0;
      end if;
    end if;
    t_stamp <= std_logic_vector(tstamp_i);

  end process tstamp_pr;
  

end rtl;