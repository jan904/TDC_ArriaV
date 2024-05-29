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
        signal_out : IN STD_LOGIC_VECTOR(n_output_bits - 1 DOWNTO 0);
        address : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
        signal_running : OUT STD_LOGIC;
        reset : OUT STD_LOGIC;
        wrt : OUT STD_LOGIC
    );
END ENTITY detect_signal;


ARCHITECTURE fsm OF detect_signal IS

    -- Define the states of the FSM
    TYPE stype IS (IDLE, DETECT_START, ENCODE, WRITE_FIFO, RST);
    SIGNAL state, next_state : stype;

    -- Signals used to store the values of the signals
    SIGNAL reset_reg, reset_next : STD_LOGIC;
    SIGNAL signal_running_reg, signal_running_next : STD_LOGIC;
    SIGNAL wrt_reg, wrt_next : STD_LOGIC;
    SIGNAL count, count_reg, count_next : INTEGER range 0 to 8;
    SIGNAL start_idle, start_idle_next : STD_LOGIC;
    SIGNAL wait_counter, wait_counter_next : INTEGER range 0 to 12;
    SIGNAL done_write_reg, done_write_next : STD_LOGIC;
    SIGNAL address_reg, address_next : UNSIGNED(15 DOWNTO 0);

    SIGNAL reset_count, reset_count_next : INTEGER range 0 to 24;

BEGIN
    -- FSM core
    PROCESS(clock)
    BEGIN
        IF rising_edge(clock) THEN
            -- Reset at start 
            IF start = '1' THEN
                state <= IDLE;
                signal_running_reg <= '0';
                reset_reg <= '0';
                wrt_reg <= '0';
                address_reg <= (OTHERS => '0');
                count <= 0;
                start_idle <= '0';
                wait_counter <= 0;
                reset_count <= 0;

            -- Update signals
            ELSE
                signal_running_reg <= signal_running_next;
                reset_reg <= reset_next;
                wrt_reg <= wrt_next;
                state <= next_state;
                address_reg <= address_next;
                count <= count_next;
                start_idle <= start_idle_next;
                wait_counter <= wait_counter_next;
                reset_count <= reset_count_next;
            END IF;
        END IF;
    END PROCESS;

    -- FSM logic
    PROCESS (state, signal_running_reg, wrt_reg, reset_reg, signal_out, signal_in, count, wait_counter, start_idle, address_reg, reset_count)  
    BEGIN

        -- Default values
        next_state <= state;
        wrt_next <= wrt_reg;
        reset_next <= reset_reg;
        signal_running_next <= signal_running_reg;
        address_next <= address_reg;
        count_next <= count;
        start_idle_next <= start_idle;
        wait_counter_next <= wait_counter;
        reset_count_next <= reset_count;

        CASE state IS
            WHEN IDLE =>
                IF start_idle = '1' THEN
                    IF signal_in = '1' THEN
                        start_idle_next <= '0';
                        next_state <= DETECT_START;   
                    ELSE
                        next_state <= IDLE;
                    END IF;
                ELSIF signal_in = '0' and start_idle = '0' THEN
                    start_idle_next <= '1';
                    next_state <= IDLE;  
                ELSE
                    next_state <= IDLE;
                END IF;
                
            WHEN DETECT_START =>
                signal_running_next <= '1';
                next_state <= ENCODE;

            WHEN ENCODE =>
                IF wait_counter = 12 THEN
                    wait_counter_next <= 0; 
                    next_state <= WRITE_FIFO;    
                ELSE
                    wait_counter_next <= wait_counter + 1;
                    next_state <= ENCODE;
                END IF;

            WHEN WRITE_FIFO =>
                IF count = 8 THEN
                    wrt_next <= '1';
                    count_next <= count + 1;
                    next_state <= WRITE_FIFO;
                ELSIF count = 12 then
                    count_next <= 0;
                    wrt_next <= '0';
                    next_state <= RST;
                ELSE
                    count_next <= count + 1;
                    next_state <= WRITE_FIFO;
                END IF;

            WHEN RST =>
                IF signal_in = '0' or reset_count > 0 THEN
                    IF reset_count = 20 THEN
                        IF signal_in = '0' THEN
                            reset_count_next <= 0;
                            signal_running_next <= '0';
                            reset_next <= '0';
                            next_state <= IDLE;
                        ELSE
                            reset_count_next <= 20;
                            next_state <= RST;
                        END IF;
                    ELSIF reset_count = 12 THEN
                        reset_count_next <= reset_count + 1;
                        address_next <= address_reg + 1;
                        reset_next <= '1';
                        next_state <= RST;
                    ELSE
                        reset_count_next <= reset_count + 1;
                        next_state <= RST;
                    END IF;
                ELSE
                    next_state <= RST;
                END IF;
                
                
            WHEN OTHERS =>
                next_state <= RST;
        END CASE;
    END PROCESS;

    signal_running <= signal_running_reg;
    reset <= reset_reg;
    address <= std_logic_vector(address_reg);
    wrt <= wrt_reg;

END ARCHITECTURE fsm;