/*

    Simulador uniciclo do RISC-V

    Departamento de Ciencia da Computacao
    Organizacao e Arquitetura de Computadores


    Lucas Araujo Pena - 130056162


*/

library IEEE;
    use IEEE.STD_LOGIC_1164.all;
    use IEEE.NUMERIC_STD.all;

entity riscv is port(

	clock		: in	STD_LOGIC;						 -- Clock
    reset		: in 	STD_LOGIC;						 -- Ordem de reset
    
    I_addr		: out 	STD_LOGIC_VECTOR(31 downto 0);	 -- Endereco destino na memoria de instrucao
    I_rdStb		: out   STD_LOGIC;						 -- Sinal de controle de leitura para memoria de instrucao
    I_wrStb		: out 	STD_LOGIC;						 -- Sinal de controle de escrita para memoria de instrucao
    I_dataOut	: out 	STD_LOGIC_VECTOR(31 downto 0);	 -- Dado enviado para a memoria de instrucao
    I_dataIn	: in 	STD_LOGIC_VECTOR(31 downto 0);	 -- Instrucao recebida da memoria de instrucao
    
    D_addr		: out 	STD_LOGIC_VECTOR(31 downto 0);	 -- Endereco de destino na memoria de dados
    D_rdStb		: out 	STD_LOGIC;						 -- Sinal de controle de leitura da memoria de dados
    D_wrStb		: out	STD_LOGIC;						 -- Sinal de controle de escrita da memoria de dados
    D_dataOut	: out	STD_LOGIC_VECTOR(31 downto 0); 	 -- Dado enviado para a memoria de dados
    D_dataIn	: in 	STD_LOGIC_VECTOR(31 downto 0)	 -- Dado recebido da memoria de dados

);
end riscv;

architecture riscv_arch of riscv is

-- Instanciando a ULA
component ALU port(

	A			: in	STD_LOGIC_VECTOR(31 downto 0);
    B			: in	STD_LOGIC_VECTOR(31 downto 0);
    aluCtrl		: in	STD_LOGIC_VECTOR(3 downto 0);
    
    zero		: out	STD_LOGIC;
    result		: out	STD_LOGIC_VECTOR(31 downto 0)

);
end component;

-- Registradores temporarios para guardar operandos, resultados e palavras
component Registers port(

	clock		: in	STD_LOGIC;
    reset		: in 	STD_LOGIC;
    wControl	: in	STD_LOGIC;
    reg1Addr	: in	STD_LOGIC_VECTOR(4 downto 0);
    reg2Addr	: in	STD_LOGIC_VECTOR(4 downto 0);
    regWrite	: in	STD_LOGIC_VECTOR(4 downto 0);
    dataWrite	: in 	STD_LOGIC_VECTOR(31 downto 0);
    data1Read	: out	STD_LOGIC_VECTOR(31 downto 0);
    data2Read	: out	STD_LOGIC_VECTOR(31 downto 0)

);
end component;

--------------------------------------------------------------------
-- Sinais de estagio IF
--------------------------------------------------------------------
signal IF_PC				:	STD_LOGIC_VECTOR(31 downto 0);		-- Endereco da Instrucao Atual
signal IF_PC_4				:	STD_LOGIC_VECTOR(31 downto 0);		-- Endereco da Instrucao Atual + 4
signal IF_PCsrc				:	STD_LOGIC_VECTOR( 1 downto 0);		-- Sinal de controle para o MUX selecionar proxima instrucao
signal IF_next_PC			:	STD_LOGIC_VECTOR(31 downto 0);		-- Instrucao da proxima instrucao
signal IF_flush				:	STD_LOGIC;							-- Sinal de Flush IF / ID
signal old_PC_4				:	STD_LOGIC_VECTOR(31 downto 0);		-- PC + 4 antes do branch


