library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.std_logic_misc.and_reduce;
use IEEE.Std_Logic_TextIO.all;

entity top is
    port(
        clk, rst, irq : in std_logic;    
        data_out: out std_logic_vector(7 downto 0);
        hsync, vsync, sync : out std_logic;
        pixel_index : out std_logic_vector(7 downto 0)
    );
end top;

architecture Behavioral of top is
    signal rdy_signal: std_logic;
    signal r_nw: std_logic;
    signal address: std_logic_vector(15 downto 0);
    signal NMI : std_logic;
    signal data: std_logic_vector(7 downto 0);

    signal ALE : std_logic;
    signal PPU_add    : std_logic_vector(7 downto 0);
    signal VRAM_r_nw: std_logic;
    signal VRAM_address: std_logic_vector(13 downto 0);
    signal VRAM_data: std_logic_vector(7 downto 0);
    
    signal RAM_select: std_logic;
    signal PPU_select: std_logic;
    signal DMA_select: std_logic;
begin
    RAM_select <= '1' when (x"0000" <= address and address < x"2000") or (x"4020" <= address or address < x"FFF") else
                  '0';
    PPU_select <= '1' when x"2000" <= address and address < 4000 else
                  '0';
    DMA_select <= '1' when address = x"4014" else
                  '0';

    CPU: entity work.CPU
    port map(
        rst => rst,
        clk => clk,
        BE => rdy_signal,
        rdy => rdy_signal,
        irq => irq,
        nmi => NMI,
        sync => sync,
        r_nw => r_nw,
        address => address,
        data => data
    );
    
    CPU_memory: entity work.RAM
    generic map(
        ADDRESS_WIDTH => 16
    )
    port map(
        clk => clk,
        WE => not r_nw,
        CS => RAM_select,
        address => address,
        data => data
    );
    
    PPU: entity work.PPU
    port map(
        rst             => rst,
        clk             => clk,
        CS              => PPU_select,
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
    
    PPU_memory: entity work.RAM
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

    DMA: entity work.DMA
    port map(
        clk => clk,
        CS => DMA_select,
        rdy => rdy_signal,
        r_nw => r_nw,
        address => address,
        data => data
    );

end Behavioral;
























