LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.float_pkg.ALL;

PACKAGE alu_pkg IS
    PROCEDURE alu_proc (
        SIGNAL aluop : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        SIGNAL reg_1 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        SIGNAL reg_2 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        SIGNAL res : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        SIGNAL flags : OUT STD_LOGIC_VECTOR(4 DOWNTO 0) -- Z, N, I, DEN, NAN
    );

END PACKAGE;

PACKAGE BODY alu_pkg IS

    PROCEDURE alu_proc (
        SIGNAL aluop : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        SIGNAL reg_1 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        SIGNAL reg_2 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        SIGNAL res : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        SIGNAL flags : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
    ) IS
        VARIABLE float_1, float_2, float_out : float(8 DOWNTO -23);
        VARIABLE float_out_class : valid_fpstate;
    BEGIN

        float_1 := to_float(reg_1, 8, 23);
        float_2 := to_float(reg_2, 8, 23);

        -- execute alu operation
        CASE aluop IS

            WHEN "000" =>
                -- add
                float_out := float_1 + float_2;
            WHEN "001" =>
                -- sub
                float_out := float_1 - float_2;
            WHEN "010" =>
                -- mul
                float_out := float_1 * float_2;
            WHEN "011" =>
                -- div
                float_out := float_1 / float_2;
            WHEN "100" =>
                -- and
                float_out := float_1 AND float_2;
            WHEN "101" =>
                -- or
                float_out := float_1 OR float_2;
            WHEN "110" =>
                -- xor
                float_out := float_1 XOR float_2;
            WHEN OTHERS => -- "111"
                -- nop
                NULL;

        END CASE;

        -- float class of output
        float_out_class := classfp(float_out, false);

        -- assign flags values -> flags[4-0]: Z, N, I, DEN, NAN
        CASE float_out_class IS

            WHEN nan => -- Signaling NaN (C FP_NAN)
                flags <= "00001";
            WHEN quiet_nan => -- Quiet NaN (C FP_NAN)
                flags <= "00001";
            WHEN neg_inf => -- Negative infinity (C FP_INFINITE)
                flags <= "01100";
            WHEN neg_normal => -- negative normalized nonzero
                flags <= "01000";
            WHEN neg_denormal => -- negative denormalized (FP_SUBNORMAL)
                flags <= "01010";
            WHEN neg_zero => -- -0 (C FP_ZERO)
                flags <= "11000";
            WHEN pos_zero => -- +0 (C FP_ZERO)
                flags <= "10000";
            WHEN pos_denormal => -- Positive denormalized (FP_SUBNORMAL)
                flags <= "00010";
            WHEN pos_inf => -- positive infinity
                flags <= "00100";
            WHEN OTHERS => -- positive normalized nonzero or isx
                flags <= "00000";

        END CASE;

        res <= to_slv(float_out);

    END alu_proc;

END alu_pkg;