--------------------------------------------------------------------
-- Sinais de estagio ID
--------------------------------------------------------------------
signal ID_instruction		: 	STD_LOGIC_VECTOR(31 downto 0);		-- Instrucao a ser decodificada
signal ID_PC_4				: 	STD_LOGIC_VECTOR(31 downto 0);		-- Endereco da instrucao + 4
signal ID_data1Read 		: 	STD_LOGIC_VECTOR(31 downto 0);		-- Dados no registrador rs
signal ID_data2Read	    	: 	STD_LOGIC_VECTOR(31 downto 0);		-- Dados no registrador rt
signal ID_regWriteControl	:	STD_LOGIC;							-- Sinal de controle de escrita para os registradores
signal ID_rs1				:	STD_LOGIC_VECTOR(4 downto 0);		-- Registrador rs
signal ID_rs2				:	STD_LOGIC_VECTOR(4 downto 0);		-- Registrador rt
signal ID_rd				:	STD_LOGIC_VECTOR(4 downto 0);		-- Registrador rd
signal ID_ALUop				:	STD_LOGIC_VECTOR(1 downto 0);		-- Operacao da ULA
signal ID_ALUsrc			:	STD_LOGIC;							-- Fonte de Sinal da ULA
signal ID_regDst			:	STD_LOGIC;							-- Sinal que controla o MUX que escolhe o registrador a ser escrito
signal ID_branch			:	STD_LOGIC_VECTOR(1 downto 0);		-- Habilita a condicao de branch
signal ID_memWrite			:	STD_LOGIC;							-- Sinal de controle de escrita da memoria de dados
signal ID_memRead			:	STD_LOGIC;							-- Sinal de controle de leitura da memoria de dados
signal ID_memToReg			:	STD_LOGIC;							-- Sinal de controle do MUX
signal ID_immediate			:	STD_LOGIC_VECTOR(31 downto 0);		-- Valor imediato extendido para o endereco de branch
signal ID_flush				:	STD_LOGIC;							-- Sinal de flush ID / EX 
signal ID_funct7			:	STD_LOGIC_VECTOR(6 downto 0);		-- Sinal do funct7
signal ID_funct3			:	STD_LOGIC_VECTOR(2 downto 0);		-- Sinal do funct3

--------------------------------------------------------------------
-- Sinais de estagio EX
--------------------------------------------------------------------
signal EX_PC_4				:	STD_LOGIC_VECTOR(31 downto 0);		-- Endereco da instrucao + 4
signal EX_data1Read			:	STD_LOGIC_VECTOR(31 downto 0);		-- Dado no registrador rs
signal EX_data2Read			:	STD_LOGIC_VECTOR(31 downto 0);		-- Dado no refistrador rt
signal EX_regWriteControl	:	STD_LOGIC;							-- Sinal de controle de escrita para registradores
signal EX_regWriteAddr		:	STD_LOGIC_VECTOR(4 downto 0);		-- Endereco do registrador a ser escrito
signal EX_rs1				:	STD_LOGIC_VECTOR(4 downto 0);		-- Endereco do registrador rs
signal EX_rs2				:	STD_LOGIC_VECTOR(4 downto 0);		-- Endereco do registrador rt
signal EX_rd				:	STD_LOGIC_VECTOR(4 downto 0);		-- Endereco do registrador rd
signal EX_ALUop				:	STD_LOGIC_VECTOR(1 downto 0);		-- Operacao da ULA
signal EX_ALUsrc			: 	STD_LOGIC;							-- Sinal de controle do MUX
signal EX_ALU_A_input		: 	STD_LOGIC_VECTOR(31 downto 0);		-- Entrada A da ULA
signal EX_p_ALU_B_input		: 	STD_LOGIC_VECTOR(31 downto 0);		-- Possivel entrada B da ULA
signal EX_ALU_B_input		: 	STD_LOGIC_VECTOR(31 downto 0);		-- Entrada B da ULA
signal EX_ALUfwrdA			: 	STD_LOGIC_VECTOR(1 downto 0);		-- Sinal de controle do MUX da saida A da ULA
signal EX_ALUfwrdB			:	STD_LOGIC_VECTOR(1 downto 0);		-- Sinal de controle do MUX da saida A da ULA
signal EX_regDst			: 	STD_LOGIC;							-- Sinal que controla o MUX que escolhe o registrador a ser escrito
signal EX_branch			: 	STD_LOGIC_VECTOR(1 downto 0);		-- Habilita a condicao de Branch
signal EX_memWrite			: 	STD_LOGIC;							-- Sinal de controle para escrita na memoria de dados
signal EX_memRead			: 	STD_LOGIC;							-- Sinal de controle para leitura na memoria de dados
signal EX_memToReg			: 	STD_LOGIC;							-- Registradores
signal EX_immediate			: 	STD_LOGIC_VECTOR(31 downto 0);		-- Extende o valor do imediato para o endereco de branch
signal EX_branchAddr		: 	STD_LOGIC_VECTOR(31 downto 0);		-- Endereco de branch
signal EX_ALUresult			:	STD_LOGIC_VECTOR(31 downto 0);		-- Resultado da ULA
signal EX_ALUctrl			: 	STD_LOGIC_VECTOR(3 downto 0);		-- Controle da ULA
signal EX_zero				: 	STD_LOGIC;							-- Sinal Zero
signal EX_flush				: 	STD_LOGIC;							-- Sinal de Flush EX / MEM 
signal EX_funct7			:	STD_LOGIC_VECTOR(6 downto 0);		-- Sinal do funct7
signal EX_funct3			:	STD_LOGIC_VECTOR(2 downto 0);		-- Sinal do funct3

