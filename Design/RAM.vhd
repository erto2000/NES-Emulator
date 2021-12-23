library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RAM is
    generic(
        DATA_WIDTH: integer := 8;
        ADDRESS_WIDTH: integer := 16
    );
    port ( 
        clk        : in std_logic;
        WE         : in std_logic;
        enable     : in std_logic;
        address    : in std_logic_vector(ADDRESS_WIDTH-1 downto 0);
        data       : inout std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end RAM;

architecture Behavioral of RAM is
    type ram_type is array (0 to 2**ADDRESS_WIDTH-1) of std_logic_vector (DATA_WIDTH-1 downto 0);
    signal ram : ram_type := (x"01", x"01", others => (others => '0'));
    
    signal output: std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
begin
    process(clk)
    begin
        if(rising_edge(clk)) then
            if(enable = '1' and WE = '1') then
                ram(to_integer(unsigned(address))) <= data;
            end if;
            
            output <= ram(to_integer(unsigned(address)));
        end if;
    end process;
    
    data <= output when (enable and not WE) = '1' else
            (others => 'Z'); 

end Behavioral;
















