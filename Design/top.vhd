library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity top is
    port(
        clk: in std_logic;    
        irq: in std_logic;
        data_out: out std_logic_vector(7 downto 0)
    );
end top;

architecture Behavioral of top is
    signal r_nw: std_logic;
    signal w_nr: std_logic;
    signal address: std_logic_vector(15 downto 0);
    signal data: std_logic_vector(7 downto 0);
begin
    w_nr <= not r_nw;
    data_out <= data;
    
    a: entity work.CPU
    port map(
        rst => '0',
        clk => clk,
        BE => '1',
        rdy => '1',
        irq => irq,
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
























