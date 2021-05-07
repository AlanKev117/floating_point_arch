-------------------------------------------------------
-- Johns Hopkins University - FPGA Senior Projects, R.E.Jenkins
--Floating point vhdl Package - Ryan Fay, Alex Hsieh, David Jeang
--This file contains the components and functions used for Floating point arithmetic
---------
--Copywrite Johns Hopkins University ECE department. This software may be freely
-- used and modified as long as this acknowledgement is retained.
--------------------------------------------------------

-- v.1.1

LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;

PACKAGE float_pkg IS
    --------------------
    --convert a signed integer to flt point format
    FUNCTION SIGNED_TO_FP(v : signed) RETURN STD_LOGIC_VECTOR;
    --convert a number in 32-bit flt format to a signed vector of length N
    FUNCTION FP_TO_SIGNED(fp : STD_LOGIC_VECTOR; N : INTEGER) RETURN signed;
    ---------------------
    COMPONENT FPP_MULT IS
        PORT (
            A : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            B : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            clk : IN STD_LOGIC;
            reset : IN STD_LOGIC;
            go : IN STD_LOGIC;
            done : OUT STD_LOGIC;
            overflow : OUT STD_LOGIC;
            result : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
        );
    END COMPONENT;
    -----------------------
    COMPONENT FPP_ADD_SUB IS
        PORT (
            A : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            B : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            clk : IN STD_LOGIC;
            reset : IN STD_LOGIC;
            go : IN STD_LOGIC;
            done : OUT STD_LOGIC;
            result : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
        );
    END COMPONENT;
    -----------------------
    COMPONENT FPP_DIVIDE IS
        PORT (
            A : IN STD_LOGIC_VECTOR(31 DOWNTO 0); --Dividend
            B : IN STD_LOGIC_VECTOR(31 DOWNTO 0); --Divisor
            clk : IN STD_LOGIC; --Master clock
            reset : IN STD_LOGIC; --Global asynch reset
            go : IN STD_LOGIC; --Enable
            done : OUT STD_LOGIC; --Flag for done computing
            overflow : OUT STD_LOGIC; --Flag for overflow
            result : OUT STD_LOGIC_VECTOR(31 DOWNTO 0) --Holds final FP result
        );
    END COMPONENT;
    ------------------------
    COMPONENT MantissaDivision IS
        GENERIC (
            NBIT : INTEGER := 24;
            EBIT : INTEGER := 8);
        PORT (
            clkin : IN STD_LOGIC; --50 mhz expected in
            reset : IN STD_LOGIC; --only needed to initialize state machine 
            start : IN STD_LOGIC; --external start request
            done : OUT STD_LOGIC; --division complete signal out
            as : IN unsigned(NBIT - 1 DOWNTO 0); --aligned  dividend mantissa
            bs : IN unsigned(NBIT - 1 DOWNTO 0); --divisor mantissa
            qs : OUT unsigned(NBIT - 1 DOWNTO 0); -- quotient
            shift : OUT unsigned(EBIT - 1 DOWNTO 0)
        );
    END COMPONENT;
    --------------------------
END PACKAGE float_pkg;

---===========================================
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;

