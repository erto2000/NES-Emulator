library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity Timing_Logic is
    generic(
        DATA_WIDTH: integer := 8
    );
    port(
        rst, clk, clk_ph1                : in std_logic;
        PD                               : in std_logic_vector(DATA_WIDTH-1 downto 0);
        irq_flag, nmi_flag               : in std_logic;
        cycle_increment                  : in std_logic;
        cycle_skip                       : in std_logic;
        cycle_double_skip                : in std_logic;
        cycle_reset                      : in std_logic;
        cycle                            : out integer range 0 to 7;
        instruction                      : out std_logic_vector(DATA_WIDTH-1 downto 0);
        sync                             : out std_logic
    );
end Timing_Logic;

architecture Behavioral of Timing_Logic is
    signal next_cycle            : integer range 0 to 7;
    signal cycle_reg             : integer range 0 to 7 := 0;
    signal next_IR               : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal IR                    : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
begin
    cycle <= cycle_reg;
    instruction <= IR;
    sync <= cycle_reset; --Inform user of the cpu while fetching opcode

    --Determine next cycle based on the control input
    next_cycle <= 0 when cycle_reset = '1' else
                  cycle_reg + 1 when cycle_increment = '1' else
                  cycle_reg + 2 when cycle_skip = '1' else
                  cycle_reg + 3 when cycle_double_skip = '1' else
                  cycle_reg;
    
    --Fetch new opcode or start interrupt or do nothing
    process(next_cycle, irq_flag, nmi_flag, PD, IR) begin
        if(next_cycle = 0) then
            if(irq_flag = '1' or nmi_flag = '1') then
                next_IR <= (others => '0'); --BRK instruction
            else
                next_IR <= PD;
            end if;
        else
            next_IR <= IR;
        end if;
    end process;
    
    --Change cycle and instruction on clk_ph1
    process(clk) begin
        if(rising_edge(clk) and clk_ph1 = '0') then --rising edge ph1
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
























