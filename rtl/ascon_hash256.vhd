library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library work;
use work.ascon_package.ALL;

entity ascon_hash256 is
    port(clk_i, reset_i : in std_logic;
        start_i : in std_logic; -- hashing start signal
        word_left_i : in std_logic; -- Signal whether more than 1 64-bt word is left to be absorbed
        finished_o : out std_logic; -- squeezing finished
        word_processed_o : out std_logic; -- signal that a 64-bit word has ben absorbed
        message_digest_o : out std_logic_vector(255 downto 0); -- final output state
        message_i : in std_logic_vector(63 downto 0) -- current input 64-bit word
    );
end ascon_hash256;

architecture Behavioral of ascon_hash256 is

    type fsm_state is (idle, initialization, absorb_message, squeeze_output);
    signal curr_state : fsm_state := idle;

    signal start_core : std_logic := '0';
    signal core_finished : std_logic := '0';

    signal core_in : std_logic_vector(319 downto 0);
    signal core_out : std_logic_vector(319 downto 0);

    constant ROUNDS_TO_PERFOM : natural := 12; -- Hash256 only needs permutations with 12 rounds
    signal squeeze_counter : natural range 0 to 15 := 0;

    signal H_0 : std_logic_vector(63 downto 0);
    signal H_1 : std_logic_vector(63 downto 0);
    signal H_2 : std_logic_vector(63 downto 0);

    function invert_byte_order (x : std_logic_vector(63 downto 0)) return std_logic_vector is
        begin
        return x(7 downto 0) & x(15 downto 8) & x(23 downto 16) & x(31 downto 24) & x(39 downto 32) & x(47 downto 40) & x(55 downto 48) & x(63 downto 56); 
    end function;

begin
        
    fsm: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                word_processed_o <= '0';
                message_digest_o <= (others => '0');
                finished_o <= '0';
                
                squeeze_counter <= 0;
                curr_state <= idle;
            else
                start_core <= '0';
                word_processed_o <= '0';

                case curr_state is
                    when idle =>
                        if start_i = '1' then
                            message_digest_o <= (others => '0');
                            start_core <= '1';
                            finished_o <= '0';
                            squeeze_counter <= 0;
                            word_processed_o <= '0';
                            core_in <= (others => '0');
                            core_in(319 downto 256) <= IV_HASH;

                            curr_state <= initialization;

                        end if;

                    when initialization => 
                        if core_finished = '1' then
                            -- Proceed to word absorbtion
                            start_core <= '1';
                            

                            core_in <= core_out;
                            core_in(319 downto 256) <= core_out(319 downto 256) xor message_i;

                            word_processed_o <= '1';

                            if word_left_i = '1' then
                                curr_state <= absorb_message;
                            else
                                curr_state <= squeeze_output;
                            end if;

                        else
                            start_core <= '0';
                            word_processed_o <= '0';

                        end if;

                    when absorb_message =>
                         if core_finished = '1' then
                            
                            start_core <= '1';

                            core_in <= core_out;
                            core_in(319 downto 256) <= core_out(319 downto 256) xor message_i;
                            word_processed_o <= '1';

                            if word_left_i = '0' then
                                -- If only 1 word left to absorb
                                curr_state <= squeeze_output;
                            else
                                -- If there is more than 1 word left to absorb
                                start_core <= '1';
                            end if;
                        end if;

                    when squeeze_output =>
                        if core_finished = '1' then
                            case squeeze_counter is
                                when 0 =>
                                    start_core <= '1';
                                    H_0 <= core_out(319 downto 256);
                                    core_in <= core_out;

                                when 1 => 
                                    start_core <= '1';
                                    H_1 <= core_out(319 downto 256);
                                    core_in <= core_out;

                                when 2 =>
                                    start_core <= '1';
                                    H_2 <= core_out(319 downto 256);
                                    core_in <= core_out;

                                when others =>
                                    start_core <= '0';
                                    core_in <= core_out;
                                    finished_o <= '1';
                                    message_digest_o <= invert_byte_order(H_0) & invert_byte_order(H_1) & invert_byte_order(H_2) & invert_byte_order(core_out(319 downto 256));
                                    curr_state <= idle;
                            end case;
                            
                            squeeze_counter <= squeeze_counter + 1; 
                        end if;
                    when others => null;
                end case;
            end if;
        end if;
    end process fsm;

    ascon_core_inst: entity work.ascon_core
     port map(
        clk_i => clk_i,
        rounds_i => ROUNDS_TO_PERFOM,
        reset_i => reset_i,
        start_i => start_core,
        finished_o => core_finished,
        state_i => core_in,
        state_o => core_out
    );
    
end Behavioral;