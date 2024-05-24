
-- Thermometer to binary encoder
--
-- Inputs:
--   thermometer: Thermometer code to be encoded
--   clk : Clock signal
--
-- Outputs:
--   count_bin: Binary encoded thermometer code   

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY encoder IS
    GENERIC (
        n_bits_bin : POSITIVE;
        n_bits_therm : POSITIVE
    );
    PORT (
        clk : IN STD_LOGIC;
        start_count : IN STD_LOGIC;
        thermometer : IN STD_LOGIC_VECTOR((n_bits_therm - 1) DOWNTO 0);
        finished_count : OUT STD_LOGIC;
        count_bin : OUT STD_LOGIC_VECTOR((n_bits_bin - 1) DOWNTO 0)
    );
END ENTITY encoder;


ARCHITECTURE rtl OF encoder IS

BEGIN

    PROCESS (clk)
        -- Variable to store the count
        VARIABLE count : unsigned(n_bits_bin - 1 DOWNTO 0); --:= (OTHERS => '0');
        VARIABLE pos : INTEGER := 0;
        VARIABLE found : BOOLEAN := FALSE;

    BEGIN
        count := (OTHERS => '0');
        finished_count <= '1';
        -- Simply loop over the thermometer code and count the number of '1's
        IF rising_edge(clk) THEN    
            --IF start_count = '1' THEN 
            FOR i IN 0 TO 511 LOOP
                IF found = FALSE THEN
                    pos := 511 - i;
                    IF thermometer(pos) = '1' THEN
                        count := to_unsigned(pos, count'LENGTH);
                        found := TRUE;
                    END IF;
                END IF;
            END LOOP;
            count_bin <= std_logic_vector(count);
        END IF;
    END PROCESS;
    
END ARCHITECTURE rtl;