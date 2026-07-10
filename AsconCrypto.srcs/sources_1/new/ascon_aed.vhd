library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library work;
use work.ascon_package.ALL;

entity ascon_aed is
    port(clk_i, reset_i : in std_logic;
        start_i : in std_logic; -- hashing start signal
        associated_data_word_left_i : in std_logic; -- Signal whether at least 1 128-bit AD word is left to be absorbed
        plaintext_word_left_i : in std_logic; -- Signal whether at least 1 128-bt word of plaintext is left to be absorbed
        finished_o : out std_logic; -- squeezing finished
        error_o : out std_logic; -- indicates error
        word_processed_o : out std_logic; -- signal that a 64-bit word has ben absorbed
        state_o : out std_logic_vector(255 downto 0); -- final output state
        k_i : in std_logic_vector(127 downto 0); -- Secret key
        n_i : in std_logic_vector(127 downto 0); -- Nonce
        a_i : in std_logic_vector(127 downto 0); -- current AD input 128-bit word
        p_i : in std_logic_vector(127 downto 0); -- current Plaintext input 128-bit word
        c_o : out std_logic_vector(127 downto 0); -- current output 128-bit word
        p_len_i : in natural -- length of plaintext word used at last stage must be greater than 1
    );
end ascon_aed;

architecture Behavioral of ascon_aed is
    type state_type is (idle, initialization, associated_data, plaintext, finalization);

    signal start_core : std_logic := '0';
    signal core_finished : std_logic := '0';
    signal key : std_logic_vector(127 downto 0) := (others => '0');

    signal core_in : std_logic_vector(319 downto 0) := (others => '0');
    signal core_out : std_logic_vector(319 downto 0);
    signal core_rounds : natural := 12;

    signal curr_state : state_type := idle;

begin

    fsm : process(clk_i, reset_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                error_o <= '0';
                curr_state <= idle;
                key <= (others => '0');
                core_in <= (others => '0');
                core_rounds <= 12;
            else
                start_core <= '0';
                error_o <= '0';

                case curr_state is
                    when idle => 
                        key <= (others => '0');
                        core_in <= (others => '0');
                        core_rounds <= 12;
                        finished_o <= '0';

                        if start_i = '1' then
                            start_core <= '1';
                            core_in <= n_i & k_i & IV_AEAD;
                            key <= k_i;
                            curr_state <= initialization;
                        end if;

                    when initialization =>
                        if core_finished = '1' then
                            start_core <= '1';
                            core_rounds <= 8;
                            core_in(191 downto 0) <= core_out(191 downto 0) xor (key & x"00000000000000");

                            if associated_data_word_left_i = '1' then
                                core_in(319 downto 192) <= core_out(319 downto 192) xor a_i;
                                curr_state <= associated_data;
                            else
                                core_in(319 downto 192) <= core_out(319 downto 192) xor p_i;
                                core_in(191 downto 0) <= core_out(191 downto 1) & core_out(0) xor '1';
                                curr_state <= plaintext;
                            end if;
                        end if;

                    when associated_data => 
                        if core_finished = '1' then
                            start_core <= '1';
                            core_rounds <= 8;
                            if associated_data_word_left_i = '1' then
                                core_in(319 downto 192) <= core_out(319 downto 192) xor a_i;
                            else
                                core_in(319 downto 192) <= core_out(319 downto 192) xor p_i;
                                core_in(191 downto 0) <= core_out(191 downto 1) & core_out(0) xor '1';
                                curr_state <= plaintext;
                            end if;
                        end if;

                    when plaintext =>
                        if core_finished = '1' then
                            c_o <= core_out(319 downto 192);
                            start_core <= '1';
                            core_rounds <= 8;
                            if plaintext_word_left_i = '1' then
                                core_in <= core_out;
                                core_in(319 downto 192) <= core_out(319 downto 192) xor p_i;
                            else
                                if p_len_i > 0 then
                                    core_in(319 downto 320 - p_len_i) <= core_out(319 downto 320 - p_len_i) xor p_i(127 downto 128 - p_len_i);
                                    core_in(320 - p_len_i - 1 downto 192) <= core_in(320 - p_len_i - 1 downto 192) xor ('1' & (others => '0'));
                                    core_in(191 downto 0) <= core_out(191 downto 0) xor (key & x"00000000000000");
                                    core_rounds <= 12;
                                    curr_state <= finalization;
                                else
                                    error_o <= '1';
                                end if;
                            end if;
                        end if;

                    when finalization =>
                        if core_finished = '1' then
                            c_o <= core_out(319 downto 192);
                            t_o <= core_out(191 downto 0) xor key;
                            key <= (others => '0'); -- Erasing the key as soon as possible
                            finished_o <= '1';
                            curr_state <= idle;
                        end if;


                    when others => null;
                end case;
            end if;
        end if;
    end process fsm;

    ascon_core_inst: entity work.ascon_core
     port map(
        clk_i => clk_i,
        reset_i => reset_i,
        start_i => start_core,
        finished_o => core_finished,
        state_i => core_in,
        rounds_i => core_rounds,
        state_o => core_out
    );
end Behavioral;
