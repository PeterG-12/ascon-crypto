library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library work;
use work.ascon_package.ALL;


entity ascon_core is
    port(clk_i, reset_i : in std_logic;
        start_i : in std_logic; -- start signal
        finished_o : out std_logic; -- finished signal
        state_i : in std_logic_vector(319 downto 0); -- input state
        rounds_i : in natural; -- rounds to perform between 1 and 16
        state_o : out std_logic_vector(319 downto 0) -- final state
    );
end ascon_core;

architecture Behavioral of ascon_core is
    type fsm_state is (idle, running, finished);
    signal curr_state : fsm_state := idle;

    signal internal_state : std_logic_vector(319 downto 0);


    signal round_counter : natural range 0 to 16 := 0; -- Countign how many rounds have been performed
    signal rounds_to_perform : natural range 0 to 16 := 0; -- Registers value of rounds to do

    signal constant_addition : std_logic_vector(319 downto 0);
    signal nonlinear_substition : std_logic_vector(319 downto 0);
    signal linear_diffusion : std_logic_vector(319 downto 0);


begin
    

    process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                round_counter <= 0;
                rounds_to_perform <= 0;
                finished_o <= '0';
                curr_state <= idle;
                internal_state <= (others => '0');
                state_o <= (others => '0');
            else
                case curr_state is
                    when idle => 
                        state_o <= (others => '0');
                        finished_o <= '0';
                        if start_i = '1' then
                            internal_state <= state_i; -- Load the starting state
                            round_counter <= 0;
                            rounds_to_perform <= rounds_i;
                            curr_state <= running;
                        end if;

                    when running =>
                        if round_counter = rounds_to_perform then
                            round_counter <= 0;
                            finished_o <= '1';
                            

                            state_o <= internal_state;
                            curr_state <= finished;
                        else
                            round_counter <= round_counter + 1;
                            internal_state <= linear_diffusion;
                        end if;

                    when finished =>
                        state_o <= (others => '0');
                        finished_o <= '0';
                        curr_state <= idle;

                    when others => null;
                end case;
            end if;    
        end if;
    end process;

    -- Three stage ASCON permutation
    constant_addition <= internal_state(319 downto 192) & (internal_state(191 downto 128) xor TABLE5((16 - rounds_to_perform + round_counter))) & internal_state(127 downto 0) 


    when (16 - rounds_to_perform + round_counter) < 16 
    else (others => '0');

    ascon_sbox_inst: entity work.ascon_sbox
     port map(
        state_i => constant_addition,
        state_o => nonlinear_substition
    );

    ascon_linear_layer_inst: entity work.ascon_linear_layer
     port map(
        state_i => nonlinear_substition,
        state_o => linear_diffusion
    );
    
end Behavioral;
