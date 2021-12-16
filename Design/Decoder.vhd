library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity Decoder is
    generic(
        DATA_WIDTH: integer := 8
    );
    port(
        rdy:                            in std_logic;
        irq_flag, nmi_flag, rst_flag:   in std_logic;
        IR:                             in std_logic_vector(DATA_WIDTH-1 downto 0);
        cycle:                          in integer range 0 to 7;
        cycle_increment:                out std_logic;
        cycle_reset:                    out std_logic;
        cycle_skip:                     out std_logic;
        r_nw:                           out std_logic
        --Other signals
    );
end Decoder;

architecture Behavioral of Decoder is
    subtype T is std_logic_vector(DATA_WIDTH-1 downto 0);
    constant BRK_IMPL: T := x"00";
    constant ORA_XIND: T := x"01";
    constant ORA_ZPG : T := x"05";
    constant ASL_ZPG : T := x"06";
    constant PHP_IMPL: T := x"08";
    constant ORA_IMM : T := x"09";
    constant ASL_A   : T := x"0A";
    constant ORA_ABS : T := x"0D";
    constant ASL_ABS : T := x"0E";
    constant BPL_REL : T := x"";
    constant ORA_INDY: T := x"";
    constant ORA_ZPGX: T := x"";
    constant ASL_ZPGX: T := x"";
    constant CLC_IMPL: T := x"";
    constant ORA_ABSY: T := x"";
    constant ORA_ABSX: T := x"";
    constant ASL_ABSX: T := x"";
    constant JSR_ABS : T := x"";
    constant AND_XIND: T := x"";
    constant BIT_ZPG : T := x"";
    constant AND_ZPG : T := x"";
    constant ROL_ZPG : T := x"";
    constant PLP_IMPL: T := x"";
    constant AND_IMM : T := x"";
    constant ROL_A   : T := x"";
    constant BIT_ABS : T := x"";
    constant AND_ABS : T := x"";
    constant ROL_ABS : T := x"";
begin
    process(rdy, irq_flag, nmi_flag, rst_flag, IR, cycle) begin
            if(rdy = '0') then
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
    end process;
end Behavioral;
























