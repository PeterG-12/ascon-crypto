library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library work;
use work.ascon_package.ALL;

entity ascon_linear_layer is
    port(state_i : in std_logic_vector(319 downto 0);
        state_o : out std_logic_vector(319 downto 0)
    );
end ascon_linear_layer;

architecture Behavioral of ascon_linear_layer is
signal sliced_state : sliced_state_type;
signal sliced_out_state : sliced_state_type;

function rotr64 (x : std_logic_vector(63 downto 0); n : integer) return std_logic_vector is
    begin
    return x(n - 1 downto 0) & x(63 downto n);
end function;

begin

    -- Slice the state in
    process(state_i)
    begin
        for i in 0 to 4 loop
            sliced_state(4 - i) <= state_i(64 * i + 63 downto 64 * i + 0); -- Extract 64-bit words
        end loop;
    end process;

    sliced_out_state(0) <= sliced_state(0) xor rotr64(sliced_state(0), 19) xor rotr64(sliced_state(0), 28);
    sliced_out_state(1) <= sliced_state(1) xor rotr64(sliced_state(1), 61) xor rotr64(sliced_state(1), 39);
    sliced_out_state(2) <= sliced_state(2) xor rotr64(sliced_state(2),  1) xor rotr64(sliced_state(2),  6);
    sliced_out_state(3) <= sliced_state(3) xor rotr64(sliced_state(3), 10) xor rotr64(sliced_state(3), 17);
    sliced_out_state(4) <= sliced_state(4) xor rotr64(sliced_state(4),  7) xor rotr64(sliced_state(4), 41);

    --state_o <= sliced_out_state(4) & sliced_out_state(3) & sliced_out_state(2) & sliced_out_state(1) & sliced_out_state(0);

    state_o <= sliced_out_state(0) & sliced_out_state(1) & sliced_out_state(2) & sliced_out_state(3) & sliced_out_state(4);


end Behavioral;
