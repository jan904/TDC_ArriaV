-- Carry4 module consisting of 4 full adders
--
-- The carry-in of the first full adder is connected to the Cin input of the module.
-- Each carry-out of the full adders is connected to the carry-in of the next full adder.
-- The carry-outs are stored asynchonously in the Cout_vector output of the module.
--
-- Inputs: 
--  a, b: 4-bit vectors
--  Cin: carry-in
--
-- Outputs:
--  Cout_vector: 4-bit vector containing the carry-outs of the full adders

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY carry4 IS
    GENERIC (
        stages : INTEGER := 4
    );
    PORT (
        a, b : IN STD_LOGIC_VECTOR(stages-1 DOWNTO 0);
        Cin : IN STD_LOGIC;
        Cout : OUT STD_LOGIC;
        Sum_vector : OUT STD_LOGIC_VECTOR(stages-1 DOWNTO 0)
    );
END ENTITY carry4;

ARCHITECTURE rtl OF carry4 IS

    --SIGNAL carry : STD_LOGIC_VECTOR(4 DOWNTO 0);
    SIGNAL output : STD_LOGIC_VECTOR(1 DOWNTO 0);


    COMPONENT full_add IS
        PORT (
            a : IN STD_LOGIC;
            b : IN STD_LOGIC;
            Cin : IN STD_LOGIC;
            Cout : OUT STD_LOGIC;
            Sum : OUT STD_LOGIC
        );
    END COMPONENT full_add;

    SIGNAL total : STD_LOGIC_VECTOR(stages DOWNTO 0);

BEGIN

    total <= std_logic_vector(resize(unsigned(a),stages+1) + resize(unsigned(b), stages+1) + unsigned'('0'&Cin));
    Sum_vector <= total(stages-1 downto 0);
    Cout <= total(stages);

END ARCHITECTURE rtl;