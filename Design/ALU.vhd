library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity ALU is
    Port (A_in : in std_logic_vector(7 downto 0);
          B_in : in std_logic_vector(7 downto 0);
          SUMS, ANDS, EORS, ORS, SRS : in std_logic ;   
          DAA, I_ADCC : in std_logic;
          AVR, ACR, HC : out std_logic;
          ALU_OUT : out std_logic_vector(7 downto 0)
          );
end ALU;

architecture Behavioral of ALU is

signal sum_out    : std_logic_vector (8 downto 0);
signal s_alu_out  : std_logic_vector (7 downto 0);

begin
   
    process(A_in, B_in, SUMS, ANDS, EORS, ORS, SRS, I_ADCC,sum_out) begin
        if (SUMS = '1') then
            sum_out <= ('0' & A_in) + ('0' & B_in) + I_ADCC;
            ACR <= sum_out(8);
            s_alu_out <= sum_out(7 downto 0);
        elsif (ANDS = '1') then
            s_alu_out <= A_in and B_in;
        elsif (EORS = '1') then
            s_alu_out <= A_in xor B_in;
        elsif (ORS = '1') then
            s_alu_out <= A_in or B_in;
        elsif (SRS = '1') then
            ACR <= A_in(0);
            s_alu_out <= '0' & A_in(7 downto 1);
        else
            s_alu_out <= "00000000";
            ACR <= '0';
            sum_out <= "000000000";
        end if;
        
    ALU_OUT <= s_alu_out;
    AVR <= (A_in(7) and B_in(7) and (not(s_alu_out(7)))) or ((not(A_in(7))) and (not(B_in(7))) and s_alu_out(7));
    
    end process;
end Behavioral;