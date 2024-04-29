----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    12:15:23 07/27/2017 
-- Design Name: 
-- Module Name:    uart - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

use work.baudPack.all;

entity uart is
        generic (mhz: integer := 12
    );
    PORT(
         clk : IN  std_logic;
         rst : IN  std_logic;
         --re : IN  std_logic;
         we : IN  std_logic;
         --rx : IN  std_logic;
         tx : out  std_logic;
         --addr : IN  std_logic_vector(3 downto 0);
         din : IN  std_logic_vector(7 downto 0)
         --dout : out  std_logic_vector(7 downto 0);
         --irq : OUT  std_logic
        );
end uart;

architecture Behavioral of uart is

	signal rst_n: std_logic;

component BAUDGEN 
    generic (bdDivider: integer := 1);
    port (
        clk: in std_logic;
        rst : in std_logic;
        baudtick: out std_logic
        );
end component;


component fifo
    port (
        clk: in std_logic;
        rst : in std_logic;
        rd: in std_logic;
        wr: in std_logic;
        empty: out std_logic;
        full: out std_logic;
        w_data: in std_logic_vector(7 downto 0);
        r_data: out std_logic_vector(7 downto 0)
    );
end component;

    
component UART_TX
    generic (oversampling: integer := 16);
    port (
        clk: in std_logic;
        resetn : in std_logic;
        b_tick : in std_logic;
        tx : out std_logic;
        tx_start : in std_logic;
        tx_done : out std_logic;
        d_in: in std_logic_vector(7 downto 0)
    );
end component;

	signal baudtick: std_logic;
	signal tx_start: std_logic;
	signal rx_empty, rx_full: std_logic;
	signal tx_empty, tx_full: std_logic;
	signal rx_rd, rx_wr: std_logic;
	signal tx_rd, tx_wr: std_logic;
	signal rx_din, rx_dout: std_logic_vector(7 downto 0);
	signal tx_din, tx_dout: std_logic_vector(7 downto 0);
    

begin

	rst_n <= not rst;

	b: BAUDGEN
	generic map(bdDiv(mhz)) 
	port map(
		clk => clk,
		rst => rst,			
		baudtick => baudtick
	);

	ftx: fifo
	port map(
		clk => clk,
		rst => rst,
		rd => tx_rd,
		wr => we,
		w_data => din,
		r_data => tx_dout,
		empty => tx_empty,
		full => tx_full
	);
    
	tx_start <= not tx_empty;
	utx: UART_TX
	generic map (oversampling => ovSamp(mhz))
    port map(
		clk => clk,
		resetn => rst_n,
        b_tick => baudtick,
	    tx => tx,
	    tx_start => tx_start,
	    tx_done => tx_rd,
	    d_in => tx_dout
    );

end Behavioral;

