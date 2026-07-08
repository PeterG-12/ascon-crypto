library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ascon_sbox is
    port(state_i : in std_logic_vector(320 - 1 downto 0);
        state_o : out std_logic_vector(320 - 1 downto 0)
    );
end ascon_sbox;

architecture Behavioral of ascon_sbox is
    type sliced_state_type is array (0 to 4) of std_logic_vector(63 downto 0);
    signal sliced_state : sliced_state_type;

begin

    -- Slice the state in
    process(state_i)
    begin
        for i in 0 to 4 loop
            sliced_state(i) <= state_i(64 * i + 63 downto 64 * i + 0); -- Extract 64-bit words
        end loop;
    end process;

    -- Perform Ascons's S-box transformation
    process(sliced_state)
        variable s0_xor_s4 : std_logic_vector(63 downto 0)  := (sliced_state(0) xor sliced_state(4));
        variable s1_xor_s2 : std_logic_vector(63 downto 0) := (sliced_state(1) xor sliced_state(2));
        variable s3_xor_s4 : std_logic_vector(63 downto 0) := (sliced_state(3) xor sliced_state(4));

        variable s0_xor_1 : std_logic_vector(63 downto 0) := (s0_xor_s4 xor '1');
        variable s1_xor_1 : std_logic_vector(63 downto 0) := (sliced_state(1) xor '1');
        variable s2_xor_1 : std_logic_vector(63 downto 0) := (s1_xor_s2 xor '1');
        variable s3_xor_1 : std_logic_vector(63 downto 0) := (sliced_state(3) xor '1');
        variable s4_xor_1 : std_logic_vector(63 downto 0) := (s3_xor_s4 xor '1');

        variable xor_and_s1 : std_logic_vector(63 downto 0) := (s0_xor_1 and sliced_state(1));
        variable xor_and_s2 : std_logic_vector(63 downto 0) := (s1_xor_1 and sliced_state(2));
        variable xor_and_s3 : std_logic_vector(63 downto 0) := (s2_xor_1 and sliced_state(3));
        variable xor_and_s4 : std_logic_vector(63 downto 0) := (s3_xor_1 and sliced_state(4));
        variable xor_and_s5 : std_logic_vector(63 downto 0) := (s4_xor_1 and sliced_state(0));

        variable s0_xor_2 : std_logic_vector(63 downto 0) := (s0_xor_s4 xor xor_and_s1);
        variable s1_xor_2 : std_logic_vector(63 downto 0) := (sliced_state(1) xor xor_and_s2);
        variable s2_xor_2 : std_logic_vector(63 downto 0) := (s1_xor_s2 xor xor_and_s3);
        variable s3_xor_2 : std_logic_vector(63 downto 0) := (sliced_state(3) xor xor_and_s4);
        variable s4_xor_2 : std_logic_vector(63 downto 0) := (s3_xor_s4 xor xor_and_s5);
        
        variable s0_xor_3 : std_logic_vector(63 downto 0) := (s0_xor_2 xor s4_xor_2);
        variable s1_xor_3 : std_logic_vector(63 downto 0) := (s0_xor_2 xor s1_xor_2);
        variable s2_xor_3 : std_logic_vector(63 downto 0) := (s2_xor_2 xor '1');
        variable s3_xor_3 : std_logic_vector(63 downto 0) := (s2_xor_2 xor s3_xor_2);

    begin
        state_o <= s4_xor_2 & s3_xor_3 & s2_xor_3 & s1_xor_3 & s0_xor_3;
    end process;

end Behavioral;
