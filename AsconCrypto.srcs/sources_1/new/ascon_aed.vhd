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
        c_ready_o : out std_logic; -- ciphertext block ready
        word_processed_o : out std_logic; -- signal that a 64-bit word has ben absorbed
        --state_o : out std_logic_vector(255 downto 0); -- final output state
        k_i : in std_logic_vector(127 downto 0); -- Secret key
        n_i : in std_logic_vector(127 downto 0); -- Nonce
        a_i : in std_logic_vector(127 downto 0); -- current AD input 128-bit word
        p_i : in std_logic_vector(127 downto 0); -- current Plaintext input 128-bit word
        c_o : out std_logic_vector(127 downto 0); -- current output 128-bit word
        t_o : out std_logic_vector(127 downto 0); -- authenticaction tag 128-bit word
        p_len_i : in natural -- length of plaintext word used at last stage must be greater than 1
    );
end ascon_aed;

architecture Behavioral of ascon_aed is
    type state_type is (idle, initialization, associated_data, plaintext, finished, finalization);

    signal start_core : std_logic := '0';
    signal core_finished : std_logic := '0';
    signal key : std_logic_vector(127 downto 0) := (others => '0');

    signal core_in : std_logic_vector(319 downto 0) := (others => '0');
    signal core_out : std_logic_vector(319 downto 0) := (others => '0');
    signal core_rounds : natural := 12;

    signal curr_state : state_type := idle;
    
    
    
    signal p_intermed_debug : natural;
    signal debug_clock : natural range 0 to 10_000_000 := 0;


begin
    p_intermed_debug <= p_len_i;
    

    fsm : process(clk_i, reset_i)
    begin
        if rising_edge(clk_i) then
            debug_clock <= debug_clock + 1;
            if reset_i = '1' then
                error_o <= '0';
                curr_state <= idle;
                key <= (others => '0');
                core_in <= (others => '0');
                c_o <= (others => '0');
                c_ready_o <= '0';
                core_rounds <= 12;
            else
                start_core <= '0';
                error_o <= '0';
                word_processed_o <= '0';
                c_ready_o <= '0';

                case curr_state is
                    when idle => 
                        c_o <= (others => '0');
                        core_rounds <= 12;
                        finished_o <= '0';
                        if start_i = '1' then
                            start_core <= '1';

                            core_in <= IV_AEAD & k_i & n_i;
                            key <= k_i;
                            curr_state <= initialization;
                        end if;

                    when initialization =>
                        if core_finished = '1' then
                            core_in <= core_out;
                            
                            word_processed_o <= '1';
                            start_core <= '1';
                            core_rounds <= 8;

                            core_in(191 downto 0) <= core_out(191 downto 0) xor (x"0000000000000000" & key);

                            if associated_data_word_left_i = '1' then
                                core_in(319 downto 192) <= core_out(319 downto 192) xor a_i;
                                curr_state <= associated_data;
                                
                            elsif plaintext_word_left_i = '1' then
                                core_in(319 downto 192) <= core_out(319 downto 192) xor p_i;
                                c_o <= core_out(319 downto 192) xor p_i;
                                c_ready_o <= '1';

                                core_in(191 downto 128) <= core_out(191 downto 128);
                                core_in(127 downto 64) <= core_out(127 downto 64) xor (key(127 downto 64));
                                core_in(63) <= core_out(63) xor '1' xor key(63);
                                curr_state <= plaintext;

                            else
                                core_in(319 downto 192) <= core_out(319 downto 192) xor p_i;
                                c_o <= core_out(319 downto 192) xor p_i;
                                c_ready_o <= '1';

                                core_in(191 downto 128) <= core_out(191 downto 128) xor key(127 downto 64);
                                core_in(127 downto 64) <= core_out(127 downto 64) xor key(127 downto 64) xor key(63 downto 0);
                                core_in(63 downto 0) <= core_out(63 downto 0) xor key(63 downto 0);
                                core_in(63) <= core_out(63) xor '1' xor key(63);

                                


                                core_rounds <= 12;
                                curr_state <= finalization;
                            end if;
                        end if;

                    when associated_data => 
                        if core_finished = '1' then
                            core_in <= core_out;

                            start_core <= '1';
                            word_processed_o <= '1';
                            core_rounds <= 8;

                            if associated_data_word_left_i = '1' then
                                core_in(319 downto 192) <= core_out(319 downto 192) xor a_i;
                            elsif plaintext_word_left_i = '1' then
                                c_o <= core_out(319 downto 192) xor p_i;
                                c_ready_o <= '1';
                                core_in(319 downto 192) <= core_out(319 downto 192) xor p_i;
                                core_in(63) <= core_out(63) xor '1';
                                curr_state <= plaintext;
                            else
                                c_o <= core_out(319 downto 192) xor p_i;
                                c_ready_o <= '1';
                                
                                core_in(319 downto 192) <= core_out(319 downto 192) xor p_i;
                                core_in(63) <= core_out(63) xor '1';

                                core_in(191 downto 64) <= core_out(191 downto 64) xor key;
                                core_rounds <= 12;
                                curr_state <= finalization;
                            end if;
                        end if;

                    when plaintext =>
                        if core_finished = '1' then
                            core_in <= core_out;
                            c_o <= core_out(319 downto 192) xor p_i;
                            c_ready_o <= '1';

                            start_core <= '1';
                            word_processed_o <= '1';
                            core_rounds <= 8;

                            if plaintext_word_left_i = '1' then
                                core_in(319 downto 192) <= core_out(319 downto 192) xor p_i;
                            else
                                if p_intermed_debug > 0 then

                                    --core_in(319 downto 320 - p_intermed_debug) <= core_out(319 downto 320 - p_intermed_debug) xor p_i(p_intermed_debug - 1 downto 0);
                                    --c_o <= (others => '0');
                                    --c_o(p_intermed_debug - 1 downto 0) <= core_out(319 downto 320 - p_intermed_debug) xor p_i(p_intermed_debug - 1 downto 0);
                                    core_in(319 downto 192) <= core_out(319 downto 192) xor p_i;
                                    c_o <= core_out(319 downto 192) xor p_i;

                                    --core_in(320 - p_intermed_debug - 1) <= core_out(320 - p_intermed_debug- 1) xor '1';

                                    core_in(191 downto 64) <= core_out(191 downto 64) xor key;
                                    core_rounds <= 12;
                                    curr_state <= finalization;

                                else
                                    core_in(319 downto 192) <= core_out(319 downto 192) xor p_i;
                                    core_in(191 downto 64) <= core_out(191 downto 64) xor key;

                                    core_rounds <= 12;
                                    curr_state <= finalization;
                                end if;
                            end if;
                        end if;

                    when finalization =>
                        if core_finished = '1' then
                            t_o <= core_out(127 downto 0) xor key;
                            key <= (others => '0'); -- Erasing the key as soon as possible
                            
                            curr_state <= finished;
                        end if;

                    when finished =>
                        finished_o <= '1';
                        curr_state <= idle;


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
