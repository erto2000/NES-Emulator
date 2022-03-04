library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.std_logic_misc.or_reduce;

entity PPU is
    generic(
        DATA_WIDTH: integer := 8
    );
    port(
        rst, clk        : in std_logic;
        CS              : in std_logic;
        r_nw            : in std_logic;
        address         : in std_logic_vector(2 downto 0);
        NMI             : out std_logic;
        ALE             : out std_logic;
        PPU_add         : out std_logic_vector(2 downto 0);
        R,G,B           : out std_logic_vector(7 downto 0);
        VRAM_r_nw       : out std_logic;
        VRAM_address    : out std_logic_vector(12 downto 0);
        VRAM_data       : inout std_logic_vector(7 downto 0);
        data            : inout std_logic_vector(DATA_WIDTH-1 downto 0) 
    );
end PPU;

architecture Behavioral of PPU is

begin   

end Behavioral;