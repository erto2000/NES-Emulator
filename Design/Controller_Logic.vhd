library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity Controller_Logic is
    generic(
        DATA_WIDTH: integer := 8
    );
    port(
        clk, rst        : in std_logic;
        CS              : in std_logic;
        controller      : in std_logic_vector(DATA_WIDTH-1 downto 0);
        CPU_r_nw        : in std_logic;
        CPU_address     : in std_logic;
        CPU_data        : inout std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end Controller_Logic;

architecture Behavioral of Controller_Logic is
    signal clk_counter         : integer range 0 to 11 := 0; -- Master clock tick
    signal shift_strobe        : std_logic := '0'; -- Register for selecting controller mode
    signal controller_register : std_logic_vector(7 downto 0) := (others => '0');
    signal CPU_data_out        : std_logic_vector(7 downto 0) := (others => '0');
begin
    CPU_data <= CPU_data_out when CS = '1' and CPU_r_nw = '1' else
                (others => 'Z');

    process(clk) begin
        if(rising_edge(clk)) then
            if(rst = '1') then
                clk_counter <= 0;
                shift_strobe <= '0';
                controller_register <= (others => '0');
                CPU_data_out <= (others => '0');
            else
                clk_counter <= 0 when clk_counter = 11 else
                               clk_counter + 1;
                
                shift_strobe <= CPU_data(0) when CS = '1' and CPU_r_nw = '0' and CPU_address = '0';
                
                controller_register <= controller when shift_strobe = '1' else
                                       '1' & controller_register(7 downto 1) when clk_counter = 0 and CS = '1' and CPU_r_nw = '1' and shift_strobe = '0' and (CPU_address = '0' or CPU_address = '1');
                                       
                CPU_data_out <= "0000000" & controller_register(0) when clk_counter = 0 and CS = '1' and CPU_r_nw = '1' and shift_strobe = '0' and CPU_address = '0';
                CPU_data_out <= "00000000" when clk_counter = 0 and CS = '1' and CPU_r_nw = '1' and shift_strobe = '0' and CPU_address = '1';
            end if;
        end if;
    end process;

end Behavioral;
























