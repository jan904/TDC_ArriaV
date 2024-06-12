LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY count_rounds IS
    PORT (
        rst : IN STD_LOGIC;
        carry : IN STD_LOGIC;
        parity : OUT STD_LOGIC;
        count : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
    );
END count_rounds;

ARCHITECTURE rtl OF count_rounds IS

    SIGNAL count_reg : INTEGER RANGE 0 TO 10;
    SIGNAL count_read : INTEGER RANGE 0 TO 10;
    SIGNAL parity_reg : STD_LOGIC := '0';
    SIGNAL parity_read : STD_LOGIC := '0';

BEGIN

    PROCESS (rst, carry)
    BEGIN
        IF rst = '1' THEN
            parity_reg <= '0';
            count_reg <= 0;
        ELSE
            IF (count_read mod 2 = 0 and carry = '1') THEN  
                count_reg <= count_read + 1;
                parity_reg <= '1';
            ELSIF (count_read mod 2 = 1 and carry = '0') THEN
                count_reg <= count_read + 1;
                parity_reg <= '0';
            ELSE
                parity_reg <= parity_read;
                count_reg <= count_read;
            END IF;
        END IF;

        count_read <= count_reg;
        count <= STD_LOGIC_VECTOR(to_unsigned(count_reg, count'length));
        parity_read <= parity_reg;
        parity <= parity_reg;

    END PROCESS;

END rtl;