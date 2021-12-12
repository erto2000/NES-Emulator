library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity Timing_Logic is
    generic(
        DATA_WIDTH: integer := 8
    );
    port(
        rst: in std_logic;
        clk_ph1: in std_logic;
        PD: in std_logic_vector(DATA_WIDTH-1 downto 0);
        cycle_increment: in std_logic;
        cycle_reset: in std_logic;
        cycle: out integer range 0 to 7;
        IR: out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end Timing_Logic;

architecture Behavioral of Timing_Logic is
    signal next_cycle: integer;
    signal next_IR: std_logic_vector(DATA_WIDTH-1 downto 0);
begin
    next_cycle <= 0 when cycle_reset = '1' else
                  next_cycle + 1 when cycle_increment = '1' else
                  next_cycle;
    
    next_IR <= PD when next_cycle = 0 else
               IR;
    
    process(clk_ph1) begin
        if(rising_edge(clk_ph1)) then
            if(rst = '1') then
                cycle <= 0;
                IR <= (others => '0');
            else
                cycle <= next_cycle; 
                IR <= next_IR;
            end if;     
        end if;
    end process;
end Behavioral;
























