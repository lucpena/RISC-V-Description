/*

    Simulador uniciclo do RISC-V

    Departamento de Ciencia da Computacao
    Organizacao e Arquitetura de Computadores


    Lucas Araujo Pena - 130056162


*/

library IEEE;
    use IEEE.STD_LOGIC_1164.all; 
    use IEEE.NUMERIC_STD.all;

entity riscv_tb is
-- Vazio
end riscv_tb;
    
architecture riscv_tb_arch of riscv_tb is
    
    -- Declaracao da unidade de testes
    component riscv 
    port(

        clock       : in STD_LOGIC;
        reset       : in STD_LOGIC;

        -- Memoria de Instrucoes
        I_addr      : out STD_LOGIC_VECTOR(31 downto 0);
        I_rdStb     : out STD_LOGIC;
        I_wrStb     : out STD_LOGIC;
        I_dataOut   : out STD_LOGIC_VECTOR(31 downto 0);
        I_dataIn    : in  STD_LOGIC_VECTOR(31 downto 0);

        -- Memoria de Dados
        D_addr      : out STD_LOGIC_VECTOR(31 downto 0);
        D_rdStb     : out STD_LOGIC;
        D_wrStb     : out STD_LOGIC;
        D_dataOut   : out STD_LOGIC_VECTOR(31 downto 0);
        D_dataIn    : in  STD_LOGIC_VECTOR(31 downto 0)
    );
    end component;

    component Memory
    generic(
        
        FILENAME    : string;
        MEM_SIZE    : integer

    );
    port(

        clock       : in  STD_LOGIC;
        addr        : in  STD_LOGIC_VECTOR(31 downto 0);
        rdStb       : in  STD_LOGIC;
        wrStb       : in  STD_LOGIC;
        dataIn      : in  STD_LOGIC_VECTOR(31 downto 0);
        dataOut     : out STD_LOGIC_VECTOR(31 downto 0)

    );

    end component;

    -- Sinais
    signal clock        : STD_LOGIC;
    signal reset        : STD_LOGIC;
    
    -- Sinais da memoria de Instrucao
    signal I_addr       : STD_LOGIC_VECTOR(31 downto 0);
    signal I_rdStb      : STD_LOGIC;
    signal I_wrStb      : STD_LOGIC;
    signal I_dataOut    : STD_LOGIC_VECTOR(31 downto 0);
    signal I_dataIn     : STD_LOGIC_VECTOR(31 downto 0);

    -- Sinais da memoria de dados
    signal D_addr       : STD_LOGIC_VECTOR(31 downto 0);
    signal D_rdStb      : STD_LOGIC;
    signal D_wrStb      : STD_LOGIC;
    signal D_dataIn     : STD_LOGIC_VECTOR(31 downto 0);
    signal D_dataOut    : STD_LOGIC_VECTOR(31 downto 0);

    constant tper_clk   : time :=  50 ns;
    constant tdelay     : time := 150 ns;

begin

    -- Mapeando as portas do RISC V, no Unity Under Test
    UUT: riscv 
    port map(

        clock       => clock,
        reset       => reset,

        --Memoria de Instrucoes
        I_addr      => I_addr,
        I_rdStb     => I_rdStb,
        I_wrStb     => I_wrStb,
        I_dataOut   => I_dataOut,
        I_dataIn    => I_dataIn,

        -- Memoria de dados
        D_addr      => D_addr,
        D_rdStb     => D_rdStb,
        D_wrStb     => D_wrStb,
        D_dataOut   => D_dataOut,
        D_dataIn    => D_dataIn

    );

    -- Mapeando as portas da Memoria
    Instruction_Mem_inst: memory 
    generic map(

        FILENAME    => "program",
        MEM_SIZE    => 1024

    )

    port map(

        clock       => clock,
        addr        => I_addr,
        rdStb       => I_rdStb,
        wrStb       => I_wrStb,
        dataOut     => I_dataOut,
        dataIn      => I_dataIn

    );

    -- Clock
    process
    begin

        clock <= '0';
        wait for tper_clk / 2;
        clock <= '1';
        wait for tper_clk / 2;
    
    end process;

    -- Reset
    process
    begin

        reset <= '1';
        wait for tdelay;
        reset <= '0';
        wait;
    
    end process;
    

end architecture riscv_tb_arch;