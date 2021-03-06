library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.std_logic_misc.and_reduce;
use IEEE.Std_Logic_TextIO.all;

entity NES is
    port(
        clk, rst        : in std_logic;
        controller      : in std_logic_vector(7 downto 0); -- 0-A, 1-B, 2-Select, 3-Start, 4-Up, 5-Down, 6-Left, 7-Right,
        R,G,B           : out std_logic_vector(3 downto 0);
        VGA_H,VGA_V     : out std_logic
    );
end NES;

architecture Behavioral of NES is
    signal rdy, irq, nmi, sync: std_logic;
    signal CPU_r_nw: std_logic;
    signal CPU_address: std_logic_vector(15 downto 0);
    signal CPU_data: std_logic_vector(7 downto 0);

    signal VRAM_CS, VRAM_A10, VRAM_r_nw : std_logic;
    signal VRAM_address: std_logic_vector(13 downto 0);
    signal VRAM_data: std_logic_vector(7 downto 0);
    signal vsync, hsync: std_logic;
    signal delayed_vsync, delayed_hsync: std_logic := '0';
    signal pixel_index: std_logic_vector(7 downto 0);
    signal pixel_color: std_logic_vector(23 downto 0);
    
    signal RAM_select, PPU_select, DMA_select, Cartridge_select, Controller_Logic_select: std_logic;
    
    signal clk25 : std_logic;
    signal clk50 : std_logic;
    signal clk12_5 : std_logic;
    signal clk6_25 : std_logic;
    signal index   : std_logic_vector(19 downto 0);
    signal data_vga   : std_logic_vector(11 downto 0);
begin
    RAM_select <= '1' when x"0000" <= CPU_address and CPU_address <= x"1FFF" else
                  '0';
                  
    PPU_select <= '1' when x"2000" <= CPU_address and CPU_address <= x"3FFF" else
                  '0';
                  
    DMA_select <= '1' when CPU_address = x"4014" else
                  '0';
                  
    Cartridge_select <= '1' when x"4020" <= CPU_address and CPU_address <= x"FFFF" else
                        '0';
                        
    Controller_Logic_select <= '1' when CPU_address = x"4016" or CPU_address = x"4017" else
                               '0';
    
    CPU: entity work.CPU
    port map(
        clk => clk25,
        rst => rst,
        BE => rdy,
        rdy => rdy,
        irq => irq,
        nmi => nmi,
        sync => sync,
        r_nw => CPU_r_nw,
        address => CPU_address,
        data => CPU_data
    );
    
    CPU_RAM: entity work.RAM
    generic map(
        DATA_WIDTH => 8,
        ADDRESS_WIDTH => 11,
        INITIALIZE_TYPE => 1
    )
    port map(
        clk => clk25,
        WE => not CPU_r_nw,
        CS => RAM_select,
        address => CPU_address(10 downto 0),
        data => CPU_data
    );
    
    PPU: entity work.PPU
    port map(
        clk             => clk25,
        rst             => rst,
        CS              => PPU_select,
        r_nw            => CPU_r_nw,         
        address         => CPU_address(2 downto 0),      
        nmi             => nmi,                
        hsync           => hsync,      
        vsync           => vsync,
        pixel_index     => pixel_index, 
        VRAM_r_nw       => VRAM_r_nw,    
        VRAM_address    => VRAM_address, 
        VRAM_data       => VRAM_data,    
        data            => CPU_data
    );

    PPU_Nametable: entity work.RAM
    generic map(
        DATA_WIDTH => 8,
        ADDRESS_WIDTH => 11,
        INITIALIZE_TYPE => 1
    )
    port map(
        clk     => clk25,
        WE      => not VRAM_r_nw,
        CS      => VRAM_CS,
        address => VRAM_A10 & VRAM_address(9 downto 0),
        data    => VRAM_data        
    );
    
    Color_ROM: entity work.RAM
    generic map(
        DATA_WIDTH => 24,
        ADDRESS_WIDTH => 6,
        INITIALIZE_TYPE => 2,
        INITIALIZE_FILE_INDEX => 0
    )
    port map(
        clk     => clk25,
        WE      => std_logic'('0'),
        CS      => std_logic'('1'),
        address => pixel_index(5 downto 0),
        data    => pixel_color
    );

    DMA: entity work.DMA
    port map(
        clk     => clk25,
        CS      => DMA_select,
        rdy     => rdy,
        r_nw    => CPU_r_nw,
        address => CPU_address,
        data    => CPU_data
    );
    
    Cartridge: entity work.Cartridge
    port map(
        clk             => clk25,
        rst             => rst,
        CS              => Cartridge_select,
        irq             => irq,
        CPU_r_nw        => CPU_r_nw,
        CPU_address     => CPU_address,
        PPU_r_nw        => VRAM_r_nw,
        PPU_address     => VRAM_address,
        VRAM_CS         => VRAM_CS,
        VRAM_A10        => VRAM_A10,
        CPU_data        => CPU_data,
        PPU_data        => VRAM_data
    );
    
    Controller_Logic: entity work.Controller_Logic
    port map(
        clk           => clk25,
        rst           => rst,
        CS            => Controller_Logic_select,
        controller    => controller,
        CPU_r_nw      => CPU_r_nw,
        CPU_address   => CPU_address(0),
        CPU_data      => CPU_data
    );
    
    VGA: entity work.VGA
    port map(
    clk             => clk25,
    rst             => rst,
    index           => index,
    R               => R,
    G               => G,
    B               => B,
    VGA_H           => VGA_H,
    VGA_V           => VGA_V,
    data_vga        => data_vga
    );

    VGA_RAM: entity work.VGA_RAM
    port map(
    clk             => clk6_25,
    clk_2           => clk25,
    rst             => rst,
    pixel_color     => pixel_color,
    vsync           => vsync,
    hsync           => hsync,
    index           => index,
    data_vga        => data_vga
    );


    CLK_GEN: entity work.CLK_GEN
    port map(
    clk             => clk,
    rst             => rst,
    clk50           => clk50,
    clk25           => clk25,
    clk12_5         => clk12_5,
    clk6_25         => clk6_25
    );

end Behavioral;
























