library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity ALU is
    generic(
        DATA_WIDTH: integer := 8
    );
    port (
        AI:                         in std_logic_vector(DATA_WIDTH-1 downto 0);
        BI:                         in std_logic_vector(DATA_WIDTH-1 downto 0);
        SUMS, ANDS, EORS, ORS, SRS: in std_logic ;   
        DAA, I_ADDC:                in std_logic;
        AVR, ACR, HC:               out std_logic;
        ALU_OUT:                    out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end ALU;

architecture Behavioral of ALU is
    signal sum_out:         std_logic_vector (DATA_WIDTH downto 0);
    signal alu_out_signal:  std_logic_vector (DATA_WIDTH-1 downto 0);
begin   
    ALU_OUT <= alu_out_signal;
    AVR <= (AI(DATA_WIDTH-1) and BI(DATA_WIDTH-1) and (not(alu_out_signal(DATA_WIDTH-1)))) 
            or ((not(AI(DATA_WIDTH-1))) and (not(BI(DATA_WIDTH-1))) and alu_out_signal(DATA_WIDTH-1));

    process(AI, BI, SUMS, ANDS, EORS, ORS, SRS, I_ADDC, sum_out, alu_out_signal) begin
        sum_out <= (others => '0');
        ACR <= '0';
        alu_out_signal <= (others => '0');
        
        if (SUMS = '1') then
            sum_out <= ('0' & AI) + ('0' & BI) + I_ADDC;
            ACR <= sum_out(DATA_WIDTH);
            alu_out_signal <= sum_out(DATA_WIDTH-1 downto 0);
        elsif (ANDS = '1') then
            alu_out_signal <= AI and BI;
        elsif (EORS = '1') then
            alu_out_signal <= AI xor BI;
        elsif (ORS = '1') then
            alu_out_signal <= AI or BI;
        elsif (SRS = '1') then
            ACR <= AI(0);
            alu_out_signal <= '0' & AI(DATA_WIDTH-1 downto 1);
        end if;    
    end process;
end Behavioral;