library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity PC_Logic is
    generic(
        DATA_WIDTH: integer := 8
    );
    port(
        PCL, PCH, ADL, ADH: in std_logic_vector(DATA_WIDTH-1 downto 0);
        PCL_PCL, PCH_PCH:   in std_logic;
        ADL_PCL, ADH_PCH:   in std_logic;
        I_PC:               in std_logic;       
        PCL_Logic_Output:   out std_logic_vector(DATA_WIDTH-1 downto 0);
        PCH_Logic_Output:   out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end PC_Logic;

architecture Behavioral of PC_Logic is
    signal PCLS:    std_logic_vector(DATA_WIDTH-1 downto 0);
    signal PCHS:    std_logic_vector(DATA_WIDTH-1 downto 0);
    signal PCLC:    std_logic;
    signal PCL_SUM: std_logic_vector(DATA_WIDTH downto 0);
begin
    PCLS <= PCL when PCL_PCL = '1' else
            ADL when ADL_PCL = '1' else
            PCL;
            
    PCHS <= PCH when PCH_PCH = '1' else
            ADH when ADH_PCH = '1' else
            PCH;

    PCL_SUM <= ('0' & PCLS) + I_PC;
    PCLC <= PCL_SUM(DATA_WIDTH);
    PCL_Logic_Output <= PCL_SUM(DATA_WIDTH-1 downto 0);
   
    PCH_Logic_Output <= PCHS + PCLC;  
end Behavioral;
























