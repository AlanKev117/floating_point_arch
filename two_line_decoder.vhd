LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY two_line_decoder IS
    PORT (
        ax_in : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        line1_buffer : OUT STD_LOGIC_VECTOR(127 DOWNTO 0); -- Data for the top line of the LCD
        line2_buffer : OUT STD_LOGIC_VECTOR(127 DOWNTO 0)); -- Data for the bottom line of the LCD
END two_line_decoder;

ARCHITECTURE decoder_arch OF two_line_decoder IS
    -- format chars
    CONSTANT char_x : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"58";
    CONSTANT char_colon : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"3a";
    CONSTANT char_space : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"20";
    -- hex chars
    CONSTANT char_0 : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"30";
    CONSTANT char_1 : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"31";
    CONSTANT char_2 : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"32";
    CONSTANT char_3 : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"33";
    CONSTANT char_4 : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"34";
    CONSTANT char_5 : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"35";
    CONSTANT char_6 : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"36";
    CONSTANT char_7 : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"37";
    CONSTANT char_8 : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"38";
    CONSTANT char_9 : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"39";
    CONSTANT char_a : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"41";
    CONSTANT char_b : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"42";
    CONSTANT char_c : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"43";
    CONSTANT char_d : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"44";
    CONSTANT char_e : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"45";
    CONSTANT char_f : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"46";

    FUNCTION nibble_to_char(
        nibble : STD_LOGIC_VECTOR(3 DOWNTO 0)
    ) RETURN STD_LOGIC_VECTOR IS
        VARIABLE result : STD_LOGIC_VECTOR(7 DOWNTO 0);
    BEGIN
        CASE nibble IS
            WHEN x"0" => result := char_0;
            WHEN x"1" => result := char_1;
            WHEN x"2" => result := char_2;
            WHEN x"3" => result := char_3;
            WHEN x"4" => result := char_4;
            WHEN x"5" => result := char_5;
            WHEN x"6" => result := char_6;
            WHEN x"7" => result := char_7;
            WHEN x"8" => result := char_8;
            WHEN x"9" => result := char_9;
            WHEN x"a" => result := char_a;
            WHEN x"b" => result := char_b;
            WHEN x"c" => result := char_c;
            WHEN x"d" => result := char_d;
            WHEN x"e" => result := char_e;
            WHEN x"f" => result := char_f;
            WHEN OTHERS => result := x"00";
        END CASE;
        RETURN result;
    END nibble_to_char;

BEGIN
    
    line1_buffer <= char_a & char_x & char_colon & char_space & nibble_to_char(ax_in(31 DOWNTO 28)) & nibble_to_char(ax_in(27 DOWNTO 24)) & nibble_to_char(ax_in(23 DOWNTO 20)) & nibble_to_char(ax_in(19 DOWNTO 16)) & nibble_to_char(ax_in(15 DOWNTO 12)) & nibble_to_char(ax_in(11 DOWNTO 8) & nibble_to_char(ax_in(7 DOWNTO 4)) & nibble_to_char(ax_in(3 DOWNTO 0)) & x"00000000";
    line2_buffer <= x"00000000000000000000000000000000";
END decoder_arch; -- decoder_arch