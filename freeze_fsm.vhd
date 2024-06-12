LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY freeze_fsm IS
    PORT (
        clock : IN STD_LOGIC;
        signal_in : IN STD_LOGIC;
        start : IN STD_LOGIC;
        reset : IN STD_LOGIC;
        rst_chain : OUT STD_LOGIC;
        lock_interm : OUT STD_LOGIC;
        signal_running : OUT STD_LOGIC
    );
END ENTITY freeze_fsm;

ARCHITECTURE behavior OF freeze_fsm IS

    TYPE state_type IS (SYNC, IDLE, PROPAGATE, RUNNING);
    SIGNAL state, state_next : state_type;

    SIGNAL signal_running_reg, signal_running_next : STD_LOGIC;
    SIGNAL lock_interm_reg, lock_interm_next : STD_LOGIC;
    SIGNAL rst_chain_reg, rst_chain_next : STD_LOGIC;
    SIGNAL count, count_next : INTEGER range 0 to 1;
    SIGNAL wait_idle, wait_idle_next : INTEGER range 0 to 3;

BEGIN
    
    PROCESS (clock)
    BEGIN
        IF rising_edge(clock) THEN
            IF start = '1' THEN
                state <= SYNC;
                signal_running_reg <= '0';
                lock_interm_reg <= '0';
                count <= 0;
                wait_idle <= 0;
                rst_chain_reg <= '0';
            ELSE
                state <= state_next;
                lock_interm_reg <= lock_interm_next;
                signal_running_reg <= signal_running_next;
                count <= count_next;
                wait_idle <= wait_idle_next;
                rst_chain_reg <= rst_chain_next;
            END IF;
        END IF;
    END PROCESS;

    PROCESS (state, signal_in, signal_running_reg, lock_interm_reg, reset, count, wait_idle, rst_chain_reg)
    BEGIN

        state_next <= state;
        signal_running_next <= signal_running_reg;
        lock_interm_next <= lock_interm_reg;
        count_next <= count;
        rst_chain_next <= rst_chain_reg;
        wait_idle_next <= wait_idle;

        CASE state IS

            WHEN SYNC =>
                IF wait_idle = 3 THEN
                    state_next <= IDLE;
                ELSE
                    wait_idle_next <= wait_idle + 1;
                    rst_chain_next <= '0';
                    state_next <= SYNC;
                END IF;
                
            WHEN IDLE =>
                IF signal_in = '1' THEN
                    lock_interm_next <= '1';
                    state_next <= RUNNING;
                ELSE
                    state_next <= IDLE;
                END IF;

            WHEN PROPAGATE =>
                IF count = 1 THEN
                    count_next <= 0;
                    state_next <= RUNNING;
                ELSE
                    count_next <= count + 1;
                    state_next <= PROPAGATE;
                END IF;

            WHEN RUNNING =>
                IF reset = '1' THEN
                    lock_interm_next <= '0';
                    rst_chain_next <= '1';
                    signal_running_next <= '0';
                    state_next <= SYNC;
                ELSE
                    signal_running_next <= '1';
                    state_next <= RUNNING;
                END IF;
        END CASE;
    END PROCESS;

    lock_interm <= lock_interm_reg;
    signal_running <= signal_running_reg;
    rst_chain <= rst_chain_reg;

    END ARCHITECTURE behavior;