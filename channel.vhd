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
        carry4_count : INTEGER := 32;
        n_output_bits : INTEGER := 8
    );
    PORT (
        clk : IN STD_LOGIC;
        signal_in : IN STD_LOGIC;
        clk_out : OUT STD_LOGIC;
        signal_out : OUT STD_LOGIC_VECTOR(n_output_bits - 1 DOWNTO 0);
        serial_out : OUT STD_LOGIC
    );
END ENTITY channel;
ARCHITECTURE rtl OF channel IS

    SIGNAL reset_after_start : STD_LOGIC;
    SIGNAL reset_after_signal : STD_LOGIC;
    SIGNAL busy : STD_LOGIC;
    SIGNAL wr_en : STD_LOGIC;
    SIGNAL therm_code : STD_LOGIC_VECTOR(carry4_count * 4 - 1 DOWNTO 0);
    SIGNAL detect_edge : STD_LOGIC_VECTOR(carry4_count * 4 - 1 DOWNTO 0);
    SIGNAL bin_output : STD_LOGIC_VECTOR(n_output_bits - 1 DOWNTO 0);

    SIGNAL adders : STD_LOGIC_VECTOR(255 DOWNTO 0) := (OTHERS => '0');

    SIGNAL address : STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS => '0');
 
    -- Component declarations
    COMPONENT sap IS
        PORT (
            source : OUT STD_LOGIC_VECTOR(255 DOWNTO 0)
        );
    END COMPONENT sap;


    COMPONENT delay_line IS
        GENERIC (
            stages : POSITIVE
        );
        PORT (
            reset : IN STD_LOGIC;
            trigger : IN STD_LOGIC;
            clock : IN STD_LOGIC;
            signal_running : IN STD_LOGIC;
            ones : IN STD_LOGIC_VECTOR(stages-1 DOWNTO 0);
            zeros : IN STD_LOGIC_VECTOR(stages-1  DOWNTO 0);
            intermediate_signal : OUT STD_LOGIC_VECTOR(stages - 1 DOWNTO 0);
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
            interm_latch : IN STD_LOGIC_VECTOR(stages - 1 DOWNTO 0);
            signal_out : IN STD_LOGIC_VECTOR(n_output_bits - 1 DOWNTO 0);
            signal_running : OUT STD_LOGIC;
            address : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
            reset : OUT STD_LOGIC;
            wrt : OUT STD_LOGIC
        );
    END COMPONENT detect_signal;

    COMPONENT uart IS
        PORT (
            clk : IN STD_LOGIC;
            rst : IN STD_LOGIC;
            we : IN STD_LOGIC;
            din : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            tx : OUT STD_LOGIC
        );
    END COMPONENT uart;

    COMPONENT handle_start IS
        PORT (
            clk : IN STD_LOGIC;
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

BEGIN

    sap_inst : sap
    PORT MAP(
        source => adders
    );

    memory_inst : memory
    PORT MAP(
        address => address,
        clock => clk,
        data => bin_output,
        wren => wr_en,
        q => open
    );

    clk_out <= clk;

    -- send reset signal after start to all components
    handle_start_inst : handle_start
    PORT MAP(
        clk => clk,
        starting => reset_after_start
    );

    -- delay line itself
    delay_line_inst : delay_line
    GENERIC MAP(
        stages => carry4_count * 4
    )
    PORT MAP(
        reset => reset_after_signal,
        signal_running => busy,
        trigger => signal_in,
        clock => clk,
        zeros => adders(255 DOWNTO 128),
        ones => adders(127 DOWNTO 0),
        intermediate_signal => detect_edge,
        therm_code => therm_code
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
        interm_latch => detect_edge,
        signal_out => bin_output,
        signal_running => busy,
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
        count_bin => bin_output
    );
    signal_out <= bin_output;

    -- send binary output to UART
    uart_inst : uart
    PORT MAP(
        clk => clk,
        rst => reset_after_start,
        we => wr_en,
        din => bin_output,
        tx => serial_out
    );
        
END ARCHITECTURE rtl;