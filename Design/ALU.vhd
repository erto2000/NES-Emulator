library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity ALU is
    generic(
        DATA_WIDTH: integer := 8
    );
    port (
        A_in : in std_logic_vector(DATA_WIDTH-1 downto 0);
        B_in : in std_logic_vector(DATA_WIDTH-1 downto 0);
        SUMS, ANDS, EORS, ORS, SRS : in std_logic ;   
        DAA, I_ADCC : in std_logic;
        AVR, ACR, HC : out std_logic;
        ALU_OUT : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end ALU;

architecture Behavioral of ALU is
    signal sum_out    : std_logic_vector (DATA_WIDTH downto 0);
    signal s_alu_out  : std_logic_vector (DATA_WIDTH-1 downto 0);
begin   
    process(A_in, B_in, SUMS, ANDS, EORS, ORS, SRS, I_ADCC, sum_out, s_alu_out) begin
        if (SUMS = '1') then
            sum_out <= ('0' & A_in) + ('0' & B_in) + I_ADCC;
            ACR <= sum_out(DATA_WIDTH);
            s_alu_out <= sum_out(DATA_WIDTH-1 downto 0);
        elsif (ANDS = '1') then
            s_alu_out <= A_in and B_in;
        elsif (EORS = '1') then
            s_alu_out <= A_in xor B_in;
        elsif (ORS = '1') then
            s_alu_out <= A_in or B_in;
        elsif (SRS = '1') then
            ACR <= A_in(0);
            s_alu_out <= '0' & A_in(DATA_WIDTH downto 1);
        else
            s_alu_out <= (others => '0');
            ACR <= '0';
            sum_out <= (others => '0');
        end if;
        
        ALU_OUT <= s_alu_out;
        AVR <= (A_in(DATA_WIDTH) and B_in(DATA_WIDTH) and (not(s_alu_out(DATA_WIDTH)))) or ((not(A_in(DATA_WIDTH))) and (not(B_in(DATA_WIDTH))) and s_alu_out(DATA_WIDTH));
    
    end process;
end Behavioral;