PACKAGE BODY float_pkg IS
    ------------------------
    USE IEEE.std_logic_1164.ALL;
    USE IEEE.numeric_std.ALL;

    FUNCTION SIGNED_TO_FP(v : signed) RETURN STD_LOGIC_VECTOR IS
        --Convert a signed binary integer to 32-bit floating pt sign-magnitude format 
        VARIABLE i : INTEGER RANGE 0 TO v'left + 1;
        VARIABLE j : INTEGER RANGE 0 TO 255;
        VARIABLE fp : STD_LOGIC_VECTOR(31 DOWNTO 0); --returned FP
        VARIABLE exp : INTEGER RANGE -1024 TO 1024; --exponent
        VARIABLE m : unsigned(v'length DOWNTO 0); --mantissa + leading bit

    BEGIN
        m := '0' & unsigned(ABS(v)); --we use the mag of v to create a mantissa
        --start with biased exp equiv to 2**(LENGTH-1), so m becomes the mantissa, m.mmmmm...
        --i.e. mag(v) = 2**(exp-127) * m.m m m m m....
        exp := 127 + m'length - 1;
        --normalize m as the mantissa with one bit in front of the decimal point 
        FOR i IN 0 TO m'left LOOP
            IF m(m'left) = '1' THEN
                j := i;
                EXIT;
            ELSE
                m := m(m'left - 1 DOWNTO 0) & '0';
                --exp:= exp - 1;
            END IF;
        END LOOP;
        exp := exp - j;
        fp(30 DOWNTO 23) := STD_LOGIC_VECTOR(TO_UNSIGNED(exp, 8));
        --Make sure we have enough bits for a normalized full mantissa (23)
        -- and at the same time remove the mantissa leading 1
        IF m'length < 24 THEN -- <24 bits, bottom bits set to 0, and drop the leading 1        
            fp(23 - m'length DOWNTO 0) := (OTHERS => '0');
            fp(22 DOWNTO 24 - m'length) := STD_LOGIC_VECTOR(m(m'length - 2 DOWNTO 0));
        ELSE --if >= 24, drop leading 1 and take next 23 bits for fp
            fp(22 DOWNTO 0) := STD_LOGIC_VECTOR(m(m'length - 2 DOWNTO m'length - 24));
        END IF;

        IF v(v'left) = '1' THEN
            fp(31) := '1';
        ELSE
            fp(31) := '0';
        END IF;
        RETURN fp;
    END FUNCTION SIGNED_TO_FP;
    --------------------------------
    USE IEEE.std_logic_1164.ALL;
    USE IEEE.numeric_std.ALL;
    --Convert a number in std 32-bit flt pt format to a signed binary integer with N bits.
    --NOTE that N must be large enough for the entire truncated result as a signed integer
    --If the number is positive, the result can be typecast into unsigned if desired.
    FUNCTION FP_TO_SIGNED(fp : STD_LOGIC_VECTOR; N : INTEGER) RETURN signed IS
        VARIABLE num : unsigned(N + 1 DOWNTO 0);
        VARIABLE result : signed(N + 1 DOWNTO 0); --returned number
        VARIABLE exp : INTEGER RANGE -1024 TO 1023;
        VARIABLE m : unsigned(24 DOWNTO 0);
    BEGIN
        m := "01" & unsigned(fp(22 DOWNTO 0)); --restore the mantissa leading 1 
        exp := TO_INTEGER(unsigned(fp(30 DOWNTO 23))) - 127; --unbias the exponent
        IF exp < 0 THEN --number less than 1 truncated to 0
            num := (OTHERS => '0');
        ELSIF exp >= N THEN
            num := (OTHERS => '1'); --num greater than 2**N saturates
        ELSE
            num(exp + 1 DOWNTO 0) := m(24 DOWNTO 23 - exp); --effectively multiply m by 2**exp,
            num(N + 1 DOWNTO exp + 2) := (OTHERS => '0'); --  and pad with leading 0's.
        END IF;
        IF fp(31) = '1' THEN
            result := - signed(num);
        ELSE
            result := signed(num);
        END IF;
        RETURN result(N - 1 DOWNTO 0);
    END FUNCTION FP_TO_SIGNED;
    ---------------------------------
END PACKAGE BODY float_pkg;
---================================================

--******************************************************
--Module to Produce a 32-bit floating point product from 2 operands - Ryan Fay
--We presume a mult. request starts the process, and a completion signal is generated.
-- This generally takes 4 clocks to complete, if overflow is checked for.
--******************************************************
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
ENTITY FPP_MULT IS
    PORT (
        A : IN STD_LOGIC_VECTOR(31 DOWNTO 0); --input operands
        B : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        clk : IN STD_LOGIC;
        reset : IN STD_LOGIC;
        go : IN STD_LOGIC;
        done : OUT STD_LOGIC;
        overflow : OUT STD_LOGIC;
        result : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
    );
END FPP_MULT;
-----------------------------------
ARCHITECTURE ARCH OF FPP_MULT IS

    CONSTANT BIAS : unsigned(8 DOWNTO 0) := to_unsigned(127, 9); --exponent bias of 127

    SIGNAL full_mantissa : STD_LOGIC_VECTOR(47 DOWNTO 0);
    SIGNAL full_exp : STD_LOGIC_VECTOR(8 DOWNTO 0); --extra msb for unsigned exponent addition
    SIGNAL R_sign : STD_LOGIC;

    SIGNAL Aop, Bop : STD_LOGIC_VECTOR(31 DOWNTO 0); --latched operands
    ALIAS A_sign : STD_LOGIC IS Aop(31); --operand segments
    ALIAS A_exp : STD_LOGIC_VECTOR(7 DOWNTO 0) IS Aop(30 DOWNTO 23);
    ALIAS A_man : STD_LOGIC_VECTOR(22 DOWNTO 0) IS Aop(22 DOWNTO 0);

    ALIAS B_sign : STD_LOGIC IS Bop(31);
    ALIAS B_exp : STD_LOGIC_VECTOR(7 DOWNTO 0) IS Bop(30 DOWNTO 23);
    ALIAS B_man : STD_LOGIC_VECTOR(22 DOWNTO 0) IS Bop(22 DOWNTO 0);

    -- STATE MACHINE DECLARATION
    TYPE MULT_SM IS (WAITM, MAN_EXP, CHECK, NORMALIZE, PAUSE);
    SIGNAL MULTIPLY : MULT_SM;
    ATTRIBUTE INIT : STRING;
    ATTRIBUTE INIT OF MULTIPLY : SIGNAL IS "WAITM";
    -----------------------------------
BEGIN

    PROCESS (MULTIPLY, clk, go, reset) IS
    BEGIN
        IF (reset = '1') THEN
            full_mantissa <= (OTHERS => '0');
            full_exp <= (OTHERS => '0');
            done <= '0';
            MULTIPLY <= WAITM;
        ELSIF (rising_edge(clk)) THEN
            CASE (MULTIPLY) IS
                WHEN WAITM =>
                    overflow <= '0';
                    done <= '0';
                    IF (go = '1') THEN
                        Aop <= A; --latch input values
                        Bop <= B;
                        MULTIPLY <= MAN_EXP;
                    ELSE
                        MULTIPLY <= WAITM;
                    END IF;
                WHEN MAN_EXP => --compute a sign, exponent and matissa for product
                    R_sign <= A_sign XOR B_sign;
                    full_mantissa <= STD_LOGIC_VECTOR(unsigned('1' & A_man) * unsigned('1' & B_man));
                    --full_exp <= std_logic_vector( (unsigned(A_exp)-BIAS) + (unsigned(B_exp)-BIAS)+ BIAS );
                    full_exp <= STD_LOGIC_VECTOR((unsigned(A_exp) - BIAS) + unsigned(B_exp));
                    --MULTIPLY <= CHECK;
                    MULTIPLY <= NORMALIZE;
                WHEN CHECK => --Check for exponent overflow
                    IF (unsigned(full_exp) > 255) THEN
                        overflow <= '1';
                        result <= (31 => R_sign, OTHERS => '1');
                        done <= '1';
                        MULTIPLY <= PAUSE;
                    ELSE
                        MULTIPLY <= NORMALIZE;
                    END IF;
                WHEN NORMALIZE =>
                    IF full_mantissa(47) = '1' THEN
                        full_mantissa <= '0' & full_mantissa(47 DOWNTO 1);
                        full_exp <= STD_LOGIC_VECTOR(unsigned(full_exp) + 1);
                    ELSE
                        result <= R_sign & full_exp(7 DOWNTO 0) & full_mantissa(45 DOWNTO 23);
                        done <= '1'; --signal that operation completed
                        MULTIPLY <= PAUSE;
                    END IF;
                WHEN PAUSE => -- wait for acknowledgement
                    IF (go = '0') THEN
                        done <= '0';
                        MULTIPLY <= WAITM;
                    END IF;
                WHEN OTHERS =>
                    MULTIPLY <= WAITM;
            END CASE;
        END IF;
    END PROCESS;

END ARCH;
---===============================================================
--Module for a signed floating point add - David Jeang. Thanks to Prof. Jenkins
--We presume an ADD request starts the process, and a completion signal is generated.
--Subtraction is accomplished by negating the B input, before requesting the add.
--The add can easily exceed 15 clocks, depending on the exponent difference
--   and post-normalization.
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
ENTITY FPP_ADD_SUB IS
    PORT (
        A : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        B : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        clk : IN STD_LOGIC;
        reset : IN STD_LOGIC;
        go : IN STD_LOGIC;
        done : OUT STD_LOGIC;
        result : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
    );
END FPP_ADD_SUB;

ARCHITECTURE Arch OF FPP_ADD_SUB IS
    TYPE SMC IS (WAITC, ALIGN, ADDC, NORMC, PAUSEC);
    SIGNAL ADD_SUB : SMC;
    ATTRIBUTE INIT : STRING;
    ATTRIBUTE INIT OF ADD_SUB : SIGNAL IS "WAITC"; --we  powerup in WAITC state

    ---signals latched from inputs
    SIGNAL A_mantissa, B_mantissa : STD_LOGIC_VECTOR (24 DOWNTO 0);
    SIGNAL A_exp, B_exp : STD_LOGIC_VECTOR (8 DOWNTO 0);
    SIGNAL A_sgn, B_sgn : STD_LOGIC;
    --output signals
    SIGNAL sum : STD_LOGIC_VECTOR (31 DOWNTO 0);
    --signal F_exp: std_logic_vector (7 downto 0);
    SIGNAL mantissa_sum : STD_LOGIC_VECTOR (24 DOWNTO 0);

BEGIN

    result <= sum; --sum is built in the state machine
    --State machine to wait for request, latch inputs, align exponents, perform add, normalize result
    SM : PROCESS (clk, reset, ADD_SUB, go) IS
        VARIABLE diff : signed(8 DOWNTO 0);
        --variable j: integer range 0 to 31;
    BEGIN
        IF (reset = '1') THEN
            ADD_SUB <= WAITC; --start in wait state
            done <= '0';
        ELSIF rising_edge(clk) THEN
            CASE ADD_SUB IS
                WHEN WAITC =>
                    IF (go = '1') THEN --wait till start request goes high
                        A_sgn <= A(31);
                        B_sgn <= B(31);
                        A_exp <= '0' & A(30 DOWNTO 23);
                        B_exp <= '0' & B(30 DOWNTO 23);
                        A_mantissa <= "01" & A(22 DOWNTO 0);
                        B_mantissa <= "01" & B(22 DOWNTO 0);
                        ADD_SUB <= ALIGN;
                    ELSE
                        ADD_SUB <= WAITC; --not needed, but clearer
                    END IF;
                WHEN ALIGN => --exponent alignment. Always makes A_exp be final exponent
                    --Below method is like a barrel shift, but is big space hog------
                    --note that if either num is greater by 2**24, we skip the addition.
                    IF unsigned(A_exp) = unsigned(B_exp) THEN
                        ADD_SUB <= ADDC;
                    ELSIF unsigned(A_exp) > unsigned(B_exp) THEN
                        diff := signed(A_exp) - signed(B_exp); --B needs downshifting
                        IF diff > 23 THEN
                            mantissa_sum <= A_mantissa; --B insignificant relative to A
                            sum(31) <= A_sgn;
                            ADD_SUB <= PAUSEC; --go latch A as output
                        ELSE --downshift B to equilabrate B_exp to A_exp
                            B_mantissa(24 - TO_INTEGER(diff) DOWNTO 0) <= B_mantissa(24 DOWNTO TO_INTEGER(diff));
                            B_mantissa(24 DOWNTO 25 - TO_INTEGER(diff)) <= (OTHERS => '0');
                            ADD_SUB <= ADDC;
                        END IF;
                    ELSE --A_exp < B_exp. A needs downshifting
                        diff := signed(B_exp) - signed(A_exp);
                        IF diff > 23 THEN
                            mantissa_sum <= B_mantissa; --A insignificant relative to B
                            sum(31) <= B_sgn;
                            A_exp <= B_exp; --this is just a hack since A_exp is used for final result
                            ADD_SUB <= PAUSEC; --go latch B as output
                        ELSE --downshift A to equilabrate A_exp to B_exp
                            A_exp <= B_exp;
                            A_mantissa(24 - TO_INTEGER(diff) DOWNTO 0) <= A_mantissa(24 DOWNTO TO_INTEGER(diff));
                            A_mantissa(24 DOWNTO 25 - TO_INTEGER(diff)) <= (OTHERS => '0');
                            ADD_SUB <= ADDC;
                        END IF;
                    END IF;
                    ---------------------------------------
                    --This way iterates the alignment shifts, but is way too slow
                    -- If either num is greater by 2**23, we just skip the addition.
                    --                              if (signed(A_exp) - signed(B_exp))> 23 then
                    --                                      mantissa_sum <= std_logic_vector(unsigned(A_mantissa));
                    --                                      sum(31) <= A_sgn;
                    --                                      ADD_SUB <= PAUSEC;  --go latch A as output
                    --                              elsif (signed(B_exp) - signed(A_exp))> 23 then
                    --                                      mantissa_sum <= std_logic_vector(unsigned(B_mantissa));
                    --                                      sum(31) <= B_sgn;
                    --                                      A_exp <= B_exp;
                    --                                      ADD_SUB <= PAUSEC;  --go latch B as output.
                    --                              --otherwise we normalize the smaller exponent to the larger.
                    --                              elsif(unsigned(A_exp) < unsigned(B_exp)) then
                    --                                      A_mantissa <= '0' & A_mantissa(24 downto 1);
                    --                                      A_exp <= std_logic_vector((unsigned(A_exp)+1));
                    --                              elsif (unsigned(B_exp) < unsigned(A_exp)) then
                    --                                      B_mantissa <= '0' & B_mantissa(24 downto 1);
                    --                                      B_exp <= std_logic_vector((unsigned(B_exp)+1));
                    --                              else
                    --                                      --either way, A_exp is the final equilabrated exponent
                    --                                      ADD_SUB <= ADDC;
                    --                              end if;
                    -----------------------------------------
                WHEN ADDC => --Mantissa addition
                    ADD_SUB <= NORMC;
                    IF (A_sgn XOR B_sgn) = '0' THEN --signs are the same. Just add 'em
                        mantissa_sum <= STD_LOGIC_VECTOR((unsigned(A_mantissa) + unsigned(B_mantissa)));
                        sum(31) <= A_sgn; --both nums have same sign
                        --otherwise subtract smaller from larger and use sign of larger
                    ELSIF unsigned(A_mantissa) >= unsigned(B_mantissa) THEN
                        mantissa_sum <= STD_LOGIC_VECTOR((unsigned(A_mantissa) - unsigned(B_mantissa)));
                        sum(31) <= A_sgn;
                    ELSE
                        mantissa_sum <= STD_LOGIC_VECTOR((unsigned(B_mantissa) - unsigned(A_mantissa)));
                        sum(31) <= B_sgn;
                    END IF;

                WHEN NORMC => --post normalization. A_exp is the exponent of the unormalized sum
                    IF unsigned(mantissa_sum) = TO_UNSIGNED(0, 25) THEN
                        mantissa_sum <= (OTHERS => '0'); --break out if a mantissa of 0
                        A_exp <= (OTHERS => '0');
                        ADD_SUB <= PAUSEC; --
                    ELSIF (mantissa_sum(24) = '1') THEN --if sum overflowed we downshift and are done.
                        mantissa_sum <= '0' & mantissa_sum(24 DOWNTO 1); --shift the 1 down
                        A_exp <= STD_LOGIC_VECTOR((unsigned(A_exp) + 1));
                        ADD_SUB <= PAUSEC;
                    ELSIF (mantissa_sum(23) = '0') THEN --in this case we need to upshift
                        --Below takes big resources to determine the normalization upshift, 
                        --  but does it one step.
                        FOR i IN 22 DOWNTO 1 LOOP --find position of the leading 1
                            IF mantissa_sum(i) = '1' THEN
                                mantissa_sum(24 DOWNTO 23 - i) <= mantissa_sum(i + 1 DOWNTO 0);
                                mantissa_sum(22 - i DOWNTO 0) <= (OTHERS => '0'); --size of shift= 23-i
                                A_exp <= STD_LOGIC_VECTOR(unsigned(A_exp) - 23 + i);
                                EXIT;
                            END IF;
                        END LOOP;
                        ADD_SUB <= PAUSEC; --go latch output, wait for acknowledge
                        ------------------------------
                        --This iterates the normalization shifts, thus can take many clocks.
                        --mantissa_sum <= mantissa_sum(23 downto 0) & '0';
                        --A_exp <= std_logic_vector((unsigned(A_exp)-1));
                        --ADD_SUB<= NORMC; --keep shifting till  leading 1 appears
                        ------------------------------
                    ELSE
                        ADD_SUB <= PAUSEC; --leading 1 already there. Latch output, wait for acknowledge
                    END IF;
                WHEN PAUSEC =>
                    sum(22 DOWNTO 0) <= mantissa_sum(22 DOWNTO 0);
                    sum(30 DOWNTO 23) <= A_exp(7 DOWNTO 0);
                    done <= '1'; -- signal done
                    IF (go = '0') THEN --pause till request ends
                        done <= '0';
                        ADD_SUB <= WAITC;
                    END IF;
                WHEN OTHERS => ADD_SUB <= WAITC; --Just in case.
            END CASE;
        END IF;
    END PROCESS SM;

END Arch;
--=================================================================
---*****************************************
-- Floating point divide control module
-- Doanwhey Alexander Hsieh. Special thanks to Prof. Robert E. Jenkins  
--******************************************
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE WORK.float_pkg.ALL;
---Uncomment the following library declaration if instantiating any Xilinx primitives.
---library UNISIM;
---use UNISIM.VComponents.all;

ENTITY FPP_DIVIDE IS
    PORT (
        A : IN STD_LOGIC_VECTOR(31 DOWNTO 0); --Dividend
        B : IN STD_LOGIC_VECTOR(31 DOWNTO 0); --Divisor
        clk : IN STD_LOGIC; --Master clock
        reset : IN STD_LOGIC; --Global asynch reset
        go : IN STD_LOGIC; --Enable
        done : OUT STD_LOGIC; --Flag for done computing
        --ZD:         out std_logic;                                          --Flag for zero divisor
        overflow : OUT STD_LOGIC; --Flag for overflow
        result : OUT STD_LOGIC_VECTOR(31 DOWNTO 0) --Holds final FP result
    );
END FPP_DIVIDE;

ARCHITECTURE Arch OF FPP_DIVIDE IS
    --=======Constants===========
    CONSTANT ZERO_FP : STD_LOGIC_VECTOR(30 DOWNTO 0) := (OTHERS => '0');
    CONSTANT EBIAS : unsigned(8 DOWNTO 0) := to_unsigned(127, 9); --exponent bias
    --=======Floating Point Divide State Machine===
    TYPE FPDiv IS (FPDivIdle, --Waits for GO signal to be set
        FPDivAlign, --Align dividend
        FPDivSetExponent, --Set the quotient exponent
        FPDivStart, --start mantissa divider
        FPDivWaitTilDone, --wait for completion
        FPDivDone, --Done with calculation
        FPDivPause --Wait for GO signal to be cleared
    );
    SIGNAL FPD : FPDiv;
    ATTRIBUTE init : STRING;
    ATTRIBUTE init OF FPD : SIGNAL IS "FPDivIdle";

    --==== Hardware/Registers=====
    SIGNAL Ae : unsigned(8 DOWNTO 0); --Dividend exponent
    SIGNAL Be : unsigned(8 DOWNTO 0); --Divisor exponent
    --Quotient parts 
    SIGNAL Qs : STD_LOGIC;
    SIGNAL Qm : STD_LOGIC_VECTOR(22 DOWNTO 0); --final mantissa with leading 1 gone
    SIGNAL Qe : STD_LOGIC_VECTOR(8 DOWNTO 0);
    --unsigned actual Mantissa of Dividend and Divisor with leading 1 restored 
    SIGNAL rdAm, rdBm : unsigned(23 DOWNTO 0);
    --normalized mantissa Quotient with leading 1
    SIGNAL rdQm : unsigned(23 DOWNTO 0);
    --Required exponent reduction from quotient normalization
    SIGNAL expShift : unsigned(7 DOWNTO 0);
    --===== Clock Signals=====
    SIGNAL fpClk0 : STD_LOGIC := '0';
    SIGNAL fpClk : STD_LOGIC := '0'; --25MHz Clock for DIV state machine
    --=====  Miscellaneous ===
    SIGNAL restoringDivStart : STD_LOGIC;
    SIGNAL restoringDivDone : STD_LOGIC;
    ----------------------------------
BEGIN
    ------------------------------------------
    -- Divided Clock to Drive Floating Point steps
    PROCESS (CLK) IS
    BEGIN
        IF (rising_edge(CLK)) THEN
            fpClk0 <= NOT fpClk0;
        END IF;
    END PROCESS;

    PROCESS (fpClk0) IS
    BEGIN
        IF (rising_edge(fpClk0)) THEN
            fpClk <= NOT fpClk;
        END IF;
    END PROCESS;
    ---------------------------------------
    UDIV : MantissaDivision --instantiate module for mantissa division
    GENERIC MAP(NBIT => 24, EBIT => 8)
    PORT MAP(
        clkin => fpClk,
        reset => reset,
        start => restoringDivStart,
        done => restoringDivDone,
        as => rdAm, --full mantissas with hidden leading 1 restored
        bs => rdBm,
        qs => rdQm,
        shift => expShift
    );
    ---------------------------------------
    -- State Machine for Division Control
    ----------------------------------------
    PROCESS (fpClk, reset) IS --, FPD, GO, A, B
    BEGIN
        IF (reset = '1') THEN
            FPD <= FPDivIdle;
            done <= '0';
            overflow <= '0';
            restoringDivStart <= '0';
        ELSIF (rising_edge(fpClk)) THEN
            CASE FPD IS
                    ------------------------------------
                    -- Wait for GO signal, then begin the FPP division algorithm. 
                    -- If divisor is zero, return all 1's.
                    -- If dividend is zero, return zero. 
                    ------------------------------------
                WHEN FPDivIdle =>
                    restoringDivStart <= '0';
                    done <= '0';
                    IF (go = '1') THEN
                        Qs <= A(31) XOR B(31); --Set sign of quotient
                        IF (B(30 DOWNTO 0) = ZERO_FP) THEN
                            Qm <= (OTHERS => '1'); --Divide by zero, return Max number
                            Qe <= (OTHERS => '1');
                            overflow <= '1'; --we make no distinction on cause of overflow
                            FPD <= FPDivDone; --go to done
                        ELSIF (A(30 DOWNTO 0) = ZERO_FP) THEN
                            Qm <= (OTHERS => '0'); --Zero dividend, return zero
                            Qe <= (OTHERS => '0');
                            FPD <= FPDivDone; --go to done
                        ELSE --initialize internal registers
                            rdAm <= unsigned('1' & A(22 DOWNTO 0)); --Actual normalized mantissas
                            rdBm <= unsigned('1' & B(22 DOWNTO 0));
                            Ae <= unsigned('0' & A(30 DOWNTO 23)); --biased exponents with extra msb
                            Be <= unsigned('0' & B(30 DOWNTO 23));
                            FPD <= FPDivAlign;
                        END IF;
                    ELSE
                        FPD <= FPDivIdle; --continue waiting
                    END IF;
                    ----------
                WHEN FPDivAlign => -- Check mantissas and align if Am greater than Bm
                    FPD <= FPDivSetExponent; --default next state
                    IF rdAm > rdBm THEN
                        rdAm <= '0' & rdAm(23 DOWNTO 1); --downshift to make Am less than Bm
                        --if Ae < 255 then
                        Ae <= Ae + 1;
                        --else 
                        -- Qreg                    <= A(31) & NAN; --Exponent overflow, return NaN
                        -- overflow                <= '1'; --we make no distinction on cause of overflow
                        -- FPD                     <= FPDivDone;  --go to Calculation done
                        --end if;  
                    END IF;
                    ---------
                    --Maybe we should break the exponent subtract into two pieces for speed
                WHEN FPDivSetExponent =>
                    IF Ae > Be THEN
                        Qe <= STD_LOGIC_VECTOR(unsigned(Ae) - unsigned(Be) + EBIAS);
                    ELSE
                        Qe <= STD_LOGIC_VECTOR(EBIAS - (unsigned(Be) - unsigned(Ae)));
                    END IF;
                    FPD <= FPDivStart;
                    -----------  
                WHEN FPDivStart => --Start the mantissa division
                    restoringDivStart <= '1';
                    FPD <= FPDivWaitTilDone; --Wait for mantissa division to complete
                    ----------   
                WHEN FPDivWaitTilDone => --Latch normalized mantissa quotient, and new exponent
                    IF (restoringDivDone = '1') THEN
                        Qe <= STD_LOGIC_VECTOR(unsigned(Qe) - expShift);
                        Qm <= STD_LOGIC_VECTOR(rdQm(22 DOWNTO 0)); --drop the mantissa leading 1
                        FPD <= FPDivDone;
                    END IF;
                    ---------
                WHEN FPDivDone => --Paste together and latch the final result,  signal done.
                    done <= '1';
                    result <= Qs & Qe(7 DOWNTO 0) & Qm;
                    restoringDivStart <= '0';
                    FPD <= FPDivPause;
                    ----------
                WHEN FPDivPause => --Pause for the done signal to be recognized
                    IF (go = '0') THEN --request should reset after done goes high
                        done <= '0';
                        fpd <= FPDivIdle;
                    END IF;
                    ---------            
                WHEN OTHERS => --  Default state is FPDivIdle
                    FPD <= FPDivIdle;
            END CASE;
        END IF;
    END PROCESS;

END Arch;

--***********************************************
--Module to Divide an N-bit unsigned mantissa by an N-bit unsigned mantissa to produce
--an N-bit unsigned, normalized Quotient - Alex Hsieh
--We presume a mantissa divide request starts the state machine, and a completion signal is generated. 
--***********************************************
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;

ENTITY MantissaDivision IS -- XSA board driver usb dram operations.
    GENERIC (
        NBIT : INTEGER := 24;
        EBIT : INTEGER := 8);
    PORT (
        clkin : IN STD_LOGIC; --50 mhz expected in
        reset : IN STD_LOGIC; --only needed to initialize state machine 
        start : IN STD_LOGIC; --external start request
        done : OUT STD_LOGIC; --division complete signal out
        as : IN unsigned(NBIT - 1 DOWNTO 0); --aligned dividend
        bs : IN unsigned(NBIT - 1 DOWNTO 0); --divisor
        qs : OUT unsigned(NBIT - 1 DOWNTO 0); --normalized quotient with leading 1 supressed
        shift : OUT unsigned(EBIT - 1 DOWNTO 0)
    );
END MantissaDivision;

ARCHITECTURE arch OF MantissaDivision IS
    ---state machine signals---
    TYPE SM_type IS (IDLE, NORM, TEST, CHKBO, FINI);
    SIGNAL state : SM_type; --division process state machine
    ATTRIBUTE INIT : STRING;
    ATTRIBUTE INIT OF state : SIGNAL IS "IDLE"; --we powerup in IDLE state
    SIGNAL sm_clk : STD_LOGIC;
    --- registers-------------
    SIGNAL acc : unsigned(NBIT - 1 DOWNTO 0); --accumulated quotient
    SIGNAL numerator, denominator : unsigned(2 * NBIT - 1 DOWNTO 0);
    SIGNAL diff : unsigned(2 * NBIT - 1 DOWNTO 0); --difference between current num. and denom.
    SIGNAL shift_I : unsigned(EBIT - 1 DOWNTO 0); --reduction of final exponent for normalization
    SIGNAL count : INTEGER RANGE 0 TO NBIT; --iteration count.
    --- SR inference----
    ATTRIBUTE shreg_extract : STRING; --Don't infer primitive SR's
    --attribute shreg_extract of acc: signal is "no";               --To avoid reset problems.
    --attribute shreg_extract of numerator: signal is "no"; 

BEGIN
    shift <= shift_I;
    ----- division state machine--------------
    diff <= numerator - denominator;
    sm_clk <= clkin;
    MDIV : PROCESS (sm_clk, reset, state, start, as, bs) IS
    BEGIN
        IF reset = '1' THEN
            state <= IDLE; --reset into the idle state to wait for a memory operation.
            done <= '0';

        ELSIF rising_edge(sm_clk) THEN --
            CASE state IS
                WHEN IDLE => --we remain in idle till we get a start signal.
                    IF start = '1' THEN
                        acc <= (OTHERS => '0');
                        numerator(NBIT - 1 DOWNTO 0) <= as;
                        numerator(2 * NBIT - 1 DOWNTO NBIT) <= (OTHERS => '0');
                        denominator(NBIT - 1 DOWNTO 0) <= bs;
                        denominator(2 * NBIT - 1 DOWNTO NBIT) <= (OTHERS => '0');
                        count <= 0;
                        state <= TEST;
                        done <= '0';
                        shift_I <= (OTHERS => '0');
                    END IF;
                    -------
                WHEN TEST => -- Test, shift, and apply subtraction to numerator if necessary.
                    IF numerator < denominator THEN
                        acc <= acc(NBIT - 2 DOWNTO 0) & '0';
                        numerator <= numerator(2 * NBIT - 2 DOWNTO 0) & '0';
                    ELSE
                        acc <= acc(NBIT - 2 DOWNTO 0) & '1'; --next quotient bit is a 1
                        numerator <= diff(2 * NBIT - 2 DOWNTO 0) & '0'; --diff = numerator - denominator;
                    END IF;
                    state <= CHKBO;
                    --------
                WHEN CHKBO => --check count for breakout. (this conveniently creates a 1-clk delay)
                    IF count < NBIT - 1 THEN
                        count <= count + 1;
                        state <= TEST;
                    ELSE
                        state <= NORM;
                    END IF;
                    ---------
                WHEN NORM => --normalize the 24-bit accumulated quotient
                    IF (acc(NBIT - 1) = '0') THEN
                        acc <= acc(NBIT - 2 DOWNTO 0) & '0';
                        shift_I <= shift_I + 1;
                        state <= NORM;
                    ELSE
                        qs <= acc; --latch normalized quotient for output. Leading bit will be dropped
                        done <= '1';
                        state <= FINI;
                    END IF;
                    ---------
                WHEN FINI => --to avoid a race condition, we wait till start goes off
                    IF start = '0' THEN --this means the upper entity has latched the answer
                        state <= IDLE; --Go wait for next request
                        done <= '0';
                    END IF;
                    ---------  
                WHEN OTHERS => state <= IDLE;
            END CASE;
        END IF;
    END PROCESS MDIV;
    ---------------------------------
END arch;