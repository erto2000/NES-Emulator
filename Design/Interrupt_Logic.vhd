library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity Interrupt_Logic is
    generic(
        DATA_WIDTH: integer := 8
    );
    port(
        rst, clk_ph1                   : in std_logic;
        irq, nmi                       : in std_logic;
        irq_flag, nmi_flag, rst_flag   : out std_logic := '0'
    );
end Interrupt_Logic;

architecture Behavioral of Interrupt_Logic is
    signal previous_nmi_reg: std_logic := '1';
begin
    --Detect interrupt signals
    process(clk_ph1) begin
        if(rising_edge(clk_ph1)) then
            if(rst = '1') then
                irq_flag <= '0';
                nmi_flag <= '0';
                rst_flag <= '1'; --If rst is 1 start reset sequence on clk_ph1
                previous_nmi_reg <= '1';
            else
                --Detect when irq signal is 0
                if(irq = '0') then
                    irq_flag <= '1';
                end if;
                
                --Detect when nmi signal goes from 1 to 0(sampled on clk_ph1)
                previous_nmi_reg <= nmi;
                if((previous_nmi_reg and not nmi) = '1') then
                    nmi_flag <= '1';
                end if;
                
                rst_flag <= '0';
            end if;
        end if;
    end process;
end Behavioral;
