--------------------------------------------------------------------
-- Sinais de estagio MEM
--------------------------------------------------------------------
signal MEM_zero				: STD_LOGIC;							-- Sinal que indica se recebe um zero
signal MEM_memWrite			: STD_LOGIC;							-- Sinal de controle para escrita na memoria de dados
signal MEM_memRead			: STD_LOGIC;							-- Sinal de controle para leitura na memoria de dados
signal MEM_memData			: STD_LOGIC_VECTOR(31 downto 0);		-- Dado lido da memoria
signal MEM_ALUresult		: STD_LOGIC_VECTOR(31 downto 0);		-- Resuldado da ULA
signal MEM_data2Read		: STD_LOGIC_VECTOR(31 downto 0);		-- Dado no registrador rt
signal MEM_MemToReg			: STD_LOGIC;							-- Sinal de controle do MUX que escolhe qual dado sera escrito
signal MEM_regWriteControl  : STD_LOGIC;							-- Sinal de controle de escita para os registradores
signal MEM_regWriteAddr 	: STD_LOGIC_VECTOR(4 downto 0);			-- Endereco do registrador a ser escrito 
signal MEM_branch			: STD_LOGIC_VECTOR(1 downto 0);			-- Habilita a condicao de branch
signal MEM_fwrd				: STD_LOGIC_VECTOR(31 downto 0);		-- Dados para serem passados


--------------------------------------------------------------------
-- Sinais de estagio WB
--------------------------------------------------------------------
signal WB_memData			: STD_LOGIC_VECTOR(31 downto 0);		-- Dado lido da memoria de dados
signal WB_ALUresult			: STD_LOGIC_VECTOR(31 downto 0);		-- Resultado da ULA
signal WB_MemToReg			: STD_LOGIC;							-- Sinal que controla o MUX que escolhe qual dado sera escrito
signal WB_regWriteData  	: STD_LOGIC_VECTOR(31 downto 0);		-- Dado que sera escrito nos registradores
signal WB_regWriteControl	: STD_LOGIC;							-- Sinal de controle de escrita para registradores
signal WB_regWriteAddr  	: STD_LOGIC_VECTOR(4 downto 0);			-- Endereco do registrador a ser escrito

begin


------------------------------------------------------------------------
-- Estagio IF
------------------------------------------------------------------------

PCCounter: process(clock, reset, IF_flush)
begin
    -- Se reset = 1, o proximo endereco de instrucao sera o primeiro
	if reset = '1' or IF_flush = '1' then                           
		IF_PC <= (others => '0');
	-- Pega o proximo endereco de instrucao na subida de clock
	elsif RISING_EDGE(clock) then
		IF_PC <= IF_next_PC;
	end if;
end process;

-- PC + 4
IF_PC_4 <= STD_LOGIC_VECTOR(UNSIGNED(IF_PC) + TO_UNSIGNED(4,32));

-- MUX para o proximo endereco de instrucao
next_PC: process(IF_PCSrc, IF_PC_4, EX_branchAddr)
begin
	case IF_PCSrc is
	when "00" =>
		-- Sem Branch
		IF_next_PC <= IF_PC_4;
	when "01" =>
		-- Branch
		IF_next_PC <= EX_branchAddr;
	when "10" =>
		-- Falha no branch, continua execucao normal
		IF_next_PC <= ID_PC_4;
	when others =>
    	null;
	end case;
