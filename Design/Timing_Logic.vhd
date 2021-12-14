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
        cycle_increment:    in std_logic;
        cycle_reset:        in std_logic;
        cycle:              out integer range 0 to 7;
        IR:                 out std_logic_vector(DATA_WIDTH-1 downto 0);
        sync:               out std_logic
    );
end Timing_Logic;

architecture Behavioral of Timing_Logic is
    signal next_cycle:   integer range 0 to 7;
    signal cycle_reg:    integer range 0 to 7 := 0;
    signal next_IR:      std_logic_vector(DATA_WIDTH-1 downto 0);
    signal IR_reg:       std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    signal next_sync:    std_logic;
    signal sync_reg:     std_logic;
begin
    cycle <= cycle_reg;
    IR <= IR_reg;
    sync <= sync_reg;

    next_cycle <= 0 when cycle_reset = '1' else
                  cycle_reg + 1 when cycle_increment = '1' else
                  cycle_reg;
               
    process(next_cycle, int_flag, PD, IR_reg) begin
        if(next_cycle = 0) then
            next_sync <= '1';
            if(int_flag = '1') then
                next_IR <= (others => '0');
            else
                next_IR <= PD;
            end if;
        else    
            next_sync <= '0';
            next_IR <= IR_reg;
        end if;
    end process;
    
    process(clk_ph1) begin
        if(rising_edge(clk_ph1)) then
            if(rst = '1') then
                cycle_reg <= 0;
                IR_reg <= (others => '0');
                sync_reg <= '1';
            else
                cycle_reg <= next_cycle; 
                IR_reg <= next_IR;
                sync_reg <= next_sync;
            end if;     
        end if;
    end process;
end Behavioral;
























