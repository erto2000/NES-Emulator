library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity top is
    port(
        clk: in std_logic;    
        data_out: out std_logic_vector(7 downto 0)
    );
end top;

architecture Behavioral of top is
    signal r_nw: std_logic;
    signal w_nr: std_logic;
    signal NMI: std_logic;
    signal address: std_logic_vector(15 downto 0);
    signal data: std_logic_vector(7 downto 0);

    signal CS  : std_logic;
    signal ALE : std_logic;
    signal PPU_add    : std_logic_vector(7 downto 0);
    signal R: std_logic_vector(7 downto 0);
    signal G: std_logic_vector(7 downto 0);
    signal B: std_logic_vector(7 downto 0);
    signal VRAM_r_nw: std_logic;
    signal VRAM_address: std_logic_vector(12 downto 0);
    signal VRAM_data: std_logic_vector(7 downto 0);
    
begin
    w_nr <= not r_nw;
    data_out <= data;
    
    P_A: entity work.CPU
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
    
    
    P_B: entity work.RAM
    port map(
        clk => clk,
        WE => w_nr,
        enable =>  std_logic'('1'),
        address => address,
        data => data        
    );
    
    P_C: entity work.PPU
    port map(
        rst             => '0',
        clk             => clk,
        CS              => CS,
        r_nw            => r_nw,         
        address         => address,      
        NMI             => NMI,          
        ALE             => ALE,          
        PPU_add         => PPU_add,      
        R               => R,      
        G               => G,
        B               => B, 
        VRAM_r_nw       => VRAM_r_nw,    
        VRAM_address    => VRAM_address, 
        VRAM_data       => VRAM_data,    
        data            => data         
    );

end Behavioral;
























