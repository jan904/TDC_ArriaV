LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY detect_signal IS
    GENERIC (
        stages : INTEGER := 124;
        n_output_bits : INTEGER := 8
    );
    PORT (
        clock : IN STD_LOGIC;
        start : IN STD_LOGIC;
        signal_in : IN STD_LOGIC;
        address : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
        reset : OUT STD_LOGIC;
        wrt : OUT STD_LOGIC
    );
END ENTITY detect_signal;


ARCHITECTURE fsm OF detect_signal IS

    -- Define the states of the FSM
    TYPE stype IS (IDLE, DETECT_START, ENCODE, WRITE_FIFO, ADDRESS_UP, RST);
    SIGNAL state, next_state : stype;

    -- Signals used to store the values of the signals
    SIGNAL reset_reg, reset_next : STD_LOGIC;
    SIGNAL wrt_reg, wrt_next : STD_LOGIC;
    SIGNAL count, count_reg, count_next : INTEGER range 0 to 2;
    SIGNAL wait_counter, wait_counter_next : INTEGER range 0 to 2;
    SIGNAL done_write_reg, done_write_next : STD_LOGIC;
    SIGNAL address_reg, address_next : UNSIGNED(15 DOWNTO 0);


BEGIN
    -- FSM core
    PROCESS(clock)
    BEGIN
        IF rising_edge(clock) THEN
            -- Reset at start 
            IF start = '1' THEN
                state <= IDLE;
                reset_reg <= '0';
                wrt_reg <= '0';
                address_reg <= (OTHERS => '0');
                count <= 0;
                wait_counter <= 0;

            -- Update signals
            ELSE
                reset_reg <= reset_next;
                wrt_reg <= wrt_next;
                state <= next_state;
                address_reg <= address_next;
                count <= count_next;
                wait_counter <= wait_counter_next;
            END IF;
        END IF;
    END PROCESS;

    -- FSM logic
    PROCESS (state, wrt_reg, reset_reg, signal_in, count, wait_counter, address_reg)  
    BEGIN

        -- Default values
        next_state <= state;
        wrt_next <= wrt_reg;
        reset_next <= reset_reg;
        address_next <= address_reg;
        count_next <= count;
        wait_counter_next <= wait_counter;

        CASE state IS
            WHEN IDLE =>
                IF signal_in = '1' THEN
                    next_state <= ENCODE;   
                ELSE
                    next_state <= IDLE;
                END IF;
                
            WHEN ENCODE =>
                --IF wait_counter = 2 THEN
                    wait_counter_next <= 0; 
                    next_state <= WRITE_FIFO;    
                --ELSE
                --    wait_counter_next <= wait_counter + 1;
                --    next_state <= ENCODE;
                --END IF;

            WHEN WRITE_FIFO =>
                IF count = 0 THEN
                    wrt_next <= '1';
                    count_next <= count + 1;
                    next_state <= WRITE_FIFO;
                ELSIF count = 1 then
                    count_next <= 0;
                    wrt_next <= '0';
                    next_state <= ADDRESS_UP;
                ELSE
                    count_next <= count + 1;
                    next_state <= WRITE_FIFO;
                END IF;

            WHEN ADDRESS_UP =>
                address_next <= address_reg + 1;
                next_state <= RST;

            WHEN RST =>
                IF signal_in = '0' or reset_reg = '1' THEN
                    IF reset_reg = '1' THEN
                        IF signal_in = '0' THEN
                            reset_next <= '0';
                            next_state <= IDLE;
                        ELSE
                            reset_next <= '1';
                            next_state <= RST;
                        END IF;
                    ELSE
                        reset_next <= '1';
                        next_state <= RST;
                    END IF;
                ELSE
                    next_state <= RST;
                END IF;
                
            WHEN OTHERS =>
                next_state <= RST;
        END CASE;
    END PROCESS;

    reset <= reset_reg;
    address <= std_logic_vector(address_reg);
    wrt <= wrt_reg;

END ARCHITECTURE fsm;