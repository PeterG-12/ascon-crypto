library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package ascon_package is
    type table5_type is array (0 to 15) of std_logic_vector(63 downto 0); -- Type for Table 5. The constants const_i to derive round constants of the Ascon permutations

    constant TABLE5 : table5_type := (
        x"000000000000003c",
        x"000000000000002d",
        x"000000000000001e",
        x"000000000000000f",
        x"00000000000000f0",
        x"00000000000000e1",
        x"00000000000000d2",
        x"00000000000000c3",
        x"00000000000000b4",
        x"00000000000000a5",
        x"0000000000000096",
        x"0000000000000087",
        x"0000000000000078",
        x"0000000000000069",
        x"000000000000005a",
        x"000000000000004b"
    );


    type sliced_state_type is array (0 to 4) of std_logic_vector(63 downto 0);
    
    constant IV_AEAD : std_logic_vector(63 downto 0) := x"00001000808c0001";
    constant IV_HASH : std_logic_vector(63 downto 0) := x"0000080100cc0002";

end ascon_package;
