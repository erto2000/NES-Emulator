library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity Interrupt_Logic is
    generic(
        DATA_WIDTH: integer := 8
    );
    port(
        rst, clk_ph2:                   in std_logic;
        irq, nmi:                       in std_logic;
        irq_clr, nmi_clr, rst_clr:      in std_logic;
        irq_disable:                    in std_logic;
        irq_flag, nmi_flag, rst_flag:   out std_logic;
        int_flag:                       out std_logic
    );
end Interrupt_Logic;

architecture Behavioral of Interrupt_Logic is
    signal irq_reg:             std_logic := '0';
    signal nmi_reg:             std_logic := '0';
    signal previous_nmi_reg:    std_logic := '1';
begin
    irq_flag <= irq_reg;
    nmi_flag <= nmi_reg;
    int_flag <= irq_reg or nmi_reg;
    
    process(clk_ph2) begin
        if(rising_edge(clk_ph2)) then
            if(rst = '1') then
                irq_reg <= '0';
                nmi_reg <= '0';
                rst_flag <= '1';
                previous_nmi_reg <= '1';
            else
                if(irq_clr = '1') then
                    irq_reg <= '0';
                elsif(irq = '0') then
                    irq_reg <= (not irq_disable);
                end if;
                
                previous_nmi_reg <= nmi;
                if(nmi_clr = '1') then
                    nmi_reg <= '0';
                elsif((previous_nmi_reg and not nmi) = '1') then
                    nmi_reg <= '1';
                end if;
                
                if(rst_clr = '1') then
                    rst_flag <= '0';
                end if;
            end if;
        end if;
    end process;
end Behavioral;
























