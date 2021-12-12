library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity PC_Logic is
    generic(
        DATA_WIDTH: integer := 8
    );
    port(
        PCL: in std_logic_vector(DATA_WIDTH-1 downto 0);
        PCH: in std_logic_vector(DATA_WIDTH-1 downto 0);       
        ADL: in std_logic_vector(DATA_WIDTH-1 downto 0);       
        ADH: in std_logic_vector(DATA_WIDTH-1 downto 0);       
        PCL_PCL: in std_logic;
        PCH_PCH: in std_logic;
        ADL_PCL: in std_logic;
        ADH_PCH: in std_logic;
        I_PC: in std_logic;       
        PCL_Logic_Output: out std_logic_vector(DATA_WIDTH-1 downto 0);
        PCH_Logic_Output: out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end PC_Logic;

architecture Behavioral of PC_Logic is
    signal PCLS: std_logic_vector(DATA_WIDTH-1 downto 0);
    signal PCHS: std_logic_vector(DATA_WIDTH-1 downto 0);
    signal PCLC: std_logic;
    signal PCL_SUM: std_logic_vector(DATA_WIDTH downto 0);
begin
    process(PCL) begin
        if(PCL_PCL = '1') then
            PCLS <= PCL;
        elsif(ADL_PCL = '1') then
            PCLS <= ADL;
        else
            PCLS <= PCL;
        end if;
            
        if(PCH_PCH = '1') then
            PCHS <= PCH;
        elsif(ADH_PCH = '1') then
            PCHS <= ADH;
        else
            PCHS <= PCH;            
        end if;
        
        PCL_SUM <= ('0' & PCLS) + I_PC;
        PCLC <= PCL_SUM(DATA_WIDTH);
        PCL_Logic_Output <= PCL_SUM(DATA_WIDTH-1 downto 0);
       
        PCH_Logic_Output <= PCHS + PCLC;    
    end process;
end Behavioral;
























