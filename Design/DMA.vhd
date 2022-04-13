library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity DMA is
    generic(
        DATA_WIDTH: integer := 8;
        ADDRESS_WIDTH: integer := 16
    );
    port(
        clk, CS: in std_logic;
        rdy: out std_logic;
        r_nw: inout std_logic;
        address: inout std_logic_vector(ADDRESS_WIDTH-1 downto 0);
        data: inout std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end DMA;

architecture Behavioral of DMA is
    signal clk_counter              : integer range 0 to 11 := 0; -- Master clock tick
    signal odd_cpu_cycle_flag       : std_logic := '0';
    
    type transfer_state is (idle, wait_instruction, wait_odd_cycle, read, write);
    signal state                    : transfer_state := idle;
    signal transfer_address         : std_logic_vector(ADDRESS_WIDTH-1 downto 0) := (others => '0');
    signal read_data                : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
begin

    rdy <= '0' when state = wait_odd_cycle or state = read or state = write else
           '1';
           
    r_nw <= '1' when state = read else
            '0' when state = write else
            'Z';
           
    address <= transfer_address when state = read else
               x"2004" when state = write else
               (others => 'Z');
           
    data <= read_data when state = write else
            (others => 'Z');
            
    clk_generation: process(clk) begin
        if(rising_edge(clk)) then
            clk_counter <= clk_counter + 1 when clk_counter < 11 else
                           0;
                           
            odd_cpu_cycle_flag <= not odd_cpu_cycle_flag when clk_counter = 11;
            
            case state is
                when idle =>
                    if(CS = '1' and r_nw = '0') then
                        if(clk_counter = 5) then
                            transfer_address <= (data, others => '0');
                        elsif(clk_counter = 11) then
                            state <= wait_instruction;
                        end if;
                    end if;    
                
                when wait_instruction =>
                    if(clk_counter = 11) then
                        if(odd_cpu_cycle_flag = '1') then
                            state <= wait_odd_cycle;
                        else
                            state <= read;
                        end if;
                    end if;
                
                when wait_odd_cycle =>
                    if(clk_counter = 11) then
                        state <= read;
                    end if;
                
                when read =>
                    if(clk_counter = 5) then
                        read_data <= data;
                    elsif(clk_counter = 11) then
                        state <= write;
                    end if;
                    
                when write =>
                    if(clk_counter = 11) then
                        if(transfer_address(DATA_WIDTH-1 downto 0) = x"FF") then 
                            state <= idle;
                        else
                            transfer_address <= transfer_address + 1;
                            state <= read;
                        end if;
                    end if;
                    
                when others =>
            end case;
        end if;
    end process;


end Behavioral;























