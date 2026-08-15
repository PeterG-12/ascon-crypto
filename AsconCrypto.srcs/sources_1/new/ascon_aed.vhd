library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library work;
use work.ascon_package.ALL;

entity ascon_aead is
    port(clk_i, reset_i : in std_logic;
        start_i : in std_logic; -- hashing start signal
        associated_data_word_left_i : in std_logic; -- Signal whether at least 1 128-bit AD word is left to be absorbed
        plaintext_word_left_i : in std_logic; -- Signal whether at least 1 128-bt word of plaintext is left to be absorbed
        encrypt_mode_i : in std_logic; -- '1' for encrypt '0' for decrypt
        input_ready_i : std_logic; -- Input data is ready to be consumed

        start_core_o : out std_logic; -- Core started
        finished_o : out std_logic; -- operation finished
        text_ready_o : out std_logic; -- text block ready
        word_processed_o : out std_logic; -- signal that a 64-bit word has ben absorbed

        key_i : in std_logic_vector(127 downto 0); -- Secret key
        nonce_i : in std_logic_vector(127 downto 0); -- Nonce
        assoc_data_i : in std_logic_vector(127 downto 0); -- current AD input 128-bit word
        text_i : in std_logic_vector(127 downto 0); -- current Plaintext input 128-bit word
        text_o : out std_logic_vector(127 downto 0); -- current output 128-bit word
        tag_o : out std_logic_vector(127 downto 0); -- authenticaction tag 128-bit word
        text_len_i : in natural range 0 to 128 -- length of plaintext word used at last stage must be greater than 1
    );
end ascon_aead;

architecture Behavioral of ascon_aead is
    type state_type is (idle, initialization, associated_data, plaintext, finished, finalization);

    signal start_core : std_logic := '0';
    signal core_finished : std_logic := '0';
    signal core_finished_latched : std_logic := '0';
    signal key : std_logic_vector(127 downto 0) := (others => '0');

    signal core_in : std_logic_vector(319 downto 0) := (others => '0');
    signal core_out : std_logic_vector(319 downto 0) := (others => '0');
    signal core_out_latched : std_logic_vector(319 downto 0) := (others => '0');
    signal core_rounds : natural := 12;

    signal curr_state : state_type := idle;

    signal mask_low : std_logic_vector(63 downto 0);
    signal mask_high : std_logic_vector(63 downto 0);
    signal pad_low : std_logic_vector(63 downto 0);
    signal pad_high : std_logic_vector(63 downto 0);



    signal start_prev : std_logic := '0';

