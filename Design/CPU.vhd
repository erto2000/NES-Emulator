library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.std_logic_misc.or_reduce;


entity CPU is
    generic(
        DATA_WIDTH: integer := 8
    );
    port(
        rst, clk:   in std_logic;
        BE, rdy:    in std_logic;
        irq, nmi:   in std_logic;
        sync:       out std_logic;
        r_nw:       out std_logic;
        address:    out std_logic_vector(DATA_WIDTH*2-1 downto 0);
        data:       inout std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end CPU;

architecture Behavioral of CPU is
    signal PD, DL, DOR, ABL, ABH:                 std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    signal PCL, PCH, S, AI, BI, ADD, X, Y, AC, P: std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    signal DB, SB, ADL, ADH:                      std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    
    signal clk_ph1, clk_ph2:                      std_logic;
    signal rdy_signal:                            std_logic := '1';
    signal r_nw_signal:                           std_logic;
    
    --PC_Logic signals--
    signal PCL_Logic_Output, PCH_Logic_Output:    std_logic_vector(DATA_WIDTH-1 downto 0);
    
    --ALU signals--
    signal ALU_OUT:                               std_logic_vector(DATA_WIDTH-1 downto 0);
    signal AVR, ACR:                              std_logic;
    
    --Timing_Logic signals--
    signal int_flag:         std_logic;
    signal brk_clr:          std_logic;  
    signal cycle_increment:  std_logic;
    signal cycle_reset:      std_logic;
    signal cycle:            integer range 0 to 7;
    signal instruction:      std_logic_vector(DATA_WIDTH-1 downto 0);
    signal brk_flag:         std_logic;
    
    --Interrupt_Logic signals--
    signal irq_disable: std_logic;
    signal nmi_clr:     std_logic;
    signal rst_clr:     std_logic;
    signal irq_flag:    std_logic;
    signal nmi_flag:    std_logic;
    signal rst_flag:    std_logic;
    
    --CONTROL SIGNALS--
    signal DL_DB, DL_ADL, DL_ADH, ZERO_ADH:                std_logic;
    signal ONE_ADH, FF_ADH, ADH_ABH:                       std_logic;
    signal ADL_ABL, PCL_PCL, ADL_PCL:                      std_logic;
    signal I_PC, PCL_DB, PCL_ADL:                          std_logic;
    signal PCH_PCH, ADH_PCH, PCH_DB, PCH_ADH:              std_logic;
    signal SB_ADH, SB_DB, FA_ADL, FB_ADL, FC_ADL:          std_logic;
    signal FD_ADL, FE_ADL, FF_ADL, S_ADL, SB_S, D_S, S_SB: std_logic;
    signal NDB_ADD, DB_ADD, ADL_ADD, ONE_ADDC:             std_logic;
    signal DAA, DSA, SUMS, ANDS, EORS:                     std_logic;
    signal ORS, SRS, ADD_ADL, ADD_SB, FF_ADD:              std_logic;
    signal ZERO_ADD, SB_ADD, SB_AC, DB_SB, ADH_SB:         std_logic;
    signal AC_DB, AC_SB, SB_X, X_SB, SB_Y, Y_SB:           std_logic;
    signal P_DB, DB0_C, ZERO_C, ONE_C, ACR_C, DB1_Z:       std_logic;
    signal DBZ_Z, DB2_I, ZERO_I, ONE_I,  DB3_D:            std_logic;
    signal ZERO_D, ONE_D, DB6_V, AVR_V, ONE_V, DB7_N:      std_logic;
begin
    clk_ph1 <= not clk;
    clk_ph2 <= clk;
    
    r_nw <= r_nw_signal;
    
    address <= ABH & ABL;
        
    data <= DOR when (BE and not r_nw_signal and clk_ph2) = '1' else
            (others => 'Z');
    
    DB <= DL when DL_DB = '1'else
          PCL when PCL_DB = '1'else
          PCH when PCH_DB = '1'else
          SB when SB_DB = '1' else
          P when P_DB = '1' else
          AC when AC_DB = '1' else
          (others => '0');
    
    ADL <= DL when DL_ADL = '1' else
           PCL when PCL_ADL = '1' else
           S when S_ADL = '1' else
           ADD when ADD_ADL = '1' else
           x"FA" when FA_ADL = '1' else
           x"FB" when FB_ADL = '1' else
           x"FC" when FC_ADL = '1' else
           x"FD" when FD_ADL = '1' else
           x"FE" when FE_ADL = '1' else
           x"FF" when FF_ADL = '1' else
           (others => '0');
               
    ADH <= DL when DL_ADH = '1' else
           PCH when PCH_ADH = '1' else
           SB when SB_ADH = '1' else
           x"00" when ZERO_ADH = '1' else
           x"01" when ONE_ADH = '1' else
           x"FF" when FF_ADH = '1' else
           (others => '0');    
           
    SB <= DB when DB_SB = '1' else
          ADH when ADH_SB = '1' else
          S when S_SB = '1' else
          ADD when ADD_SB = '1' else
          X when X_SB = '1' else
          Y when Y_SB = '1' else
          AC when AC_SB = '1' else
          (others => '0');
          
    S <= SB when SB_S = '1' else
         S-1 when D_S = '1' else
         S;
         
    AI <= SB when SB_ADD = '1' else
          x"00" when ZERO_ADD = '1' else
          x"FF" when FF_ADD = '1' else
          AI;
          
    BI <= DB when DB_ADD = '1' else
          not DB when NDB_ADD = '1' else
          ADL when ADL_ADD = '1' else
          BI;
          
    X <= SB when SB_X = '1' else
         X;
    
    Y <= SB when SB_Y = '1' else
         Y;
         
    AC <= SB when SB_AC = '1' else
          AC;
        
    --Carry(C) flag--  
    P(0) <= DB(0) when DB0_C = '1' else
            '0' when ZERO_C = '1' else
            '1' when ONE_C = '1' else
            ACR when ACR_C = '1' else 
            P(0);
    
    --Zero(Z) flag--        
    P(1) <= DB(1) when DB1_Z = '1' else
            not or_reduce(DB) when ZERO_C = '1' else
            P(1);       
    
    --IRQ disable(I) flag--      
    P(2) <= DB(2) when DB2_I = '1' else
         '0' when ZERO_I = '1' else
         '1' when ONE_I = '1' else
         P(2);
         
    --Decimal(D) flag--
    P(3) <= DB(3) when DB3_D = '1' else
            '0' when ZERO_D = '1' else
            '1' when ONE_D = '1' else
            P(3);
    
    --Overflow(V) flag--     
    P(6) <= DB(6) when DB6_V = '1' else
            AVR when AVR_V = '1' else
            '1' when ONE_V = '1' else
            P(6);
    
    --Negative(N) flag--        
    P(7) <= DB(7) when DB7_N = '1' else
            P(7);
            
    PC_LOAD: process (clk_ph1, rst, DB, ADH_ABH, ADH, ADL_ABL, ADL) begin
        if(clk_ph1 = '1') then
            if(rst = '1') then
                ABL <= (others => '0');
                ABH <= (others => '0');
                DOR <= (others => '0');
            else
                DOR <= DB;
                
                if(ADL_ABL = '1') then
                    ABL <= ADL;
                end if;
                
                if(ADH_ABH = '1') then
                    ABH <= ADH;
                end if;
            end if;
        end if;
    end process;
    
    REGISTER_LOAD: process(clk_ph2, rst, PCL_Logic_Output, PCH_Logic_Output, SUMS, ANDS, EORS, ORS, SRS, ALU_OUT) begin
        if(clk_ph2 = '1') then
            if(rst = '1') then
                PCL <= (others => '0');
                PCH <= (others => '0');
                ADD <= (others => '0');
            else
                PCL <= PCL_Logic_Output;
                PCH <= PCH_Logic_Output;
                
                if(SUMS='1' or ANDS='1' or EORS='1' or ORS='1' or SRS='1') then
                    ADD <= ALU_OUT;
                end if;
            end if;
        end if;
    end process;
    
    DATA_IN: process(clk_ph2) begin
        if(rising_edge(clk_ph2)) then
            if(rst = '1') then
                DL <= (others => '0');
                PD <= (others => '0');
                rdy_signal <= '1';
            else    
                DL <= data;
                PD <= data;
                rdy_signal <= rdy or not r_nw_signal;
            end if;
        end if;
    end process;
    
    PC_Logic: entity work.PC_Logic
    port map(
        PCL              => PCL,
        PCH              => PCH,
        ADL              => ADL,
        ADH              => ADH,
        PCL_PCL          => PCL_PCL,
        PCH_PCH          => PCH_PCH,
        ADL_PCL          => ADL_PCL,
        ADH_PCH          => ADH_PCH,
        I_PC             => I_PC,
        PCL_Logic_Output => PCL_Logic_Output,
        PCH_Logic_Output => PCH_Logic_Output
    );
    
    ALU: entity work.ALU
    port map(
        AI       => AI,
        BI       => BI,
        SUMS     => SUMS,
        ANDS     => ANDS,   
        EORS     => EORS,
        ORS      => ORS,
        SRS      => SRS,
        ONE_ADDC => ONE_ADDC,
        AVR      => AVR,
        ACR      => ACR,
        ALU_OUT  => ALU_OUT
    );
    
    Timing_Logic: entity work.Timing_Logic
    port map(
        rst             => rst,
        clk_ph1         => clk_ph1,
        PD              => PD,
        int_flag        => int_flag,
        brk_clr         => brk_clr,
        cycle_increment => cycle_increment,
        cycle_reset     => cycle_reset,
        cycle           => cycle,
        instruction     => instruction,
        brk_flag        => brk_flag,
        sync            => sync
    );        
    
    Interrupt_Logic: entity work.Interrupt_Logic
    port map(
        rst         => rst,
        clk_ph1     => clk_ph1,
        irq         => irq,
        nmi         => nmi,
        irq_disable => irq_disable,
        nmi_clr     => nmi_clr,
        rst_clr     => rst_clr,
        irq_flag    => irq_flag,
        nmi_flag    => nmi_flag,
        rst_flag    => rst_flag,
        int_flag    => int_flag
    );
    
    Decoder: entity work.Decoder
    port map(
        rdy             => rdy_signal,
        brk_flag        => brk_flag,
        irq_flag        => irq_flag,
        nmi_flag        => nmi_flag,
        rst_flag        => rst_flag,
        instruction     => instruction,
        cycle           => cycle,
        cycle_increment => cycle_increment,
        cycle_reset     => cycle_reset,
        brk_clr         => brk_clr,
        irq_disable     => irq_disable,
        nmi_clr         => nmi_clr,
        rst_clr         => rst_clr,
        r_nw            => r_nw_signal,
        DL_DB           => DL_DB,
        DL_ADL          => DL_ADL,
        DL_ADH          => DL_ADH,
        ZERO_ADH        => ZERO_ADH,
        ONE_ADH         => ONE_ADH,
        FF_ADH          => FF_ADH,
        ADH_ABH         => ADH_ABH,
        ADL_ABL         => ADL_ABL,
        PCL_PCL         => PCL_PCL,
        ADL_PCL         => ADL_PCL,
        I_PC            => I_PC,
        PCL_DB          => PCL_DB,
        PCL_ADL         => PCL_ADL,
        PCH_PCH         => PCH_PCH,
        ADH_PCH         => ADH_PCH,
        PCH_DB          => PCH_DB,
        PCH_ADH         => PCH_ADH,
        SB_ADH          => SB_ADH,
        SB_DB           => SB_DB,
        FA_ADL          => FA_ADL,
        FB_ADL          => FB_ADL,
        FC_ADL          => FC_ADL,
        FD_ADL          => FD_ADL,
        FE_ADL          => FE_ADL,
        FF_ADL          => FF_ADL,
        S_ADL           => S_ADL,
        SB_S            => SB_S,
        D_S             => D_S,
        S_SB            => S_SB,
        NDB_ADD         => NDB_ADD,
        DB_ADD          => DB_ADD,
        ADL_ADD         => ADL_ADD,
        ONE_ADDC        => ONE_ADDC,
        DAA             => DAA,
        DSA             => DSA,
        SUMS            => SUMS,
        ANDS            => ANDS,
        EORS            => EORS,
        ORS             => ORS,
        SRS             => SRS,
        ADD_ADL         => ADD_ADL,
        ADD_SB          => ADD_SB,
        FF_ADD          => FF_ADD,
        ZERO_ADD        => ZERO_ADD,
        SB_ADD          => SB_ADD,
        SB_AC           => SB_AC,
        DB_SB           => DB_SB,
        ADH_SB          => ADH_SB,
        AC_DB           => AC_DB,
        AC_SB           => AC_SB,
        SB_X            => SB_X,
        X_SB            => X_SB,
        SB_Y            => SB_Y,
        Y_SB            => Y_SB,
        P_DB            => P_DB,
        DB0_C           => DB0_C,
        ZERO_C          => ZERO_C,
        ONE_C           => ONE_C,
        ACR_C           => ACR_C,
        DB1_Z           => DB1_Z,
        DBZ_Z           => DBZ_Z,
        DB2_I           => DB2_I,
        ZERO_I          => ZERO_I,
        ONE_I           => ONE_I,
        DB3_D           => DB3_D,
        ZERO_D          => ZERO_D,
        ONE_D           => ONE_D,
        DB6_V           => DB6_V,
        AVR_V           => AVR_V,
        ONE_V           => ONE_V,
        DB7_N           => DB7_N
    );
end Behavioral;
























