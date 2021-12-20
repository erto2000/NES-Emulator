library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity Timing_Logic is
    generic(
        DATA_WIDTH: integer := 8
    );
    port(
        rst, clk_ph1       : in std_logic;
        PD                 : in std_logic_vector(DATA_WIDTH-1 downto 0);
        interrupt          : in std_logic;
        cycle_increment    : in std_logic;
        cycle_skip         : in std_logic;
        cycle_reset        : in std_logic;
        cycle              : out integer range 0 to 7;
        instruction        : out std_logic_vector(DATA_WIDTH-1 downto 0);
        sync               : out std_logic
    );
end Timing_Logic;

architecture Behavioral of Timing_Logic is
    signal next_cycle   : integer range 0 to 7;
    signal cycle_reg    : integer range 0 to 7 := 0;
    signal next_IR      : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal IR           : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
begin
    cycle <= cycle_reg;
    instruction <= IR;
    sync <= cycle_reset; --Inform user of the cpu while fetching opcode

    --Determine next cycle based on the control input
    next_cycle <= 0 when cycle_reset = '1' else
                  cycle_reg + 1 when cycle_increment = '1' else
                  cycle_reg + 1 when cycle_skip = '1' else
                  cycle_reg;
    
    --Fetch new opcode or start interrupt or do nothing
    process(next_cycle, interrupt, PD, IR) begin
        if(next_cycle = 0) then
            if(interrupt = '1') then
                next_IR <= (others => '0'); --BRK instruction
            else
                next_IR <= PD;
            end if;
        else
            next_IR <= IR;
        end if;
    end process;
    
    --Change cycle and instruction on clk_ph1
    process(clk_ph1) begin
        if(rising_edge(clk_ph1)) then
            if(rst = '1') then
                cycle_reg <= 0;
                IR <= (others => '0');
            else
                cycle_reg <= next_cycle;
                IR <= next_IR;
            end if;  
        end if; 
    end process;
end Behavioral;
