begin
    
    decrypt_mask : process(text_len_i)
    begin
        mask_low <= (others => '0');
        mask_high <= (others => '0');
        pad_low <= (others => '0');
        pad_high <= (others => '0');
        
        for j in 0 to 63 loop
            if j < text_len_i then
                mask_high(j) <= '1';
            end if;
        end loop;

        for j in 64 to 127 loop
            if j < text_len_i then
                mask_low(j - 64) <= '1';
            end if;
        end loop;

        for j in 0 to 63 loop
            if j = text_len_i then
                pad_high(j) <= '1';
            end if;
        end loop;

        for j in 64 to 127 loop
            if j = text_len_i then
                pad_low(j - 64) <= '1';
            end if;
        end loop;

    end process decrypt_mask;

    start_core_o <= start_core;
    word_processed_o <= core_finished;

    fsm : process(clk_i, reset_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                start_prev <= '0';
                curr_state <= idle;
                key <= (others => '0');
                core_in <= (others => '0');
                text_o <= (others => '0');
                text_ready_o <= '0';
                core_rounds <= 12;
                finished_o <= '0';
                start_core <= '0';
                core_finished_latched <= '0';
                core_out_latched <= (others => '0');
            else
                start_core <= '0';
                --word_processed_o <= '0';
                text_ready_o <= '0';
                if core_finished = '1' then
                    core_finished_latched <= '1';
                    core_out_latched <= core_out;
                end if;
                case curr_state is
                    when idle => 
                        start_prev <= start_i;
                        text_o <= (others => '0');
                        core_rounds <= 12;
                        finished_o <= '0';
                        if start_i = '1' and start_prev = '0' then
                            start_core <= '1';

                            core_in <= IV_AEAD & key_i & nonce_i;
                            key <= key_i;
                            curr_state <= initialization;
                        end if;

                    when initialization =>
                        if core_finished_latched = '1'  and input_ready_i = '1' then
                            core_finished_latched <= '0';
                            core_in <= core_out_latched;
                            
                            -- word_processed_o <= '1';
                            start_core <= '1';
                            core_rounds <= 8;

                            core_in(191 downto 0) <= core_out_latched(191 downto 0) xor (x"0000000000000000" & key);

                            if associated_data_word_left_i = '1' then
                                core_in(319 downto 192) <= core_out_latched(319 downto 192) xor assoc_data_i;
                                curr_state <= associated_data;
                                
                            elsif plaintext_word_left_i = '1' then
                                if encrypt_mode_i = '1' then
                                    core_in(319 downto 192) <= core_out_latched(319 downto 192) xor text_i;
                                    text_o <= core_out_latched(319 downto 192) xor text_i;
                                else
                                    core_in(319 downto 192) <= text_i;
                                    text_o <= core_out_latched(319 downto 192) xor text_i;
                                end if;

                                text_ready_o <= '1';
                                core_in(191 downto 128) <= core_out_latched(191 downto 128);
                                core_in(127 downto 64) <= core_out_latched(127 downto 64) xor (key(127 downto 64));
                                core_in(63) <= core_out_latched(63) xor '1' xor key(63);
                                curr_state <= plaintext;

                            else
                                if encrypt_mode_i = '1' then
                                    -- Encrypt
                                    core_in(319 downto 192) <= core_out_latched(319 downto 192) xor text_i;
                                    text_o <= core_out_latched(319 downto 192) xor text_i;
                                else
                                    -- Decrypt
                                    core_in(319 downto 256) <= core_out_latched(319 downto 256) xor ((core_out_latched(319 downto 256) xor text_i(127 downto 64)) and mask_high) xor pad_high;
                                    core_in(255 downto 192) <= core_out_latched(255 downto 192) xor ((core_out_latched(255 downto 192) xor text_i(63 downto 0)) and mask_low) xor pad_low;

                                    text_o <= core_out_latched(319 downto 192) xor text_i;
                                end if;
                                text_ready_o <= '1';

                                core_in(191 downto 128) <= core_out_latched(191 downto 128) xor key(127 downto 64);
                                core_in(127 downto 64) <= core_out_latched(127 downto 64) xor key(127 downto 64) xor key(63 downto 0);
                                core_in(63 downto 0) <= core_out_latched(63 downto 0) xor key(63 downto 0);
                                core_in(63) <= core_out_latched(63) xor '1' xor key(63);

                                core_rounds <= 12;
                                curr_state <= finalization;
                            end if;
                        end if;

                    when associated_data => 
                        if core_finished_latched = '1'  and input_ready_i = '1' then
                            core_finished_latched <= '0';
                            core_in <= core_out_latched;

                            start_core <= '1';
                            -- word_processed_o <= '1';
                            core_rounds <= 8;

                            if associated_data_word_left_i = '1' then
                                core_in(319 downto 192) <= core_out_latched(319 downto 192) xor assoc_data_i;
                            elsif plaintext_word_left_i = '1' then
                                if encrypt_mode_i = '1' then
                                    core_in(319 downto 192) <= core_out_latched(319 downto 192) xor text_i;
                                    text_o <= core_out_latched(319 downto 192) xor text_i;
                                else
                                    core_in(319 downto 192) <= text_i;
                                    text_o <= core_out_latched(319 downto 192) xor text_i;
                                end if;
                                text_ready_o <= '1';

                                core_in(63) <= core_out_latched(63) xor '1';
                                curr_state <= plaintext;
                            else
                                if encrypt_mode_i = '1' then
                                    -- Encrypt
                                    core_in(319 downto 192) <= core_out_latched(319 downto 192) xor text_i;
                                    text_o <= core_out_latched(319 downto 192) xor text_i;
                                else
                                    -- Decrypt
                                    core_in(319 downto 256) <= core_out_latched(319 downto 256) xor ((core_out_latched(319 downto 256) xor text_i(127 downto 64)) and mask_high) xor pad_high;
                                    core_in(255 downto 192) <= core_out_latched(255 downto 192) xor ((core_out_latched(255 downto 192) xor text_i(63 downto 0)) and mask_low) xor pad_low;


                                    text_o <= core_out_latched(319 downto 192) xor text_i;
                                end if;
                                text_ready_o <= '1';
                                
                                core_in(63) <= core_out_latched(63) xor '1';

                                core_in(191 downto 64) <= core_out_latched(191 downto 64) xor key;
                                core_rounds <= 12;
                                curr_state <= finalization;
                            end if;
                        end if;

                    when plaintext =>
                        if core_finished_latched = '1'  and input_ready_i = '1' then
                            core_finished_latched <= '0';


                            core_in <= core_out_latched;
                            start_core <= '1';
                            -- word_processed_o <= '1';

                            if encrypt_mode_i = '1' then
                                -- Encrypt
                                core_in(319 downto 192) <= core_out_latched(319 downto 192) xor text_i;
                                text_o <= core_out_latched(319 downto 192) xor text_i;
                            else
                                -- Decrypt
                                core_in(319 downto 256) <= core_out_latched(319 downto 256) xor ((core_out_latched(319 downto 256) xor text_i(127 downto 64)) and mask_high) xor pad_high;
                                core_in(255 downto 192) <= core_out_latched(255 downto 192) xor ((core_out_latched(255 downto 192) xor text_i(63 downto 0)) and mask_low) xor pad_low;
                                text_o <= core_out_latched(319 downto 192) xor text_i;
                            end if;
                            text_ready_o <= '1';

                            if plaintext_word_left_i = '1' then
                                core_rounds <= 8;
                            else
                                
                                core_in(191 downto 64) <= core_out_latched(191 downto 64) xor key;
                                core_rounds <= 12;
                                curr_state <= finalization;
                            end if;
                        end if;

                    when finalization =>
                        if core_finished_latched = '1'  and input_ready_i = '1' then
                            core_finished_latched <= '0';
                            tag_o <= core_out_latched(127 downto 0) xor key;
                            key <= (others => '0');
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
