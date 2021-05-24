/*

    Simulador uniciclo do RISC-V

    Departamento de Ciencia da Computacao
    Organizacao e Arquitetura de Computadores


    Lucas Araujo Pena - 130056162


*/


library IEEE;
    use IEEE.STD_LOGIC_1164.all;
    use IEEE.NUMERIC_STD.all;
    
entity Registers is port(

	clock     : in STD_LOGIC;
    
    reset     : in STD_LOGIC;
    wControl  : in STD_LOGIC;
    reg1Addr  : in STD_LOGIC_VECTOR (4  downto 0);
    reg2Addr  : in STD_LOGIC_VECTOR (4  downto 0);
    regWrite  : in STD_LOGIC_VECTOR (4  downto 0);
    dataWrite : in STD_LOGIC_VECTOR (31 downto 0);
    
    data1Read : out STD_LOGIC_VECTOR(31 downto 0);
    data2Read : out STD_LOGIC_VECTOR(31 downto 0)

);
end Registers;

architecture Registers_arch of Registers is

	type ram_type is array (31 downto 0) of STD_LOGIC_VECTOR(31 downto 0);
    signal regs : ram_type;
    
	begin
      process(clock, reset)
      begin

          if reset = '1' then
              regs <= (others => x"00000000");
          elsif FALLING_EDGE(clock) then
              if (wControl = '1') then
                  regs(TO_INTEGER(UNSIGNED(regWrite))) <= dataWrite;
              end if;
           end if;

      end process;
    
      data1Read <= regs(TO_INTEGER(UNSIGNED(reg1Addr))) when reg1Addr /= "00000" else (others => '0');

      data2Read <= regs(TO_INTEGER(UNSIGNED(reg2Addr))) when reg2Addr /= "00000" else (others => '0');

end Registers_arch;