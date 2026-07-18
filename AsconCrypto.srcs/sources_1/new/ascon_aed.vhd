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
        encrypt_mode_i : in std_logic; -- '1' for encrypt '0' for decrypt
        key_i : in std_logic_vector(127 downto 0); -- Secret key
        nonce_i : in std_logic_vector(127 downto 0); -- Nonce
        assoc_data_i : in std_logic_vector(127 downto 0); -- current AD input 128-bit word
        text_i : in std_logic_vector(127 downto 0); -- current Plaintext input 128-bit word
        text_o : out std_logic_vector(127 downto 0); -- current output 128-bit word
        tag_o : out std_logic_vector(127 downto 0); -- authenticaction tag 128-bit word
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
    
    signal debug_clock : natural range 0 to 10_000_000 := 0;

    signal mask_low : std_logic_vector(63 downto 0);
    signal mask_high : std_logic_vector(63 downto 0);


begin
    
    decrypt_mask : process(p_len_i)
    begin
        mask_low <= (others => '0');
        mask_high <= (others => '0');

        for j in 0 to 63 loop
            if j < p_len_i then
                mask_high(j) <= '1';
            end if;
        end loop;

        for j in 64 to 127 loop
            if j < p_len_i then
                mask_low(j - 64) <= '1';
            end if;
        end loop;
    end process decrypt_mask;



    fsm : process(clk_i, reset_i)
    begin
        if rising_edge(clk_i) then
            debug_clock <= debug_clock + 1;
            if reset_i = '1' then
                error_o <= '0';
                curr_state <= idle;
                key <= (others => '0');
                core_in <= (others => '0');
                text_o <= (others => '0');
                c_ready_o <= '0';
                core_rounds <= 12;
                finished_o <= '0';
                start_core <= '0';
            else
                start_core <= '0';
                error_o <= '0';
                word_processed_o <= '0';
                c_ready_o <= '0';

                case curr_state is
                    when idle => 
                        text_o <= (others => '0');
                        core_rounds <= 12;
                        finished_o <= '0';
                        if start_i = '1' then
                            start_core <= '1';

                            core_in <= IV_AEAD & key_i & nonce_i;
                            key <= key_i;
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
                                core_in(319 downto 192) <= core_out(319 downto 192) xor assoc_data_i;
                                curr_state <= associated_data;
                                
                            elsif plaintext_word_left_i = '1' then
                                if encrypt_mode_i = '1' then
                                    core_in(319 downto 192) <= core_out(319 downto 192) xor text_i;
                                    text_o <= core_out(319 downto 192) xor text_i;
                                else
                                    core_in(319 downto 192) <= text_i;
                                    text_o <= core_out(319 downto 192) xor text_i;
                                end if;

                                c_ready_o <= '1';
                                core_in(191 downto 128) <= core_out(191 downto 128);
                                core_in(127 downto 64) <= core_out(127 downto 64) xor (key(127 downto 64));
                                core_in(63) <= core_out(63) xor '1' xor key(63);
                                curr_state <= plaintext;

                            else
                                if encrypt_mode_i = '1' then
                                    -- Encrypt
                                    core_in(319 downto 192) <= core_out(319 downto 192) xor text_i;
                                    text_o <= core_out(319 downto 192) xor text_i;
                                else
                                    -- Decrypt
                                    core_in(319 downto 256) <= core_out(319 downto 256) xor ((core_out(319 downto 256) xor text_i(127 downto 64)) and mask_high);
                                    core_in(255 downto 192) <= core_out(255 downto 192) xor ((core_out(255 downto 192) xor text_i(63 downto 0)) and mask_low);

                                    if p_len_i < 64 then
                                        core_in(256 + p_len_i) <= core_out(256 + p_len_i) xor '1';
                                    elsif p_len_i < 128 then
                                        core_in(128 + p_len_i) <= core_out(128 + p_len_i) xor '1';
                                    end if;

                                    text_o <= core_out(319 downto 192) xor text_i;
                                end if;
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
                                core_in(319 downto 192) <= core_out(319 downto 192) xor assoc_data_i;
                            elsif plaintext_word_left_i = '1' then
                                if encrypt_mode_i = '1' then
                                    core_in(319 downto 192) <= core_out(319 downto 192) xor text_i;
                                    text_o <= core_out(319 downto 192) xor text_i;
                                else
                                    core_in(319 downto 192) <= text_i;
                                    text_o <= core_out(319 downto 192) xor text_i;
                                end if;
                                c_ready_o <= '1';

                                core_in(63) <= core_out(63) xor '1';
                                curr_state <= plaintext;
                            else
                                if encrypt_mode_i = '1' then
                                    -- Encrypt
                                    core_in(319 downto 192) <= core_out(319 downto 192) xor text_i;
                                    text_o <= core_out(319 downto 192) xor text_i;
                                else
                                    -- Decrypt
                                    core_in(319 downto 256) <= core_out(319 downto 256) xor ((core_out(319 downto 256) xor text_i(127 downto 64)) and mask_high);
                                    core_in(255 downto 192) <= core_out(255 downto 192) xor ((core_out(255 downto 192) xor text_i(63 downto 0)) and mask_low);
                                    
                                    if p_len_i < 64 then
                                        core_in(256 + p_len_i) <= core_out(256 + p_len_i) xor '1';
                                    elsif p_len_i < 128 then
                                        core_in(128 + p_len_i) <= core_out(128 + p_len_i) xor '1';
                                    end if;

                                    text_o <= core_out(319 downto 192) xor text_i;
                                end if;
                                c_ready_o <= '1';
                                
                                core_in(63) <= core_out(63) xor '1';

                                core_in(191 downto 64) <= core_out(191 downto 64) xor key;
                                core_rounds <= 12;
                                curr_state <= finalization;
                            end if;
                        end if;

                    when plaintext =>
                        if core_finished = '1' then
                            core_in <= core_out;
                            start_core <= '1';
                            word_processed_o <= '1';

                            if encrypt_mode_i = '1' then
                                -- Encrypt
                                core_in(319 downto 192) <= core_out(319 downto 192) xor text_i;
                                text_o <= core_out(319 downto 192) xor text_i;
                            else
                                -- Decrypt
                                core_in(319 downto 256) <= core_out(319 downto 256) xor ((core_out(319 downto 256) xor text_i(127 downto 64)) and mask_high);
                                core_in(255 downto 192) <= core_out(255 downto 192) xor ((core_out(255 downto 192) xor text_i(63 downto 0)) and mask_low);

                                if p_len_i < 64 then
                                    core_in(256 + p_len_i) <= core_out(256 + p_len_i) xor '1';
                                elsif p_len_i < 128 then
                                    core_in(128 + p_len_i) <= core_out(128 + p_len_i) xor '1';
                                end if;

                                text_o <= core_out(319 downto 192) xor text_i;
                            end if;
                            c_ready_o <= '1';

                            if plaintext_word_left_i = '1' then
                                core_rounds <= 8;
                            else
                                
                                core_in(191 downto 64) <= core_out(191 downto 64) xor key;
                                core_rounds <= 12;
                                curr_state <= finalization;
                            end if;
                        end if;

                    when finalization =>
                        if core_finished = '1' then
                            tag_o <= core_out(127 downto 0) xor key;
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
