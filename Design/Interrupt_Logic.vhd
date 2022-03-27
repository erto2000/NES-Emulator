library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity Interrupt_Logic is
    generic(
        DATA_WIDTH: integer := 8
    );
    port(
        rst, clk                       : in std_logic;
        clk_counter                    : in integer;
        irq, nmi                       : in std_logic;
        irq_disable                    : in std_logic;
        nmi_flag_clr                   : in std_logic;
        irq_flag, nmi_flag             : out std_logic := '0'
    );
end Interrupt_Logic;

architecture Behavioral of Interrupt_Logic is
    signal previous_nmi_reg : std_logic := '1';
begin
    --Detect interrupt signals
    process(clk) begin
        if(rising_edge(clk) and clk_counter = 11) then --rising edge ph1
            if(rst = '1') then
                irq_flag <= '0';
                nmi_flag <= '0';
                previous_nmi_reg <= '1';
            else
                --Detect when irq signal is 0
                if(irq = '0' and irq_disable = '0') then
                    irq_flag <= '1';
                else
                    irq_flag <= '0';
                end if;
                
                --Detect when nmi signal goes from 1 to 0(sampled on clk_ph1)
                previous_nmi_reg <= nmi;
                if((previous_nmi_reg and not nmi) = '1') then
                    nmi_flag <= '1';
                elsif(nmi_flag_clr = '1') then
                    nmi_flag <= '0';
                end if;
            end if;
        end if;
    end process;
end Behavioral;
























