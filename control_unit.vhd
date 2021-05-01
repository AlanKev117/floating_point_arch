LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;

ENTITY control_unit IS
    PORT (
        clk, exe : IN STD_LOGIC;
        opcode : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        -- register file control bits
        rf_read_write, rf_bit_mutate, rf_bit_value : OUT STD_LOGIC;
        -- accumulator control bits
        ac_write_enable, ac_write_octet, ac_sel : OUT STD_LOGIC;
        -- alu opcode
        aluop : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        -- prime counter inc.
        pc_inc : OUT STD_LOGIC
    );
END control_unit;

ARCHITECTURE con_arch OF control_unit IS
BEGIN

    PROCESS (clk) IS
    BEGIN
        IF rising_edge(clk) THEN
            IF exe = '1' THEN
                CASE opcode IS

                    WHEN "0000" => -- load byte to ax
                        aluop <= "111";
                        ac_write_enable <= '1';
                        ac_write_octet <= '1';
                        ac_sel <= '0';
                        rf_bit_mutate <= '0';
                        rf_bit_value <= '0';
                        rf_read_write <= '0';
                    WHEN "0001" => -- load ax to register
                        aluop <= "111";
                        ac_write_enable <= '1';
                        ac_write_octet <= '0';
                        ac_sel <= '0';
                        rf_bit_mutate <= '0';
                        rf_bit_value <= '0';
                        rf_read_write <= '1';
                    WHEN "0010" => -- load register to ax
                        aluop <= "111";
                        ac_write_enable <= '0';
                        ac_write_octet <= '0';
                        ac_sel <= '1';
                        rf_bit_mutate <= '0';
                        rf_bit_value <= '0';
                        rf_read_write <= '0';
                    WHEN "0011" => -- add two registers and save to ax
                        aluop <= "000";
                        ac_write_enable <= '1';
                        ac_write_octet <= '0';
                        ac_sel <= '0';
                        rf_bit_mutate <= '0';
                        rf_bit_value <= '0';
                        rf_read_write <= '0';
                    WHEN "0100" => -- subtract two registers and save to ax
                        aluop <= "001";
                        ac_write_enable <= '1';
                        ac_write_octet <= '0';
                        ac_sel <= '0';
                        rf_bit_mutate <= '0';
                        rf_bit_value <= '0';
                        rf_read_write <= '0';
                    WHEN "0101" => -- multiply two registers and save to ax
                        aluop <= "010";
                        ac_write_enable <= '1';
                        ac_write_octet <= '0';
                        ac_sel <= '0';
                        rf_bit_mutate <= '0';
                        rf_bit_value <= '0';
                        rf_read_write <= '0';
                    WHEN "0110" => -- divide two registers and save to ax
                        aluop <= "011";
                        ac_write_enable <= '1';
                        ac_write_octet <= '0';
                        ac_sel <= '0';
                        rf_bit_mutate <= '0';
                        rf_bit_value <= '0';
                        rf_read_write <= '0';
                    WHEN "0111" => -- and between two registers and save to ax
                        aluop <= "100";
                        ac_write_enable <= '1';
                        ac_write_octet <= '0';
                        ac_sel <= '0';
                        rf_bit_mutate <= '0';
                        rf_bit_value <= '0';
                        rf_read_write <= '0';
                    WHEN "1000" => -- or between two registers and save to ax
                        aluop <= "101";
                        ac_write_enable <= '1';
                        ac_write_octet <= '0';
                        ac_sel <= '0';
                        rf_bit_mutate <= '0';
                        rf_bit_value <= '0';
                        rf_read_write <= '0';
                    WHEN "1001" => -- xor between two registers and save to ax
                        aluop <= "110";
                        ac_write_enable <= '1';
                        ac_write_octet <= '0';
                        ac_sel <= '0';
                        rf_bit_mutate <= '0';
                        rf_bit_value <= '0';
                        rf_read_write <= '0';
                    WHEN "1010" => -- set bit to register
                        aluop <= "111"; -- no op. for alu
                        ac_write_enable <= '0';
                        ac_write_octet <= '0';
                        ac_sel <= '0';
                        rf_bit_mutate <= '1';
                        rf_bit_value <= '1';
                        rf_read_write <= '0';
                    WHEN "1011" => -- clear bit to register
                        aluop <= "111"; -- no op. for alu
                        ac_write_enable <= '0';
                        ac_write_octet <= '0';
                        ac_sel <= '0';
                        rf_bit_mutate <= '1';
                        rf_bit_value <= '0';
                        rf_read_write <= '0';
                    WHEN OTHERS => NULL;

                END CASE;
                pc_inc <= '1';
            ELSE
                aluop <= "111"; -- no op. for alu
                ac_write_enable <= '0';
                ac_write_octet <= '0';
                ac_sel <= '0';
                rf_bit_mutate <= '0';
                rf_bit_value <= '0';
                rf_read_write <= '0';
                pc_inc <= '0';
            END IF;
        ELSE
        END IF;
    END PROCESS;

END ARCHITECTURE; -- con_arch