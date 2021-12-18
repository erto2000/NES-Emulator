library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity Timing_Logic is
    generic(
        DATA_WIDTH: integer := 8
    );
    port(
        rst, clk_ph1:       in std_logic;
        PD:                 in std_logic_vector(DATA_WIDTH-1 downto 0);
        int_flag:           in std_logic;
        brk_clr:            in std_logic;
        cycle_increment:    in std_logic;
        cycle_reset:        in std_logic;
        cycle:              out integer range 0 to 7;
        instruction:        out std_logic_vector(DATA_WIDTH-1 downto 0);
        brk_flag:           out std_logic := '0';
        sync:               out std_logic
    );
end Timing_Logic;

architecture Behavioral of Timing_Logic is
    signal next_cycle:          integer range 0 to 7;
    signal cycle_reg:           integer range 0 to 7 := 0;
    signal next_IR:             std_logic_vector(DATA_WIDTH-1 downto 0);
    signal IR:                  std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    constant ZERO:              std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
begin
    cycle <= cycle_reg;
    instruction <= IR;
    sync <= cycle_reset;

    next_cycle <= 0 when cycle_reset = '1' else
                  cycle_reg + 1 when cycle_increment = '1' else
                  cycle_reg;
    
    process(next_cycle, int_flag, PD, IR) begin
        if(next_cycle = 0) then
            if(int_flag = '1') then
                next_IR <= (others => '0');
            else
                next_IR <= PD;
            end if;
        else
            next_IR <= IR;
        end if;
    end process;
    
    process(clk_ph1) begin
        if(rising_edge(clk_ph1)) then
            if(rst = '1') then
                cycle_reg <= 0;
                IR <= (others => '0');
                brk_flag <= '0';
            else
                cycle_reg <= next_cycle;
                IR <= next_IR;
                
                if(next_IR = ZERO and int_flag = '0') then
                    brk_flag <= '1';
                elsif(brk_clr = '1') then
                    brk_flag <= '0';
                end if;
            end if;  
        end if; 
    end process;
end Behavioral;
























