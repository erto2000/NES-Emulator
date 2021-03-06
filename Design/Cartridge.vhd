library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity Cartridge is
    generic(
        DATA_WIDTH: integer := 8
    );
    port(
        rst, clk, CS    : in std_logic;
        CPU_r_nw        : in std_logic;
        CPU_address     : in std_logic_vector(DATA_WIDTH*2-1 downto 0);
        PPU_r_nw        : in std_logic;
        PPU_address     : in std_logic_vector(13 downto 0);
        VRAM_CS         : out std_logic;
        VRAM_A10        : out std_logic;
        irq             : out std_logic;
        CPU_data        : inout std_logic_vector(DATA_WIDTH-1 downto 0);
        PPU_data        : inout std_logic_vector(7 downto 0)
    );
end Cartridge;

architecture Behavioral of Cartridge is
    signal VRAM_Size : integer := 2;
begin
    VRAM_CS <= PPU_address(13);
    VRAM_A10 <= '0'; --PPU_address(10); -- Based on file
    irq <= '1';

    PRG_memory: entity work.RAM
    generic map(
        DATA_WIDTH => 8,
        ADDRESS_WIDTH => 14,
        INITIALIZE_TYPE => 2,
        INITIALIZE_FILE_INDEX => 1
    )
    port map(
        clk => clk,
        WE => not CPU_r_nw,
        CS => CPU_address(15) and CS,
        address => CPU_address(13 downto 0),
        data => CPU_data
    );
    
    CHR_memory: entity work.RAM
    generic map(
        DATA_WIDTH => 8,
        ADDRESS_WIDTH => 13,
        INITIALIZE_TYPE => 2,
        INITIALIZE_FILE_INDEX => 2
    )
    port map(
        clk => clk,
        WE => not PPU_r_nw,
        CS => not PPU_address(13),
        address => PPU_address(12 downto 0),
        data => PPU_data
    );

end Behavioral;
























