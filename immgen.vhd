-- Gerador de Imediatos
-- Lucas Araújo Pena - 130056162

use IEEE.std_logic_1164.all;

type FORMAT_RV is { R_type, I_type, S_type, SB_type, UJ_type, U_type };

entity genImm32 is
  port (
  instr : in std_logic_vector(31 downto 0);
  imm32 : out signed(31 downto 0)
  );
end genImm32;

architecture a of genImm32 is
  signal a, b, c, d     : std_logic_vector(31 downto 0);
  signal imm32_tmp      : std_logic_vector(31 downto 0);

  begin
    case instr is
      when R_type =>
        imm32_tmp <= 
  
      when I_type =>
        imm32_tmp <= a(20 to 31);
  
      when S_type =>
        imm32_tmp <= a(7 to 11) & b(25 to 31);
  
      when SB_type =>
        imm32_tmp <= a(8 to 11) & b(25 to 31) & c(7) & d(31);
  
      when UJ_type =>
        imm32_tmp <= a(21 to 30) & b(20) & c(12 to 19) & d(31);
  
      when U_type =>
        imm32_tmp <= a(12 to 31);
        
    end case;
  WAIT;

end gemImm32;