end process;


I_addr    <= IF_PC;                       -- Pega a instrucao da memoria
I_rdStb   <= '1';                         -- Sempre le da memoria de instrucoes
I_wrStb   <= '0';                         -- Nunca escreve na memoria de instrucoes
I_dataOut <= (others => '0');             -- Nunca escreve na memoria de instrucoes


------------------------------------------------------------------------
-- Registradores intermediarios IF/ID
------------------------------------------------------------------------

IF_input: process(clock, reset, ID_flush)
begin
    -- Se reset = 1, o dado sofrera flush
	if reset = '1' or ID_flush = '1' then
		ID_instruction <= (others => '0');
		ID_PC_4 <= (others => '0');

    -- Passe o dado na borda de subida do clock
	elsif RISING_EDGE(clock) then
		ID_instruction <= I_dataIn;
		ID_PC_4 <= IF_PC_4;
	end if;
end process;


------------------------------------------------------------------------
-- Instanciando Registradores
------------------------------------------------------------------------

Registers_inst: Registers
port map(
	clock 		=> clock,
	reset 		=> reset,
	wControl	=> WB_regWriteControl,
	reg1Addr	=> ID_instruction(25 downto 21),
	reg2Addr	=> ID_instruction(20 downto 16),
	regWrite	=> WB_regWriteAddr,
	dataWrite	=> WB_regWriteData,
	data1Read	=> ID_data1Read,
	data2Read	=> ID_data2Read
);


------------------------------------------------------------------------
-- Unidade de Controle
------------------------------------------------------------------------

CUnit: process(ID_instruction)
begin
	case ID_instruction(6 downto 0) is
	-- R-type
	when "0110011" =>
		ID_regWriteControl <= '1';
		ID_memToReg <= '0';
		ID_branch <= "00";
		ID_memRead <= '0';
		ID_memWrite <= '0';
		ID_regDst <= '1';
		ID_ALUop <= "10";
		ID_ALUsrc <= '0';

	-- LW
	when "0000011" =>
		ID_regWriteControl <= '1';
		ID_memToReg <= '1';
		ID_branch <= "00";
		ID_memRead <= '1';
		ID_memWrite <= '0';
		ID_regDst <= '0';
		ID_ALUop <= "01";
		ID_ALUsrc <= '1';

	-- SW
	when "0100011" =>
		ID_regWriteControl <= '0';
		ID_memToReg <= '1';
		ID_branch <= "00";
		ID_memRead <= '0';
		ID_memWrite <= '1';
		ID_regDst <= '0';
		ID_ALUop <= "01";
		ID_ALUsrc <= '1';

	-- BEQ
	when "1100011" =>
		ID_regWriteControl <= '0';
		ID_memToReg <= '0';
		ID_branch <= "10";
		ID_memRead <= '0';
		ID_memWrite <= '0';
		ID_regDst <= '0';
		ID_ALUop <= "11";
		ID_ALUsrc <= '0';

	-- others, inserts a NOP
	when others =>
		ID_regWriteControl <= '0';
		ID_memToReg <= '0';
		ID_branch <= "00";
		ID_memRead <= '0';
		ID_memWrite <= '0';
		ID_regDst <= '0';
		ID_ALUop <= "00";
		ID_ALUsrc <= '0';
	end case;
end process;


------------------------------------------------------------------------
-- ID STAGE
------------------------------------------------------------------------

