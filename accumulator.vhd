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

    PROCESS (clk)
        VARIABLE high, low : INTEGER;
    BEGIN
        IF rising_edge(clk) THEN
            IF clr = '1' THEN
                acc_register <= (OTHERS => '0');
            ELSIF write_enable = '1' THEN
                IF write_octet = '1' THEN
                    low := conv_integer(part) * 8;
                    high := low + 7;
                    acc_register(high DOWNTO low) <= octet_in;
                ELSE
                    acc_register <= data_in;
                END IF;
            ELSE
            END IF;
        ELSE
        END IF;
    END PROCESS;

    acc_value <= acc_register;

END ARCHITECTURE; -- acc_arch