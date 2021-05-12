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

ENTITY pc_decoder IS
    PORT (
        octet : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        left, right : OUT STD_LOGIC_VECTOR(6 DOWNTO 0)
    );
END pc_decoder;

ARCHITECTURE display_dec_arch OF pc_decoder IS

    FUNCTION nibble_to_display(
        nibble : STD_LOGIC_VECTOR(3 DOWNTO 0)
    ) RETURN STD_LOGIC_VECTOR IS
        VARIABLE result : STD_LOGIC_VECTOR(6 DOWNTO 0);
    BEGIN
        CASE nibble IS
            WHEN x"0" => result := "0000001"; -- "0"     
            WHEN x"1" => result := "1001111"; -- "1" 
            WHEN x"2" => result := "0010010"; -- "2" 
            WHEN x"3" => result := "0000110"; -- "3" 
            WHEN x"4" => result := "1001100"; -- "4" 
            WHEN x"5" => result := "0100100"; -- "5" 
            WHEN x"6" => result := "0100000"; -- "6" 
            WHEN x"7" => result := "0001111"; -- "7" 
            WHEN x"8" => result := "0000000"; -- "8"     
            WHEN x"9" => result := "0000100"; -- "9" 
            WHEN x"a" => result := "0000010"; -- a
            WHEN x"b" => result := "1100000"; -- b
            WHEN x"c" => result := "0110001"; -- C
            WHEN x"d" => result := "1000010"; -- d
            WHEN x"e" => result := "0110000"; -- E
            WHEN x"f" => result := "0111000"; -- F
            WHEN others => result := "1111111"; -- turn off
        END CASE;
        RETURN result;
    END nibble_to_display;

BEGIN
    left <= nibble_to_display(octet(7 DOWNTO 4));
    right <= nibble_to_display(octet(3 DOWNTO 0));
END display_dec_arch; -- display_dec_arch