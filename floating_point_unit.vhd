LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE work.float_pkg.ALL;

ENTITY float_point_unit IS
    PORT (
        -- Inputs
        clk, clr : IN STD_LOGIC;
        aluop : IN STD_LOGIC_VECTOR(2 DOWNTO 0); -- micro op code for alu
        register_1 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        register_2 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);

        -- Outputs
        register_out : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        flags : OUT STD_LOGIC_VECTOR(2 DOWNTO 0) -- Z, N, OV

    );
END float_point_unit;

ARCHITECTURE fpu_arch OF float_point_unit IS
    TYPE step IS (quiet, await, binary_flags);
    SIGNAL state : step;
    SIGNAL go_add, go_mul, go_div : STD_LOGIC;
    SIGNAL done_add, done_mul, done_div : STD_LOGIC;
    SIGNAL add_res, mul_res, div_res : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL ov_mul, ov_div : STD_LOGIC;
    SIGNAL second_sign : STD_LOGIC;
BEGIN

    SIGN : PROCESS (aluop)
    BEGIN
        IF aluop = "001" THEN
            second_sign <= NOT register_1(31);
        ELSE
            second_sign <= register_1(31);
        END IF;
    END PROCESS;

    MULT : FPP_MULT
    PORT MAP(
        A => register_1,
        B => register_2,
        clk => clk,
        reset => clr,
        go => go_mul,
        done => done_mul,
        overflow => ov_mul,
        result => mul_res
    );

    DIVIDE : FPP_DIVIDE
    PORT MAP(
        A => register_1,
        B => register_2,
        clk => clk,
        reset => clr,
        go => go_div,
        done => done_div,
        overflow => ov_div,
        result => div_res
    );

    ADD_SUB : FPP_ADD_SUB
    PORT MAP(
        A => register_1,
        B => second_sign & register_2(30 downto 0),
        clk => clk,
        reset => clr,
        go => go_add,
        done => done_add,
        result => add_res
    );

    PROCESS (clk, register_1, register_2, aluop)
    BEGIN
        IF clr = '1' THEN
            state <= quiet;
            go_add <= '0';
            go_mul <= '0';
            go_div <= '0';
        ELSIF rising_edge(clk) THEN
            CASE state IS
                WHEN quiet =>
                    CASE aluop IS
                        WHEN "000" =>
                            go_add <= '1';
                            state <= await;
                        WHEN "001" =>
                            go_add <= '1';
                            state <= await;
                        WHEN "010" =>
                            go_mul <= '1';
                            state <= await;
                        WHEN "011" =>
                            go_div <= '1';
                            state <= await;
                        WHEN "100" =>
                            register_out <= register_1 AND register_2;
                            state <= binary_flags;
                        WHEN "101" =>
                            register_out <= register_1 OR register_2;
                            state <= binary_flags;
                        WHEN "110" =>
                            register_out <= register_1 XOR register_2;
                            state <= binary_flags;
                        WHEN OTHERS => NULL;
                    END CASE;
                WHEN await =>
                    IF go_add = '1' THEN
                        IF done_add = '1' THEN
                            go_add = '0';
                            register_out <= add_res;
                            flags(2) <= '1' WHEN add_res(30 DOWNTO 0) = "000" & x"0000000" ELSE
                            '0';
                            flags(1) <= add_res(31);
                            flags(0) <= '0';
                            state <= quiet;
                        END IF;
                    ELSIF go_mul = '1' THEN
                        IF done_mul = '1' THEN
                            go_mul = '0';
                            register_out <= mul_res;
                            flags(2) <= '1' WHEN mul_res(30 DOWNTO 0) = "000" & x"0000000" ELSE
                            '0';
                            flags(1) <= mul_res(31);
                            flags(0) <= ov_mul;
                            state <= quiet;
                        END IF;
                    ELSIF go_div = '1' THEN
                        IF done_div = '1' THEN
                            go_div = '0';
                            register_out <= div_res;
                            flags(2) <= '1' WHEN div_res(30 DOWNTO 0) = "000" & x"0000000" ELSE
                            '0';
                            flags(1) <= div_res(31);
                            flags(0) <= ov_div;
                            state <= quiet;
                        END IF;
                    END IF;
                WHEN binary_flags =>
                    flags(2) <= '1' WHEN register_out(30 DOWNTO 0) = "000" & x"0000000" ELSE
                    '0';
                    flags(1) <= register_out(31);
                    flags(0) <= '0';
                    state <= quiet;
            END CASE;
        END IF;
    END PROCESS;

END ARCHITECTURE; -- fpu_arch