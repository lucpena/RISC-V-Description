/*

    Simulador uniciclo do RISC-V

    Departamento de Ciencia da Computacao
    Organizacao e Arquitetura de Computadores


    Lucas Araujo Pena - 130056162


*/

library STD;
	use	STD.TEXTIO.all;
    
library IEEE;
	use IEEE.STD_LOGIC_1164.all;
    use IEEE.NUMERIC_STD.all;
    
entity memory is
		generic(
        
        	FILENAME	:	string  := "program";
            MEM_SIZE	:	integer := 1024
         
        );
        port(
        
        	clock	:	in STD_LOGIC;
        
        	addr	:	in STD_LOGIC_VECTOR(31 downto 0);
            dataIn	:	in STD_LOGIC_VECTOR(31 downto 0);
            rdStb	:	in STD_LOGIC;
            wrStb	:	in STD_LOGIC;
            
            dataOut	:	out STD_LOGIC_VECTOR(31 downto 0)
            );
end memory;

architecture memory_arch of memory is

	type   matriz is array(0 to MEM_SIZE - 1) of STD_LOGIC_VECTOR(7 downto 0);
    signal memo: matriz;
    signal aux : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    
    begin
    
    process(clock)
    	
        variable loadFile	  : boolean := true;
        variable address	  : STD_LOGIC_VECTOR(31 downto 0);
        variable datum		  : STD_LOGIC_VECTOR(31 downto 0);
        variable currentLine : line;
        file binFile		  : text is in FILENAME;
        
	begin
    
    	if loadFile then
        	--Inicializando a memoria
        	for i in 0 to MEM_SIZE -1 loop
            	memo(i) <= (others=>'0');
            end loop;
            address := (others => '0');
            
            -- Carregando o arquivo
            while(not endfile (binFile)) loop
            	readline(binFile, currentLine);
                hread(currentLine, datum);
                assert TO_INTEGER(UNSIGNED(address(30 downto 0))) < MEM_SIZE
                	report "Address out of range"
                    severity failure;
                
                memo(TO_INTEGER(UNSIGNED(address(30 downto 0))))      <= datum(31 downto 24);
                memo(TO_INTEGER(UNSIGNED(address(30 downto 0)) + 1))  <= datum(23 downto 16);
                memo(TO_INTEGER(UNSIGNED(address(30 downto 0)) + 2))  <= datum(15 downto  8);
                memo(TO_INTEGER(UNSIGNED(address(30 downto 0)) + 3))  <= datum( 7 downto  0);
                
                address := STD_LOGIC_VECTOR(TO_UNSIGNED(TO_INTEGER(UNSIGNED(address)) + 4,32));
                
		end loop;
            
            -- Fechando o Arquivo
            file_close(binFile);
            
            loadFile := false;
            
            elsif(clock'event and clock = '0') then
            	if (wrStb ='1') then
                	memo(TO_INTEGER(UNSIGNED(addr)))      <= dataIn(31 downto 24);
                    memo(TO_INTEGER(UNSIGNED(addr)) + 1)  <= dataIn(23 downto 16);
                    memo(TO_INTEGER(UNSIGNED(addr)) + 2)  <= dataIn(15 downto  8);
                    memo(TO_INTEGER(UNSIGNED(addr)) + 3)  <= dataIn(7  downto  0);
                
                elsif (rdStb = '1') then
                	aux(31 downto 24) <= memo(TO_INTEGER(UNSIGNED(addr)));
                    aux(23 downto 16) <= memo(TO_INTEGER(UNSIGNED(addr)) + 1);
                    aux(15 downto  8) <= memo(TO_INTEGER(UNSIGNED(addr)) + 2);
                    aux( 7 downto  0) <= memo(TO_INTEGER(UNSIGNED(addr)) + 3);
                
           		end if;
        	end if;
    	end process;
    
    dataOut <= aux;
    

end memory_arch;