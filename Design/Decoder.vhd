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
        nmi_flag_clr                   : out std_logic;
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
        ORS, SRS, ADD_ADL, ADD_ADH, ADD_SB, FF_ADD      : out std_logic;
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
    constant BRK_IMPL : T := x"00";
    constant ORA_XIND : T := x"01";
    constant ORA_ZPG  : T := x"05";
    constant ASL_ZPG  : T := x"06";
    constant PHP_IMPL : T := x"08";
    constant ORA_IMM  : T := x"09";
    constant ASL_A    : T := x"0A";
    constant ORA_ABS  : T := x"0D";
    constant ASL_ABS  : T := x"0E";
    constant BPL_REL  : T := x"10";
    constant ORA_INDY : T := x"11";
    constant ORA_ZPGX : T := x"15";
    constant ASL_ZPGX : T := x"16";
    constant CLC_IMPL : T := x"18";
    constant ORA_ABSY : T := x"19";
    constant ORA_ABSX : T := x"1D";
    constant ASL_ABSX : T := x"1E";
    constant JSR_ABS  : T := x"20";
    constant AND_XIND : T := x"21";
    constant BIT_ZPG  : T := x"24";
    constant AND_ZPG  : T := x"25";
    constant ROL_ZPG  : T := x"26";
    constant PLP_IMPL : T := x"28";
    constant AND_IMM  : T := x"29";
    constant ROL_A    : T := x"2A";
    constant BIT_ABS  : T := x"2C";
    constant AND_ABS  : T := x"2D";
    constant ROL_ABS  : T := x"2E";
    constant BMI_REL  : T := x"30";
    constant AND_INDY : T := x"31";
    constant AND_ZPGX : T := x"35";
    constant ROL_ZPGX : T := x"36";
    constant SEC_IMPL : T := x"38";
    constant AND_ABSY : T := x"39";
    constant AND_ABSX : T := x"3D";
    constant ROL_ABSX : T := x"3E";
    constant RTI_IMPL : T := x"40";
    constant EOR_XIND : T := x"41";
    constant EOR_ZPG  : T := x"45";
    constant LSR_ZPG  : T := x"46";
    constant PHA_IMPL : T := x"48";
    constant EOR_IMM  : T := x"49";
    constant LSR_A    : T := x"4A";
    constant JMP_ABS  : T := x"4C";
    constant EOR_ABS  : T := x"4D";
    constant LSR_ABS  : T := x"4E";
    constant BVC_REL  : T := x"50";
    constant EOR_INDY : T := x"51";
    constant EOR_ZPGX : T := x"55";
    constant LSR_ZPGX : T := x"56";
    constant CLI_IMPL : T := x"58";
    constant EOR_ABSY : T := x"59";
    constant EOR_ABSX : T := x"5D";
    constant LSR_ABSX : T := x"5E";
    constant RTS_IMPL : T := x"60";
    constant ADC_XIND : T := x"61";
    constant ADC_ZPG  : T := x"65";
    constant ROR_ZPG  : T := x"66";
    constant PLA_IMPL : T := x"68";
    constant ADC_IMM  : T := x"69";
    constant ROR_A    : T := x"6A";
    constant JMP_IND  : T := x"6C";
    constant ADC_ABS  : T := x"6D";
    constant ROR_ABS  : T := x"6E";
    constant BVS_REL  : T := x"70";
    constant ADC_INDY : T := x"71";
    constant ADC_ZPGX : T := x"75";
    constant ROR_ZPGX : T := x"76";
    constant SEI_IMPL : T := x"78";
    constant ADC_ABSY : T := x"79";
    constant ADC_ABSX : T := x"7D";
    constant ROR_ABSX : T := x"7E";
    constant STA_XIND : T := x"81";
    constant STY_ZPG  : T := x"84";
    constant STA_ZPG  : T := x"85";
    constant STX_ZPG  : T := x"86";
    constant DEY_IMPL : T := x"88";
    constant TXA_IMPL : T := x"8A";
    constant STY_ABS  : T := x"8C";
    constant STA_ABS  : T := x"8D";
    constant STX_ABS  : T := x"8E";
    constant BCC_REL  : T := x"90";
    constant STA_INDY : T := x"91";
    constant STY_ZPGX : T := x"94";
    constant STA_ZPGX : T := x"95";
    constant STX_ZPGY : T := x"96";
    constant TYA_IMPL : T := x"98";
    constant STA_ABSY : T := x"99";
    constant TXS_IMPL : T := x"9A";
    constant STA_ABSX : T := x"9D";
    constant LDY_IMM  : T := x"A0";
    constant LDA_XIND : T := x"A1";
    constant LDX_IMM  : T := x"A2";
    constant LDY_ZPG  : T := x"A4";
    constant LDA_ZPG  : T := x"A5";
    constant LDX_ZPG  : T := x"A6";
    constant TAY_IMPL : T := x"A8";
    constant LDA_IMM  : T := x"A9";
    constant TAX_IMPL : T := x"AA";
    constant LDY_ABS  : T := x"AC";
    constant LDA_ABS  : T := x"AD";
    constant LDX_ABS  : T := x"AE";
    constant BCS_REL  : T := x"B0";
    constant LDA_INDY : T := x"B1";
    constant LDY_ZPGX : T := x"B4";
    constant LDA_ZPGX : T := x"B5";
    constant LDX_ZPGY : T := x"B6";
    constant CLV_IMPL : T := x"B8";
    constant LDA_ABSY : T := x"B9";
    constant TSX_IMPL : T := x"BA";
    constant LDY_ABSX : T := x"BC";
    constant LDA_ABSX : T := x"BD";
    constant LDX_ABSY : T := x"BE";
    constant CPY_IMM  : T := x"C0";
    constant CMP_XIND : T := x"C1";
    constant CPY_ZPG  : T := x"C4";
    constant CMP_ZPG  : T := x"C5";
    constant DEC_ZPG  : T := x"C6";
    constant INY_IMPL : T := x"C8";
    constant CMP_IMM  : T := x"C9";
    constant DEX_IMPL : T := x"CA";
    constant CPY_ABS  : T := x"CC";
    constant CMP_ABS  : T := x"CD";
    constant DEC_ABS  : T := x"CE";
    constant BNE_REL  : T := x"D0";
    constant CMP_INDY : T := x"D1";
    constant CMP_ZPGX : T := x"D5";
    constant DEC_ZPGX : T := x"D6";
    constant CLD_IMPL : T := x"D8";
    constant CMP_ABSY : T := x"D9";
    constant CMP_ABSX : T := x"DD";
    constant DEC_ABSX : T := x"DE";
    constant CPX_IMM  : T := x"E0";
    constant SBC_XIND : T := x"E1";
    constant CPX_ZPG  : T := x"E4";
    constant SBC_ZPG  : T := x"E5";
    constant INC_ZPG  : T := x"E6";
    constant INX_IMPL : T := x"E8";
    constant SBC_IMM  : T := x"E9";
    constant NOP_IMPL : T := x"EA";
    constant CPX_ABS  : T := x"EC";
    constant SBC_ABS  : T := x"ED";
    constant INC_ABS  : T := x"EE";
    constant BEQ_REL  : T := x"F0";
    constant SBC_INDY : T := x"F1";
    constant SBC_ZPGX : T := x"F5";
    constant INC_ZPGX : T := x"F6";
    constant SED_IMPL : T := x"F8";
    constant SBC_ABSY : T := x"F9";
    constant SBC_ABSX : T := x"FD";
    constant INC_ABSX : T := x"FE";
