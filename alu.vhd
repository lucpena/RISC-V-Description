/*

    Simulador uniciclo do RISC-V

    Departamento de Ciencia da Computacao
    Organizacao e Arquitetura de Computadores


    Lucas Araujo Pena - 130056162


*/

library IEEE;
    use IEEE.STD_LOGIC_1164.all;
    use IEEE.STD_LOGIC_UNSIGNED.ALL;
    use IEEE.NUMERIC_STD.all;
    
entity ALU is
    port(
        aluCtrl : in  STD_LOGIC_VECTOR(3 downto 0);
        A, B    : in  STD_LOGIC_VECTOR(31 downto 0);
        
        result  : out STD_LOGIC_VECTOR(31 downto 0);
        zero    : out STD_LOGIC
    );
end ALU;

architecture ALU_arch of ALU is

	signal ulaRV_Resultado	:	STD_LOGIC_VECTOR(31 downto 0);         -- Saída da ULA

    begin process(A, B, aluCtrl)
        begin case aluCtrl is
            
            -- ADD A, B 
            when "0000" => ulaRV_Resultado <= STD_LOGIC_VECTOR(SIGNED(A)  +  SIGNED(B));

            -- SUB A, B
            when "0001" => ulaRV_Resultado <= STD_LOGIC_VECTOR(SIGNED(A)  -  SIGNED(B));

            -- AND A, B
            when "0010" => ulaRV_Resultado <= A and B;

            -- OR A, B
            when "0011" => ulaRV_Resultado <= A or B;

            -- XOR A, B
            when "0100" => ulaRV_Resultado <= A xor B;

            -- SLL A, B
            --when "0101" => ulaRV_Resultado <= STD_LOGIC_VECTOR(SHIFT_RIGHT(A, B));
            
            -- SRL A, B
            --when "0110" => ulaRV_Resultado <= SHIFT_RIGHT(SIGNED(A), B);

            -- SRA A, B
            --when "0111" => ulaRV_Resultado <= STD_LOGIC_VECTOR(A sra B);

            -- SLT A, B
            when "1000"=>
                if(A < B) then
                    ulaRV_Resultado <= x"00000001";
                end if;

            -- SLTU A, B
            when "1001"=>
                if(A < B) then
                    --ulaRV_Resultado <= UNSIGNED(x"00000001");
                end if;

            -- SGE A, B
            when "1010"=>
                if(A >= B) then
                    ulaRV_Resultado <= x"00000001";
                end if;

            -- SGEU A, B
            when "1011"=>
                if(A >= B) then
                    --ulaRV_Resultado <= unsigned(x"00000001");
                end if;

            -- SEQ A, B
            when "1100"=>
                if(A = B) then
                    ulaRV_Resultado <= x"00000001";
                end if;

            -- SNE A, B
            when "1101"=>
                if(A /= B) then
                    ulaRV_Resultado <= x"00000001";
                end if;

            -- Default case
            when others => ulaRV_Resultado <= A + B;

        end case;
    end process;

	-- Atribui resultado final para a saída da ULA
    result <= ulaRV_Resultado;
    
    -- Atribui o valor da saida Zero
    process(ulaRV_Resultado) begin
    	if ulaRV_Resultado = x"00000000" then
        	zero <= '1';
        else
        	zero <= '0';
        end if;
    end process;

    
end architecture ALU_arch;