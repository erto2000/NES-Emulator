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
    signal cycle_reg             : integer range 0 to 7 := 0;
    signal IR                    : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
begin
    cycle <= cycle_reg;
    instruction <= IR;
    sync <= cycle_reset; --Inform user of the cpu while fetching opcode
                                   
    --Change cycle and instruction on clk_ph1
    process(clk) begin
        if(rising_edge(clk) and clk_ph1 = '0') then --rising edge ph1
            if(rst = '1') then
                cycle_reg <= 0;
                IR <= (others => '0');
            else
                cycle_reg <= 0 when cycle_reset = '1' else                     
                             cycle_reg + 1 when cycle_increment = '1' else     
                             cycle_reg + 2 when cycle_skip = '1' else          
                             cycle_reg + 3 when cycle_double_skip = '1' else   
                             cycle_reg;   
               
                IR <= (others => '0') when (cycle_reset and (irq_flag or nmi_flag)) = '1' else                     
                      PD when cycle_reset = '1';                                                
            end if;  
        end if; 
    end process;
end Behavioral;
