genImm32: process(ID_instruction, ID_immediate, ID_funct3, ID_funct7)
begin

	case ID_instruction(6 downto 0) is
		-- R-Type
		when "0110011" =>
			ID_immediate <= (others => '0');
			ID_funct7	 <= ID_immediate(31 downto 25);
			ID_funct3	 <= ID_immediate(14 downto 12);	
			ID_rs1 		 <= ID_instruction(19 downto 15);
			ID_rs2 		 <= ID_instruction(24 downto 20);
			ID_rd 		 <= ID_instruction(11 downto  7);

		-- I-Type
		when "0000011" | "0010011" | "1100111" =>
			-- Imediato
			ID_immediate(11 downto  0)  <= ID_instruction(31 downto 20);

			-- Extensao de sinal
			ID_immediate(31 downto 12)  <=  x"FFFFF" when ID_instruction(11) = '1' else x"00000";

			-- Registradores
			ID_rs1 						<= ID_instruction(19 downto 15);
			ID_rd 						<= ID_instruction(11 downto 7);

		-- S-type
		when "0100011" =>
			-- Imediato
			ID_immediate(11 downto 0) <= ID_instruction(31 downto 25) & ID_instruction(11 downto 7);
			
			--Extensao de Sinal
			ID_immediate(31 downto 12)  <= x"FFFFF" when ID_instruction(11) = '1' else x"00000";

			-- Registradores
			ID_rs1 <= ID_instruction(19 downto 15);
			ID_rs2 <= ID_instruction(24 downto 20);
			ID_rd  <= (others => '0');

		-- SB-type
		when "1100011" =>
			-- Imediato
			ID_immediate(12 downto 1) <= ID_instruction(31) & ID_instruction(7) & ID_instruction(30 downto 25) & ID_instruction(11 downto 8);

			-- Extensao de Sinal
			ID_immediate(0)	<= '0';
			--ID_immediate(31 downto 13)  <=  "FFFFFFFFFFFFFFFFFFF" when ID_instruction(11) = '1' else "0000000000000000000";

			--Registradoress
			ID_rs1 <= ID_instruction(19 downto 15);
			ID_rs2 <= ID_instruction(24 downto 20);
			ID_rd  <= (others => '0');

		-- UJ-type
		when "1101111" =>
			-- Imediato
			ID_immediate(20 downto 1) <= ID_instruction(31) & ID_instruction(19 downto 12) & ID_instruction(20) & ID_instruction(30 downto 21);

			-- Extensao de sinal
			ID_immediate(0)	<= '0';
			ID_immediate(31 downto 20)  <= x"FFF"	when ID_instruction(19) = '1' else x"000";

			--Registrador
			ID_rd <= ID_instruction(11 downto 7);

		-- U-type
		when "0110111" =>
			-- Imediato
			ID_immediate(31 downto 12) <= ID_instruction(31 downto 12);

			-- Extensao de zeros
			ID_immediate(11 downto 0)  <=  x"000";

			-- Registrador
			ID_rd <= ID_instruction(11 downto 7);

		when others =>
    		null;

	end case;

end process;


------------------------------------------------------------------------
-- Registradores Intermediarios ID / EX
------------------------------------------------------------------------

ID_input: process(clock, reset, EX_flush)
begin
	-- Se reset = 1, os dados serão liberados
	if reset = '1' or EX_flush = '1' then
		EX_regWriteControl 	<= '0';
		EX_MemToReg 		<= '0';
		EX_branch 			<= "00";
		EX_memRead 			<= '0';
		EX_memWrite 		<= '0';
		EX_rs1 				<= (others => '0');
		EX_rs2				<= (others => '0');
		EX_rd 				<= (others => '0');
		EX_immediate 		<= (others => '0');
		EX_data1Read 		<= (others => '0');
		EX_data2Read 		<= (others => '0');
		EX_ALUop			<= (others => '0');
		EX_regDst			<= '0';
		EX_ALUsrc 			<= '0';
		EX_PC_4 			<= (others => '0');
		EX_funct3			<= (others => '0');
		EX_funct7			<= (others => '0');

	-- Passa os dados na subida do clock
	elsif RISING_EDGE(clock) then
		EX_regWriteControl 	<= ID_regWriteControl;
		EX_MemToReg 		<= ID_memToReg;
		EX_branch 			<= ID_branch;
		EX_memRead 			<= ID_memRead;
		EX_memWrite 		<= ID_memWrite;
		EX_rs1 				<= ID_rs1;
		EX_rs2				<= ID_rs2;
		EX_rd				<= ID_rd;
		EX_immediate 		<= ID_immediate;
		EX_data1Read		<= ID_data1Read;
		EX_data2Read 		<= ID_data2Read;
		EX_ALUop			<= ID_ALUop;
		EX_regDst			<= ID_RegDst;
		EX_ALUsrc 			<= ID_ALUSrc;
		EX_PC_4 			<= ID_PC_4;
		EX_funct3			<= ID_funct3;
		EX_funct7			<= ID_funct7;

	end if;
end process;


