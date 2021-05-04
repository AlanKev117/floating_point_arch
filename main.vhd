LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;
USE work.floating_point_unit.ALL;
USE work.accumulator.ALL;
USE work.control_unit.ALL;
USE work.register_file.ALL;
USE work.pc_decoder.ALL;
USE work.instruction_decoder.ALL;
USE work.two_line_decoder.ALL;
USE work.lcd_controller.ALL;

ENTITY main IS
    PORT (
        clk, clr, exe : IN STD_LOGIC;
        instruction : IN STD_LOGIC_VECTOR(13 DOWNTO 0);
        -- ax_out : OUT STD_LOGIC_VECTOR(31 DOWNTO 0); -- se reemplazan por el lcd
        rw, rs, e : OUT STD_LOGIC; --read/write, setup/data, and enable for lcd
        lcd_data : OUT STD_LOGIC_VECTOR(7 DOWNTO 0); --data signals for lcd
        -- pc_out : OUT STD_LOGIC_VECTOR(7 DOWNTO 0); -- se reemplazan por dos displays
        pc1_display, pc2_display : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        inst3, inst2, inst1, inst0 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        flags_out : OUT STD_LOGIC_VECTOR(2 DOWNTO 0)
    );
END main;

ARCHITECTURE arch OF main IS
    SIGNAL pc : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL sig_rf_read_write, sig_rf_bit_mutate, sig_rf_bit_value : STD_LOGIC;
    SIGNAL sig_ac_write_enable, sig_ac_write_octet, sig_ac_sel : STD_LOGIC;
    SIGNAL sig_aluop : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL sig_pc_inc : STD_LOGIC;
    SIGNAL accout_datain : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL op_1, op_2, alu_res, mux_out : STD_LOGIC_VECTOR(31 DOWNTO 0);
BEGIN

    CON : control_unit
    PORT MAP(
        clk => clk,
        exe => exe,
        opcode => instruction(13 DOWNTO 10),
        rf_read_write => sig_rf_read_write,
        rf_bit_mutate => sig_rf_bit_mutate,
        rf_bit_value => sig_rf_bit_value,
        ac_write_enable => sig_ac_write_enable,
        ac_write_octet => sig_ac_write_octet,
        ac_sel => sig_ac_sel,
        aluop => sig_aluop,
        pc_inc => sig_pc_inc);

    RF : register_file
    PORT MAP(
        clk => clk,
        read_write => sig_rf_read_write,
        bit_mutate => sig_rf_bit_mutate,
        bit_value => sig_rf_bit_value,
        bit_pos => instruction(4 DOWNTO 0),
        data_in => accout_datain,
        prime_sel => instruction(9 DOWNTO 8),
        second_sel => instruction(7 DOWNTO 6),
        prime_out => op_1,
        second_out => op_2);

    ALU : floating_point_unit
    PORT MAP(
        aluop => sig_aluop,
        register_1 => op_1,
        register_2 => op_2,
        register_out => alu_res,
        flags => flags_out);

    AX : accumulator
    PORT MAP(
        clk => clk,
        clr => clr,
        write_enable => sig_ac_write_enable,
        write_octet => sig_ac_write_octet,
        part => instruction(9 DOWNTO 8),
        octet_in => instruction(7 DOWNTO 0),
        data_in => mux_out,
        acc_value => accout_datain
    );

    PC : PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            IF clr = '1' THEN
                pc <= (OTHERS => '0');
            ELSIF sig_pc_inc = '1' THEN
                pc <= pc + 1;
            ELSE
            END IF;
        ELSE
        END IF;
    END PROCESS; -- PC

    -- MUX
    mux_out <= op_1 WHEN sig_ac_sel = '1' ELSE
        alu_res;

    -- Outputs
    -- ax_out <= accout_datain;
    -- pc_out <= pc;
    PC_OUT : pc_decoder
    PORT MAP(
        octet => pc,
        left => pc1_display,
        right => pc2_display
    );

    INST_OUT : instruction_decoder
    PORT MAP(
        instruction => instruction(13 DOWNTO 10);
        d3 => inst3,
        d2 => inst2,
        d1 => inst1,
        d0 => inst0
    );

    LCD_LINES : two_line_decoder
    PORT MAP(
        ax_in => accout_datain,
        line1_buffer => line1,
        line2_buffer => line2
    );

    LCD : lcd_controller
    PORT MAP(
        clk => clk;
        reset_n => clr;
        rw => rw,
        rs => rs,
        e => e,
        lcd_data => lcd_data,
        line1_buffer => line1,
        line2_buffer => line2
    );

END ARCHITECTURE; -- arch