begin
    process(rdy, irq_flag, nmi_flag, rst_flag, irq_disable, instruction, cycle, cycle_reset) begin
        --Default Output Signals
        cycle_increment <= '0';
        cycle_skip <= '0';
        cycle_reset <= '0';
        cycle_rst <= cycle_reset;
        interrupt <= '0';
        nmi_flag_clr <= '0';
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
        ORS<='0'; SRS<='0'; ADD_ADL<='0'; ADD_ADH<='0'; ADD_SB<='0'; FF_ADD<='0';
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
                    when 1 =>     
                    when others =>
                end case;     

            when ADC_IMM =>
                case cycle is
                    when 0 =>
                        cycle_increment <= '1';
                        PCL_ADL<='1'; ADL_ABL<='1'; PCH_ADH<='1'; ADH_ABH<='1';     -- Send PC to Addressbus
                        PCL_PCL<='1'; I_PC<='1'; PCH_PCH<='1';                      -- Increment PC      
                        DL_DB<='1'; DB_ADD<='1'; AC_SB<='1'; SB_ADD<='1';           -- Send Data Latch and Accumulator to ALU
                        SUMS<='1';                                                  -- Activate ALU Sum
                        ACR_C<='1'; AVR_V<='1';                                     -- Set C and V flags
                        
                    when 1 =>
                        cycle_reset <= '1';                                         
                        PCL_ADL<='1'; ADL_ABL<='1'; PCH_ADH<='1'; ADH_ABH<='1';     -- Send PC to Addressbus
                        PCL_PCL<='1'; I_PC<='1'; PCH_PCH<='1';                      -- Increment PC
                        ADD_SB<='1'; SB_AC<='1';                                    -- Send Add Register to Accumulator
                        AC_DB<='1'; DBZ_Z<='1'; DB7_N<='1';                         -- Set Z and N flag  
                           
                    when others =>
                end case;  
                
            when ADC_ZPG =>
                case cycle is
                    when 0 =>
                        cycle_increment <= '1';      
                        PCL_ADL<='1'; ADL_ABL<='1'; PCH_ADH<='1'; ADH_ABH<='1';     -- Send PC to Addressbus
                        PCL_PCL<='1'; I_PC<='1'; PCH_PCH<='1';                      -- Increment PC 
                        
                    when 1 =>
                        cycle_increment <= '1'; 
                        DL_ADL <= '1'; ZERO_ADH <= '1'; ADL_ABL<='1'; ADH_ABH<='1'; -- send data latch to low address bus, write h'00' to address bus
                        DL_DB<='1'; DB_ADD<='1'; AC_SB<='1'; SB_ADD<='1';           -- Send Data Latch and Accumulator to ALU
                        SUMS<='1';                                                  -- Activate ALU Sum
                        ACR_C<='1'; AVR_V<='1';                                     -- Set C and V flags
                        
                    when 2 =>
                        cycle_reset <= '1';
                        PCL_ADL<='1'; ADL_ABL<='1'; PCH_ADH<='1'; ADH_ABH<='1';     -- Send PC to Addressbus
                        PCL_PCL<='1'; I_PC<='1'; PCH_PCH<='1';                      -- Increment PC 
                        ADD_SB<='1'; SB_AC<='1';                                    -- Send Add Register to Accumulator
                        AC_DB<='1'; DBZ_Z<='1'; DB7_N<='1';                         -- Set Z and N flag  
                    when others =>
                end case;   
                         
            when ADC_ZPGX =>
                case cycle is
                    when 0 =>
                        cycle_increment <= '1';
                        PCL_ADL<='1'; ADL_ABL<='1'; PCH_ADH<='1'; ADH_ABH<='1';     -- Send PC to Addressbus
                        PCL_PCL<='1'; I_PC<='1'; PCH_PCH<='1';                      -- Increment PC      
                        DL_DB<='1'; DB_ADD<='1'; X_SB<='1'; SB_ADD<='1';            -- Send Data Latch and X Register to ALU
                        SUMS<='1';                                                  -- Activate ALU Sum
                        
                    when 1 =>
                        cycle_increment <= '1';
                        ADD_ADL <= '1'; ADL_ABL <= '1'; ZERO_ADH <= '1'; ADH_ABH <= '1'; --Send Add register to low address bus, send zero to high address bus     
                        DL_DB<='1'; DB_ADD<='1'; AC_SB<='1'; SB_ADD<='1';           -- Send Data Latch and Accumulator to ALU
                        SUMS<='1';                                                  -- Activate ALU Sum
                        ACR_C<='1'; AVR_V<='1';                                     -- Set C and V flags
                        
                    when 2 =>
                        cycle_increment <= '1';
                        ADD_SB<='1'; SB_AC<='1';                                    -- Send Add Register to Accumulator
                        AC_DB<='1'; DBZ_Z<='1'; DB7_N<='1';                         -- Set Z and N flag  
                        
                    when 3 =>
                        cycle_reset <= '1';
                        PCL_ADL<='1'; ADL_ABL<='1'; PCH_ADH<='1'; ADH_ABH<='1';     -- Send PC to Addressbus
                        PCL_PCL<='1'; I_PC<='1'; PCH_PCH<='1';                      -- Increment PC 
                        
                    when others =>       
                end case;   
                
            when ADC_ABS =>
                case cycle is
                    when 0 =>
                        cycle_increment <= '1';    
                        PCL_ADL<='1'; ADL_ABL<='1'; PCH_ADH<='1'; ADH_ABH<='1';     -- Send PC to Addressbus
                        PCL_PCL<='1'; I_PC<='1'; PCH_PCH<='1';                      -- Increment PC  
                        DL_DB<='1'; DB_ADD<='1'; ZERO_ADD <='1';                    -- Send Data Latch and 0 to ALU
                        SUMS<='1';                                                  -- Activate ALU Sum
                        
                    when 1 =>   
                        cycle_increment <= '1'; 
                        PCL_ADL<='1'; ADL_ABL<='1'; PCH_ADH<='1'; ADH_ABH<='1';     -- Send PC to Addressbus
                        PCL_PCL<='1'; I_PC<='1'; PCH_PCH<='1';                      -- Increment PC  
                         
                    when 2 =>   
                        cycle_increment <= '1';  
                        ADD_ADL <= '1'; ADL_ABL <= '1'; DL_ADH <= '1'; ADH_ABH <= '1'; --Send Add register to low address bus, send data latch to high address bus
                        DL_DB<='1'; DB_ADD<='1'; AC_SB<='1'; SB_ADD<='1';           -- Send Data Latch and Accumulator to ALU
                        SUMS<='1';                                                  -- Activate ALU Sum
                        ACR_C<='1'; AVR_V<='1';                                     -- Set C and V flags                                              --
                        
                    when 3 =>     
                        cycle_reset <= '1';
                        PCL_ADL<='1'; ADL_ABL<='1'; PCH_ADH<='1'; ADH_ABH<='1';     -- Send PC to Addressbus
                        PCL_PCL<='1'; I_PC<='1'; PCH_PCH<='1';                      -- Increment PC
                        ADD_SB<='1'; SB_AC<='1';                                    -- Send Add Register to Accumulator
                        AC_DB<='1'; DBZ_Z<='1'; DB7_N<='1';                         -- Set Z and N flag     
                        
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
            cycle_increment <= '0'; cycle_reset <= '0'; cycle_skip <= '0';
            PCL_PCL <= '1'; PCH_PCH <= '1'; ADL_PCL <= '0'; ADH_PCH <= '0'; I_PC <= '0';
            SUMS <= '0'; ANDS <= '0'; EORS <= '0'; ORS <= '0'; SRS <= '0';
        elsif(cycle_reset = '1' and nmi_flag = '1') then
            --If it is the last cycle of the instruction and nmi is set start nmi sequence and clear flag
            nmi_flag_clr <= '0';
            nmi_initiated <= '1';
            interrupt <= '1';
            --Prevent PC increment in order to make return address right
            I_PC <= '0';
        elsif((cycle_reset and irq_flag and not irq_disable) = '1') then
            --If it is the last cycle of the instruction and irq is set start irq sequence
            irq_initiated <= '1';
            interrupt <= '1';
            --Prevent PC increment in order to make return address right
            I_PC <= '0';
        end if;    
    end process;
end Behavioral;






