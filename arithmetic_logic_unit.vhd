LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE work.alu_pkg.ALL;

ENTITY arithmetic_logic_unit IS
    PORT (
        -- Inputs
        aluop : IN STD_LOGIC_VECTOR(2 DOWNTO 0) -- micro op code for alu
        register_1 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        register_2 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);

        -- Outputs
        register_out : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        flags : OUT STD_LOGIC_VECTOR(4 DOWNTO 0) -- Z, N, I, DEN, NAN

    );
END alu;

ARCHITECTURE alu_arch OF arithmetic_logic_unit IS
BEGIN

    PROCESS (register_1, register_2, aluop) IS
    BEGIN
        alu_proc(aluop, register_1, register_2, register_out, flags);
    END PROCESS;

END ARCHITECTURE; -- alu_arch