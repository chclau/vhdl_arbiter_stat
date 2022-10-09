----------------------------------------------------------------------------------
-- Company:  FPGA'er
-- Engineer: Claudio Avi Chami - FPGA'er Website
--           http://fpgaer.tech
-- Create Date: 27.09.2022 
-- Module Name: arbiter_unc.vhd
-- Description: Variable width arbiter with fixed priority
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

entity arbiter_unc is
  port (
    clk  : in  std_logic;
    rstn : in  std_logic;

    -- inputs
    req  : in  std_logic_vector;
    busy : in  std_logic;

    -- outputs
    gnt  : out std_logic_vector
  );
end arbiter_unc;

architecture rtl of arbiter_unc is
  signal busy_d : std_logic;
  signal busy_fe : std_logic;

begin
  busy_pr : process (clk)
  begin
    if (rising_edge(clk)) then
      busy_d <= busy;
    end if;
  end process busy_pr;

  -- Falling edge of busy signal
  busy_fe <= '1' when busy = '0' and busy_d = '1' else '0';

  arbiter_pr : process (clk)
    variable prio_req : std_logic;
  begin
    if (rising_edge(clk)) then
      if (rstn = '0') then
        gnt <= (others => '0');
      else  
        if (busy_fe = '1') then
          gnt <= (others => '0');
        elsif (busy = '0') then
          gnt(0) <= req(0);
          for I in 1 to req'left loop
            prio_req := '0';
            for J in 1 to I loop
              prio_req := prio_req or req(J - 1);
            end loop;
            gnt(I) <= req(I) and not prio_req;
          end loop;
        end if;
      end if;
    end if;  
  end process arbiter_pr;

end rtl;