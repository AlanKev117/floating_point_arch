--          INSTITUTO POLITECNICO NACIONAL 
--           Escuela Superior de Cómputo
--           Arquitectura de Computadoras
--
--           Jimenez Vargas Carlos Alexis
--                Ramos Gómez Elisa
--         Santillan Zaragoza Erick Ignacio
--
--     Practica 2 Arquitectura RISK de 8 bits

-- Version 1.1
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;

ENTITY register_file IS
    PORT (
        clk, read_write, bit_mutate, bit_value : IN STD_LOGIC;
        bit_pos : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
        data_in : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        prime_sel, second_sel : IN STD_LOGIC_VECTOR(1 DOWNTO 0); -- addresses
        prime_out, second_out : OUT STD_LOGIC_VECTOR(31 DOWNTO 0) -- data out
    );
END register_file;

ARCHITECTURE register_arch OF register_file IS
    TYPE reg_array IS ARRAY (0 TO 3) OF STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL registers : reg_array;
BEGIN

    PROCESS (clk) IS
    BEGIN
        IF rising_edge(clk) THEN
            IF bit_mutate = '1' THEN -- mutate bit value from register
                registers(conv_integer(unsigned(prime_sel)))(conv_integer(unsigned(bit_pos))) <= bit_value;
            ELSIF read_write = '1' THEN -- write 32 bit value to register
                registers(conv_integer(unsigned(prime_sel))) <= data_in;
            ELSE -- read two registers
                prime_out <= registers(conv_integer(unsigned(prime_sel)));
                second_out <= registers(conv_integer(unsigned(second_sel)));
            END IF;
        ELSE
        END IF;
    END PROCESS;

END ARCHITECTURE; -- register_arch