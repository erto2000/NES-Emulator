library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity Decoder is
    generic(
        DATA_WIDTH: integer := 8
    );
    port(
        rst, clk_ph2:       in std_logic;
        rdy:                in std_logic;
        irq_flag, nmi_flag: in std_logic;
        sv:                 in std_logic;
        IR:                 in std_logic_vector(DATA_WIDTH-1 downto 0);
        cycle:              in integer range 0 to 7;
        cycle_increment:    out std_logic;
        cycle_reset:        out std_logic;
        r_nw:               out std_logic
        --Other signals
    );
end Decoder;

architecture Behavioral of Decoder is
begin
    process(clk_ph2) begin
        if(rising_edge(clk_ph2)) then
            if(rst = '1') then
                --reset state
            elsif(rdy = '0') then
                --No change state
            else
                case IR is               
                when x"00" =>
                    case cycle is
                    when 0 =>
                        --add<=1; adl<=1;     
                    when 1 =>
                        --add<=1; adl<=1;
                    when others =>
                        --add<=1; adl<=1;
                    end case;
                    
                when x"01" =>
                    case cycle is
                    when 0 =>
                        --add<=1; adl<=1;     
                    when 1 =>
                        --add<=1; adl<=1;
                    when others =>
                        --add<=1; adl<=1;
                    end case;
                    
                when others =>
                    case cycle is
                    when 0 =>
                        --add<=1; adl<=1;     
                    when 1 =>
                        --add<=1; adl<=1;
                    when others =>
                        --add<=1; adl<=1;
                    end case;
                end case;
            end if;
        end if;
    end process;
end Behavioral;
























