library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.std_logic_misc.and_reduce;

entity top is
    port(
        clk, rst, rdy : in std_logic;    
        data_out: out std_logic_vector(7 downto 0);
        irq: out std_logic;
        BE: in std_logic;
        hsync, vsync, sync : out std_logic;
        pixel_index : out std_logic_vector(7 downto 0)
    );
end top;

architecture Behavioral of top is
    signal r_nw: std_logic;
    signal address: std_logic_vector(15 downto 0);
    signal NMI : std_logic;
    signal data: std_logic_vector(7 downto 0);

    signal ALE : std_logic;
    signal PPU_add    : std_logic_vector(7 downto 0);
    signal VRAM_r_nw: std_logic;
    signal VRAM_address: std_logic_vector(13 downto 0);
    signal VRAM_data: std_logic_vector(7 downto 0);
    
begin
    P_A: entity work.CPU
    port map(
        rst => rst,
        clk => clk,
        BE => BE,
        rdy =>  rdy,
        irq => irq,
        nmi => NMI,
        sync => sync,
        r_nw => r_nw,
        address => address,
        data => data
    );
    
    
    P_B: entity work.RAM
    port map(
        clk => clk,
        WE => not r_nw,
        CS =>  std_logic'('1'),
        address => address,
        data => data        
    );
    
    P_C: entity work.PPU
    port map(
        rst             => rst,
        clk             => clk,
        CS              => address(13),
        r_nw            => r_nw,         
        address         => address(2 downto 0),      
        NMI             => NMI,                
        hsync           => hsync,      
        vsync           => vsync,
        pixel_index     => pixel_index, 
        VRAM_r_nw       => VRAM_r_nw,    
        VRAM_address    => VRAM_address, 
        VRAM_data       => VRAM_data,    
        data            => data
    );
    
    ppu_memory: entity work.RAM
    generic map(
        ADDRESS_WIDTH => 14
    )
    port map(
        clk     => clk,
        WE      => not VRAM_r_nw,
        CS      => std_logic'('1'),
        address => VRAM_address(13 downto 0),
        data    => VRAM_data        
    );


end Behavioral;
























