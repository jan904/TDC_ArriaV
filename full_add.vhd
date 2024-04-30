-- Full adder fo two 1 Bit inputs
--
-- This is a full adder that takes two 1 Bit inputs and a carry in and outputs a carry out.
-- The sum is not calculated as we don't need it for the purpose of a delay chain.
--
--Inputs:
--  a, b : 1 Bit inputs
--  Cin : Carry in
--
--Outputs:
--  Cout : Carry out

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY full_add IS
  PORT (
    a : IN STD_LOGIC;
    b : IN STD_LOGIC;
    Cin : IN STD_LOGIC;
    Cout : OUT STD_LOGIC;
    Sum : OUT STD_LOGIC
  );
END ENTITY full_add;

ARCHITECTURE behavioral OF full_add IS

  SIGNAL a_unsigned, b_unsigned, Cin_unsigned : UNSIGNED(0 DOWNTO 0);
  SIGNAL out_unsigned : UNSIGNED(1 DOWNTO 0);

BEGIN

  a_unsigned <= "1" when a = '1' else "0";
  b_unsigned <= "1" when b = '1' else "0";
  Cin_unsigned <= "1" when Cin = '1' else "0";

  out_unsigned <= resize(a_unsigned, 2) + resize(b_unsigned, 2) + resize(Cin_unsigned, 2);

  Sum <= std_logic(std_logic_vector(out_unsigned)(0));
  Cout <= std_logic(std_logic_vector(out_unsigned)(1));
  --Sum <= std_logic_vector(unsigned(a) + unsigned(b) + unsigned(Cin));
  --Sum <= not (Cin XOR ( a XOR b ));
  --Cout <= (a AND b) OR (Cin AND (a XOR b));
  
END ARCHITECTURE behavioral;

