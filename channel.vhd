-- Top level entity for the project
--
-- This module takes the input signal and generates timing information for it. 
-- The timing information is then encoded into a binary signal and sent to the
-- UART module for serial output.
--
-- Inputs:
--   clk: The clock signal
--   signal_in: Trigger signal we want to get timing information on
--
-- Outputs:
--   signal_out: Binary timing information 
--   serial_out: Serial output of the binary timing information     


LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;

ENTITY channel IS
    GENERIC (
        carry4_count : INTEGER :=  64;
        n_output_bits : INTEGER := 10
    );
    PORT (
        clk : IN STD_LOGIC;
        signal_in : IN STD_LOGIC;
        signal_out : OUT STD_LOGIC_VECTOR(n_output_bits - 1 DOWNTO 0)
    );
END ENTITY channel;


ARCHITECTURE rtl OF channel IS

    SIGNAL reset_after_start : STD_LOGIC;
    SIGNAL reset_after_signal : STD_LOGIC;
    SIGNAL busy : STD_LOGIC;
    SIGNAL wr_en : STD_LOGIC;
    SIGNAL therm_code : STD_LOGIC_VECTOR(carry4_count * 4 - 1 DOWNTO 0);
    SIGNAL bin_output : STD_LOGIC_VECTOR(n_output_bits - 1 DOWNTO 0);

    SIGNAL address : STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS => '0');

    SIGNAL parity : STD_LOGIC;
    SIGNAL rounds : STD_LOGIC_VECTOR(7 DOWNTO 0);

    SIGNAL lock_interm : STD_LOGIC;
    SIGNAL rst_chain : STD_LOGIC;

    SIGNAL pll_clock : STD_LOGIC;
    SIGNAL pll_locked : STD_LOGIC;
 
    -- Component declarations

    component pll is
		port (
			refclk   : in  std_logic; -- clk
			rst      : in  std_logic := 'X'; -- reset
            locked   : out std_logic := 'X'; -- locked
			outclk_0 : out std_logic         -- clk
		);
	end component pll;


    --COMPONENT sap IS
    --    PORT (
    --        source : OUT STD_LOGIC_VECTOR(255 DOWNTO 0)
    --    );
    --END COMPONENT sap;


    COMPONENT delay_line IS
        GENERIC (
            stages : POSITIVE
        );
        PORT (
            reset : IN STD_LOGIC;
            lock_interm : IN STD_LOGIC;
            trigger : IN STD_LOGIC;
            clock : IN STD_LOGIC;
            signal_running : IN STD_LOGIC;
            parity : OUT STD_LOGIC;
            rounds : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            therm_code : OUT STD_LOGIC_VECTOR(stages - 1 DOWNTO 0)
        );
    END COMPONENT delay_line;

    COMPONENT encoder IS
        GENERIC (
            n_bits_bin : POSITIVE;
            n_bits_therm : POSITIVE
        );
        PORT (
            clk : IN STD_LOGIC;
            thermometer : IN STD_LOGIC_VECTOR((n_bits_therm - 1) DOWNTO 0);
            parity : IN STD_LOGIC;
            count_bin : OUT STD_LOGIC_VECTOR(n_bits_bin - 1 DOWNTO 0)
        );
    END COMPONENT encoder;

    COMPONENT detect_signal IS
        GENERIC (
            stages : POSITIVE;
            n_output_bits : POSITIVE
        );
        PORT (
            clock : IN STD_LOGIC;
            start : IN STD_LOGIC;
            signal_in : IN STD_LOGIC;
            address : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
            reset : OUT STD_LOGIC;
            wrt : OUT STD_LOGIC
        );
    END COMPONENT detect_signal;


    COMPONENT handle_start IS
        PORT (
            clk : IN STD_LOGIC;
            pll_ready : IN STD_LOGIC;
            starting : OUT STD_LOGIC
        );
    END COMPONENT handle_start;

    component memory
        PORT
        (
            address		: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
            clock		: IN STD_LOGIC  := '1';
            data		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
            wren		: IN STD_LOGIC ;
            q		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
        );
    end component;

    COMPONENT freeze_fsm IS
        PORT (
            clock : IN STD_LOGIC;
            signal_in : IN STD_LOGIC;
            start : IN STD_LOGIC;
            reset : IN STD_LOGIC;
            rst_chain : OUT STD_LOGIC;
            lock_interm : OUT STD_LOGIC;
            signal_running : OUT STD_LOGIC
        );
    END COMPONENT freeze_fsm;

    ATTRIBUTE keep : boolean;
    ATTRIBUTE keep OF bin_output : SIGNAL IS TRUE;


BEGIN

    signal_out <= bin_output;
    --rounds_out <= rounds;
    --data <= bin_output(8 DOWNTO 1);

    --sap_inst : sap
    --PORT MAP(
    --    source => adders
    --);

    pll_inst : pll
    port map (
        refclk => clk,
        rst => reset_after_start,
        locked => pll_locked,
        outclk_0 => pll_clock
    );

    memory_inst : memory
    PORT MAP(
        address => address,
        clock => clk,
        data => rounds(0) & bin_output(7 DOWNTO 1),
        wren => wr_en,
        q => open
    );

    -- send reset signal after start to all components
    handle_start_inst : handle_start
    PORT MAP(
        clk => clk,
        pll_ready => pll_locked,
        starting => reset_after_start
    );

    -- delay line itself
    delay_line_inst : delay_line
    GENERIC MAP(
        stages => carry4_count * 4
    )
    PORT MAP(
        reset => reset_after_signal,
        lock_interm => lock_interm,
        signal_running => busy,
        trigger => signal_in,
        clock => pll_clock,
        parity => parity,
        rounds => rounds,
        therm_code => therm_code
    );
	 
    freeze_fsm_inst : freeze_fsm
    PORT MAP(
        clock => pll_clock,
        signal_in => signal_in,
        start => reset_after_start,
        reset => reset_after_signal,
        rst_chain => rst_chain,
        lock_interm => lock_interm,
        signal_running => busy
    );

    -- logic to detect signal and handle current state of TDC
    detect_signal_inst : detect_signal
    GENERIC MAP(
        stages => carry4_count * 4,
        n_output_bits => n_output_bits
    )
    PORT MAP(
        clock => clk,
        start => reset_after_start,
        signal_in => signal_in,
        reset => reset_after_signal,
        address => address,
        wrt => wr_en
    );
	 
    -- convert thermometer code to binary
    encoder_inst : encoder
    GENERIC MAP(
        n_bits_bin => n_output_bits,
        n_bits_therm => 4 * carry4_count
    )
    PORT MAP(
        clk => clk,
        thermometer => therm_code,
        parity => parity,
        count_bin => bin_output
    );
    --signal_out <= bin_output;
        
END ARCHITECTURE rtl;