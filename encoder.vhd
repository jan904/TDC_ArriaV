
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

    SIGNAL first : unsigned(n_bits_bin - 1 DOWNTO 0);
    SIGNAL second : unsigned(n_bits_bin - 1 DOWNTO 0);

BEGIN

    PROCESS (clk)
        -- Variable to store the count
        VARIABLE count : unsigned(n_bits_bin - 1 DOWNTO 0); --:= (OTHERS => '0');
        VARIABLE zeros : INTEGER := 0;
    BEGIN
        count := (OTHERS => '0');
        finished_count <= '1';
        -- Simply loop over the thermometer code and count the number of '1's
        IF rising_edge(clk) THEN    
            --IF start_count = '1' THEN 
                FOR i IN 0 TO 255 LOOP
                    IF thermometer(i) = '1' THEN
                        count := count + 1;
                    END IF;
                END LOOP;
                first <= count;
        END IF;
    END PROCESS;

    PROCESS (clk)
    -- Variable to store the count
        VARIABLE count : unsigned(n_bits_bin - 1 DOWNTO 0); --:= (OTHERS => '0');
    
    BEGIN
        count := (OTHERS => '0');
        -- Simply loop over the thermometer code and count the number of '1's
        IF rising_edge(clk) THEN    
            --IF start_count = '1' THEN 
                FOR i IN 256 TO 511 LOOP
                    IF thermometer(i) = '1' THEN
                        count := count + 1;
                    END IF;
                END LOOP;
                second <= count;
        END IF;
    END PROCESS;

    PROCESS(clk)
    BEGIN
        IF rising_edge(clk) THEN
            count_bin <= STD_LOGIC_VECTOR(first + second);
        END IF;
    END PROCESS;

END ARCHITECTURE rtl;