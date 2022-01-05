library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity CPU_First_Test is
end CPU_First_Test;

architecture Behavioral of CPU_First_Test is
    signal clk: std_logic;
    signal r_nw: std_logic;
    signal w_nr: std_logic;
    signal address: std_logic_vector(15 downto 0);
    signal data: std_logic_vector(7 downto 0);
begin
    w_nr <= not r_nw;

    process begin
        clk <= '0';
        wait for 10;
        clk <= '1';
        wait for 10;
    end process;
    
    a: entity work.CPU
    port map(
        rst => '0',
        clk => clk,
        BE => '1',
        rdy => '1',
        irq => '1',
        nmi => '1',
        sync => open,
        r_nw => r_nw,
        address => address,
        data => data
    );
    
    b: entity work.RAM
    port map(
        clk => clk,
        WE => w_nr,
        enable => '1',
        address => address,
        data => data        
    );

end Behavioral;
