------------------------------------------------------------------------
-- Instanciando a ULA
------------------------------------------------------------------------

ALU_inst: ALU
port map(
	A				=> EX_data1Read,
	B				=> EX_ALU_B_input,
	aluCtrl			=> EX_ALUctrl,
	zero			=> EX_zero,
	result			=> EX_ALUresult
);


------------------------------------------------------------------------
-- Controle da ULA
------------------------------------------------------------------------

ALU_control: process(EX_ALUop, EX_immediate, EX_funct3, EX_funct7)
begin
	case EX_ALUop is
	when "10" =>
		case EX_funct3 is
			when "000" => if (EX_funct7(5) = '1') 
							then EX_ALUctrl <= "0010";
							else EX_ALUctrl <= "0110";
						  end if;

		    when "111" => EX_ALUctrl <= "0000";
			when "110" => EX_ALUctrl <= "0001";
			when "010" => EX_ALUctrl <= "0111";
			when others => null;
		end case;

		-- BEQ
		when "01" =>
			EX_ALUctrl <= "0110";

		-- SW / LW
		when "00" =>
			EX_ALUctrl <= "0010";

		when others =>
			-- Faz nada 
			EX_ALUctrl <= "1111";

	end case;
end process;


------------------------------------------------------------------------
-- Unidade de forwarding
------------------------------------------------------------------------

RAW_manager: process(EX_regWriteControl, EX_rs1, EX_rs2, MEM_regWriteAddr, WB_regWriteAddr)
begin
	if MEM_regWriteControl = '1' and EX_rs1 = MEM_regWriteAddr then
		-- Proxima instrucao quer ler do registrador rs1 antes de ser atualizado
		EX_ALUfwrdA <= "01";
	elsif WB_regWriteControl = '1' and EX_rs1 = WB_regWriteAddr then
		-- Segunda proxima instrucao quer ler do refistrador rs2 antes de ser atualizado
		EX_ALUfwrdA <= "10";
	else EX_ALUfwrdA <= "00";
	end if;

	if MEM_regWriteControl = '1' and EX_rs2 = MEM_regWriteAddr then
		-- Proxima instrucao quer ler do registrador rs2 antes de ser atualizado
		EX_ALUfwrdB <= "01";
	elsif WB_regWriteControl = '1' and EX_rs2 = WB_regWriteAddr then
		-- Segunda proxima instrucao queria ler do registrador rs2 antes de ser atualizado
		EX_ALUfwrdB <= "10";
	else EX_ALUfwrdB <= "00";

	end if;
end process;


------------------------------------------------------------------------
-- Estagio EX
------------------------------------------------------------------------

ALU_A_mux: process(EX_data1Read, EX_ALUfwrdA, MEM_fwrd, WB_regWriteData)
begin
	case EX_ALUfwrdA is

		--no forwarding required
		when "00" =>
			EX_ALU_A_input <= EX_data1Read;
		--RAW risk on consecutive instructions
		when "01" =>
			EX_ALU_A_input <= MEM_fwrd;
		--RAW risk on instructions at distance 2
		when "10" =>
			EX_ALU_A_input <= WB_regWriteData;
		when others =>
			EX_ALU_A_input <= (others => '0');
	end case;
end process;

ALU_B_mux: process(EX_data2Read, EX_ALUfwrdB, MEM_fwrd, WB_regWriteData)
begin
	case EX_ALUfwrdB is

		--no forwarding required
		when "00" =>
			EX_p_ALU_b_input <= EX_data2Read;
		--RAW risk on consecutive instructions
		when "01" =>
			EX_p_ALU_b_input <= MEM_fwrd;
		--RAW risk on instructions at distance 2
		when "10" =>
			EX_p_ALU_b_input <= WB_regWriteData;
		when others =>
			EX_p_ALU_b_input <= (others => '0');
	end case;
end process;

-- MUX que escolhe a entrada B da ULA
EX_ALU_B_input <= EX_p_ALU_B_input when EX_ALUsrc = '0' else EX_immediate;
EX_regWriteAddr <= EX_rd;

------------------------
-- Calculo de endereco do Jump 
EX_branchAddr <= STD_LOGIC_VECTOR(UNSIGNED(EX_immediate(29 downto 0) & "00") + UNSIGNED(EX_PC_4));
------------------------

