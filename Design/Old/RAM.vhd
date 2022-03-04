package RAM_PACKAGE is
    type INITIALIZE_TYPE is (NONE, INLINE, EXTERNAL); -- NONE->not initialized, INLINE->give data in parameter, EXTERNAL->give data in file
end package;

library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.RAM_PACKAGE.all;
use std.textio.all;

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

    impure function init_ram_with_file(file_name : string := "") return ram_type is
        file ram_file : text open read_mode is file_name;
        variable ram_file_line : line;
        variable ram	: ram_type;
        variable value : character;
        variable i : integer range 0 to 2**ADDRESS_WIDTH-1 := 0;
    begin
        for i in ram_type'range loop
            readline(ram_file, ram_file_line);
            read(ram_file_line, ram(i));
        end loop; 
        return ram;
    end function;
        
    impure function init_ram(init : INITIALIZE_TYPE := NONE; data : ram_type := (others => (others => '0')); file_name : string := "") return ram_type is
    begin
        if(init = NONE) then
            return (others => (others => 'U'));
        elsif(init = INLINE) then
            return data;
        elsif(init = EXTERNAL) then
            return init_ram_with_file(file_name);
        end if;
    end function;
    
    signal ram : ram_type := init_ram(EXTERNAL, file_name=>"ram_converted.bin"); 
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
















