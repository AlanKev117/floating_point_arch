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

ENTITY accumulator IS
    PORT (
        clk, clr, write_enable, write_octet : IN STD_LOGIC;
        part : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        octet_in : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        data_in : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        acc_value : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
    );
END accumulator;

ARCHITECTURE acc_arch OF accumulator IS
    SIGNAL acc_register : STD_LOGIC_VECTOR(31 DOWNTO 0);
BEGIN

    PROCESS (clk, clr)
    BEGIN
        IF clr = '0' THEN
            acc_register <= x"00000000";
        ELSIF rising_edge(clk) THEN
            IF write_enable = '1' THEN
                IF write_octet = '1' THEN
                    acc_register(((conv_integer(unsigned(part)) + 1) * 8 - 1) DOWNTO conv_integer(unsigned(part)) * 8) <= octet_in;
                ELSE
                    acc_register <= data_in;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    acc_value <= acc_register;

END ARCHITECTURE; -- acc_arch