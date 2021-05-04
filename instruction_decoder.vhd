LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY instruction_decoder IS
    PORT (
        instruction : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        d3, d2, d1, d0 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0)
    );
END instruction_decoder;

ARCHITECTURE inst_decoder_arch OF instruction_decoder IS
    FUNCTION bit_to_display(inst_bit : STD_LOGIC) RETURN STD_LOGIC_VECTOR IS
        VARIABLE result : STD_LOGIC_VECTOR(6 DOWNTO 0);
    BEGIN
        CASE inst_bit IS
            WHEN '0' => result := "0000001"; -- "0"     
            WHEN '1' => result := "1001111"; -- "1" 
            WHEN OTHERS => result := "0000000"
        END CASE;
        RETURN result;
    END bit_to_display;
BEGIN
    d3 <= bit_to_display(instruction(3))
    d2 <= bit_to_display(instruction(2))
    d1 <= bit_to_display(instruction(1))
    d0 <= bit_to_display(instruction(0))
END inst_decoder_arch; -- inst_decoder_arch