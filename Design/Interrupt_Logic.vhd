library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity Interrupt_Logic is
    generic(
        DATA_WIDTH: integer := 8
    );
    port(
        rst, clk_ph2:               in std_logic;
        irq, nmi:                   in std_logic;
        irq_clr, nmi_clr:           in std_logic;
        irq_disable:                in std_logic;
        irq_out, nmi_out:           out std_logic;
        int_out:                    out std_logic
    );
end Interrupt_Logic;

architecture Behavioral of Interrupt_Logic is
    signal previous_nmi:    std_logic := '1';
    signal irq_signal:      std_logic := '0';
    signal nmi_signal:      std_logic := '0';
begin
    irq_out <= irq_signal;
    nmi_out <= nmi_signal;
    int_out <= irq_signal or nmi_signal;
    
    process(clk_ph2) begin
        if(rising_edge(clk_ph2)) then
            if(rst = '1') then
                irq_signal <= '0';
                nmi_signal <= '0';
                previous_nmi <= '1';
            else
                if(irq_clr = '1') then
                    irq_signal <= '0';
                elsif(irq = '0') then
                    irq_signal <= (not irq_disable);
                end if;
                
                previous_nmi <= nmi;
                if(nmi_clr = '1') then
                    nmi_signal <= '0';
                elsif((previous_nmi and not nmi) = '1') then
                    nmi_signal <= '1';
                end if;
            end if;
        end if;
    end process;
end Behavioral;
