-- Predicao de branch 
PCSrc: process(EX_branch, IF_flush, EX_PC_4)
begin
	if IF_flush = '1' then
		-- Condicao de branch falhou
    	IF_PCSrc <= "10";
	elsif EX_branch(1) = '1' or EX_branch(0) = '1' then
		-- Branch Preemptivo
    	IF_PCSrc <= "01";
	else
		-- Sem branch
    	IF_PCSrc <= "00";
	end if;
end process;


------------------------------------------------------------------------
-- Registradores Intermediarios EX / MEM 
------------------------------------------------------------------------

EX_input: process(clock, reset, EX_flush)
begin
	if reset = '1' or EX_flush = '1' then
		MEM_ALUresult 			<= (others => '0');
		MEM_MemToReg 			<= '0';
		MEM_branch 				<= "00";
		MEM_data2Read 			<= (others => '0');
		MEM_zero				<= '0';
		MEM_regWriteAddr		<= (others => '0');
		MEM_regWriteControl 	<= '0';
		MEM_memWrite			<= '0';
		MEM_memRead			    <= '0';
	elsif RISING_EDGE(clock) then
		MEM_ALUresult 			<= EX_ALUresult;
		MEM_MemToReg 			<= EX_memToReg;
		MEM_branch 				<= EX_branch;
		MEM_data2Read 			<= EX_p_ALU_B_input;
		MEM_zero				<= EX_zero;
		MEM_regWriteAddr		<= EX_regWriteAddr;
		MEM_regWriteControl 	<= EX_regWriteControl;
		MEM_memWrite			<= EX_memWrite;
		MEM_memRead			    <= EX_memRead;
	end if;
end process;


------------------------------------------------------------------------
-- Estagio MEM
------------------------------------------------------------------------

-- Endereco de destino na memoria de dados
D_Addr <= MEM_ALUresult;

-- Dadis a serem escritos na memoria de dados
D_dataOut <= MEM_data2Read;

-- Sinal de controle de leitura para a memoria de dados
D_rdStb <= MEM_memRead;

-- Sinal de controle de escrita para a memoria de dados
D_wrStb <= MEM_memWrite;

-- Dados recebidos da memoria de dados
MEM_memData <= D_dataIn;

-- Dado do MUX passado para frente
MEM_fwrd <= MEM_ALUresult when MEM_memRead = '0' else MEM_memData;


------------------------------------------------------------------------
-- Gerenciamento de Risco de Controle
------------------------------------------------------------------------

-- Preve a efetividade do Jump
HAZARD_unit: process(MEM_branch, MEM_zero)
begin
	if (MEM_branch(0) = '1' and MEM_zero = '0') or (MEM_branch(1) = '1' and MEM_zero = '1') then
		-- Condicao do branch realizada
		IF_flush <= '0';
		ID_flush <= '1';
		EX_flush <= '1';

	elsif MEM_branch(0) = '1' or MEM_branch(1) = '1' then
		-- Condicao so branch nao foi realizada
		IF_flush <= '1';
		ID_flush <= '0';
		EX_flush <= '0';

	else
		-- Nenhum branch foi realizado
		IF_flush <= '0';
		ID_flush <= '0';
		EX_flush <= '0';

	end if;
end process;


------------------------------------------------------------------------
-- Registradores Intermediarios MEM / WB
------------------------------------------------------------------------

MEM_input: process(clock, reset)
begin
	if reset = '1' then
		WB_ALUresult		 <= (others => '0');
		WB_memToReg          <= '0';
		WB_memData			 <= (others => '0');
		WB_regWriteAddr	     <= (others => '0');
		WB_regWriteControl   <= '0';
	elsif RISING_EDGE(clock) then
		WB_ALUresult		 <= MEM_ALUresult;
		WB_memToReg			 <= MEM_MemToReg;
		WB_memData			 <= MEM_memData;
		WB_regWriteAddr 	 <= MEM_regWriteAddr;
		WB_regWriteControl   <= MEM_regWriteControl;
	end if;
end process;


------------------------------------------------------------------------
-- Estagio WB
------------------------------------------------------------------------

-- MUX que escolhe o dado a ser escrito nos registradores
WB_regWriteData <= WB_memData when WB_memToReg = '1' else WB_ALUresult;

end riscv_arch;