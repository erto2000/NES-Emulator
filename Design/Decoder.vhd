library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity Decoder is
    generic(
        DATA_WIDTH: integer := 8
    );
    port(
        rdy                            : in std_logic;
        irq_flag, nmi_flag, rst_flag   : in std_logic;
        irq_disable                    : in std_logic;
        instruction                    : in std_logic_vector(DATA_WIDTH-1 downto 0);
        cycle                          : in integer range 0 to 7;
        cycle_increment                : out std_logic;
        cycle_skip                     : out std_logic;
        cycle_rst                      : out std_logic;
        interrupt                      : out std_logic;
        r_nw                           : out std_logic;
       
        --CONTROL SIGNALS--
        DL_DB, DL_ADL, DL_ADH, ZERO_ADH                 : out std_logic;
        ONE_ADH, FF_ADH, ADH_ABH                        : out std_logic;
        ADL_ABL, PCL_PCL, ADL_PCL                       : out std_logic;
        I_PC, PCL_DB, PCL_ADL                           : out std_logic;
        PCH_PCH, ADH_PCH, PCH_DB, PCH_ADH               : out std_logic;
        SB_ADH, SB_DB, FA_ADL, FB_ADL, FC_ADL           : out std_logic;
        FD_ADL, FE_ADL, FF_ADL, S_ADL, ZERO_S, SB_S     : out std_logic;
        D_S, S_SB, NDB_ADD, DB_ADD, ADL_ADD, ONE_ADDC   : out std_logic;
        DAA, DSA, SUMS, ANDS, EORS                      : out std_logic;
        ORS, SRS, ADD_ADL, ADD_SB, FF_ADD               : out std_logic;
        ZERO_ADD, SB_ADD, SB_AC, DB_SB, ADH_SB          : out std_logic;
        AC_DB, AC_SB, SB_X, X_SB, SB_Y, Y_SB            : out std_logic;
        P_DB, DB0_C, ZERO_C, ONE_C, ACR_C, DB1_Z        : out std_logic;
        DBZ_Z, DB2_I, ZERO_I, ONE_I,  DB3_D             : out std_logic;
        ZERO_D, ONE_D, DB6_V, AVR_V, ONE_V, DB7_N       : out std_logic
    );
end Decoder;

architecture Behavioral of Decoder is
    --Signals determine if interrupt is processed or not
    signal irq_initiated : std_logic := '0';
    signal nmi_initiated : std_logic := '0';
    signal rst_initiated : std_logic := '1';
    
    --Same as cycle_rst
    signal cycle_reset : std_logic;

    --Instruction hex codes
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
    constant BPL_REL : T := x"00";
    constant ORA_INDY: T := x"00";
    constant ORA_ZPGX: T := x"00";
    constant ASL_ZPGX: T := x"00";
    constant CLC_IMPL: T := x"00";
    constant ORA_ABSY: T := x"00";
    constant ORA_ABSX: T := x"00";
    constant ASL_ABSX: T := x"00";
    constant JSR_ABS : T := x"00";
    constant AND_XIND: T := x"00";
    constant BIT_ZPG : T := x"00";
    constant AND_ZPG : T := x"00";
    constant ROL_ZPG : T := x"00";
    constant PLP_IMPL: T := x"00";
    constant AND_IMM : T := x"00";
    constant ROL_A   : T := x"00";
    constant BIT_ABS : T := x"00";
    constant AND_ABS : T := x"00";
    constant ROL_ABS : T := x"00";
begin
    process(rdy, irq_flag, nmi_flag, rst_flag, irq_disable, instruction, cycle, cycle_reset) begin
        --Default Output Signals
        cycle_increment <= '0';
        cycle_skip <= '0';
        cycle_reset <= '0';
        cycle_rst <= cycle_reset;
        interrupt <= '0';
        r_nw <= '1';
        
        --Default Control Signals
        DL_DB<='0'; DL_ADL<='0'; DL_ADH<='0'; ZERO_ADH<='0';
        ONE_ADH<='0'; FF_ADH<='0'; ADH_ABH<='0';
        ADL_ABL<='0'; PCL_PCL<='0'; ADL_PCL<='0';
        I_PC<='0'; PCL_DB<='0'; PCL_ADL<='0';
        PCH_PCH<='0'; ADH_PCH<='0'; PCH_DB<='0'; PCH_ADH<='0';
        SB_ADH<='0'; SB_DB<='0'; FA_ADL<='0'; FB_ADL<='0'; FC_ADL<='0';
        FD_ADL<='0'; FE_ADL<='0'; FF_ADL<='0'; S_ADL<='0'; ZERO_S<='0'; SB_S<='0'; 
        D_S<='0'; S_SB<='0'; NDB_ADD<='0'; DB_ADD<='0'; ADL_ADD<='0'; ONE_ADDC<='0';
        DAA<='0'; DSA<='0'; SUMS<='0'; ANDS<='0'; EORS<='0';
        ORS<='0'; SRS<='0'; ADD_ADL<='0'; ADD_SB<='0'; FF_ADD<='0';
        ZERO_ADD<='0'; SB_ADD<='0'; SB_AC<='0'; DB_SB<='0'; ADH_SB<='0';
        AC_DB<='0'; AC_SB<='0'; SB_X<='0'; X_SB<='0'; SB_Y<='0'; Y_SB<='0';
        P_DB<='0'; DB0_C<='0'; ZERO_C<='0'; ONE_C<='0'; ACR_C<='0'; DB1_Z<='0';
        DBZ_Z<='0'; DB2_I<='0'; ZERO_I<='0'; ONE_I<='0'; DB3_D<='0';
        ZERO_D<='0'; ONE_D<='0'; DB6_V<='0'; AVR_V<='0'; ONE_V<='0'; DB7_N<='0';
        
        --Decoder
        case instruction is               
        when x"00" =>
            case cycle is
            when 0 =>
                cycle_increment <= '1';
                DL_DB<='1';DB_ADD<='1';
                AC_SB<='1';SB_ADD<='1';
                SUMS<='1';
                PCL_PCL<='1';I_PC<='1';PCH_PCH<='1';
            
            when 1 =>
                cycle_reset<='1';
                ADD_SB<='1';SB_AC<='1';
                AVR_V <= '1'; ACR_C <='1'; DBZ_Z <='1';	DB7_N <= '1';    
                PCL_PCL<='1';I_PC<='1';PCH_PCH<='1';
                PCL_ADL<='1';PCH_ADH<='1';ADL_ABL<='1';ADH_ABH<='1';
                
            when others =>
            end case;
                 
        when others =>
        end case;

        --These are Overriding control signals decided by decoder
        if(rst_flag = '1') then
            --If rst is 1 then start reset sequence
            irq_initiated <= '0';
            nmi_initiated <= '0';
            rst_initiated <= '1';
        elsif(rdy = '0') then
            --If cpu is not ready then prevent PCL, PHL and ADD registers from change
            PCL_PCL <= '1'; PCH_PCH <= '1'; I_PC <= '0';
            SUMS <= '0'; ANDS <= '0'; EORS <= '0'; ORS <= '0'; SRS <= '0';
        elsif(cycle_reset = '1' and nmi_flag = '1') then
            --If it is the last cycle of the instruction and nmi is set start nmi sequence
            nmi_initiated <= '1';
            interrupt <= '1';
            I_PC <= '0'; 
        elsif((cycle_reset and irq_flag and not irq_disable) = '1') then
            --If it is the last cycle of the instruction and irq is set start irq sequence
            irq_initiated <= '1';
            interrupt <= '1';
            I_PC <= '0';
        end if;    
    end process;
end Behavioral;
























