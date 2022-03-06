library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.std_logic_misc.or_reduce;

entity PPU is
    port(
        rst, clk        : in std_logic;
        CS              : in std_logic;
        r_nw            : in std_logic;
        address         : in std_logic_vector(2 downto 0);
        NMI             : out std_logic;
        ALE             : out std_logic;
        R,G,B           : out std_logic_vector(7 downto 0);
        VRAM_r_nw       : out std_logic;
        VRAM_address    : out std_logic_vector(12 downto 0);
        VRAM_data       : inout std_logic_vector(7 downto 0);
        data            : inout std_logic_vector(7 downto 0) 
    );
end PPU;

architecture Behavioral of PPU is
    -- CPU interface signals
    signal PPUCTRL, PPUMASK, PPUSTATUS, OAMADDR, OAMDATA, PPUSCROLL, PPUADDR, PPUDATA : std_logic_vector(7 downto 0);
    
    -- Internal registers
    signal v : std_logic_vector(14 downto 0); -- Current VRAM address
    signal t : std_logic_vector(14 downto 0); -- Temporary VRAM address
    signal x : std_logic_vector(2 downto 0);  -- Fine X scroll
    signal w : std_logic; -- First or second write toggle
begin   

    process(clk) begin
        if(rising_edge(clk)) then 
            case address is
                when "000" =>
                    PPUCTRL <= data;
                when "001" =>
                    PPUMASK <= data;
                when "010" =>
                    PPUSTATUS <= data;
                when "011" =>
                    OAMADDR <= data;
                when "100" =>
                    OAMDATA <= data;
                when "101" =>
                    PPUSCROLL <= data;
                when "110" =>
                    PPUADDR <= data;
                when "111" =>
                    PPUDATA <= data;
                when others =>
            end case;
        end if;        
    end process;

end Behavioral;





















