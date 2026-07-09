library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library work;
use work.ascon_package.ALL;


entity ascon_core is
    generic(
        ROUNDS : natural := 8 -- Rounds to perform between 1 and 16
    );
    port(clk_i, reset_i, start_i : in std_logic;
        finished_o : out std_logic;
        state_i : in std_logic_vector(319 downto 0);
        state_o : out std_logic_vector(319 downto 0)
    );
end ascon_core;

architecture Behavioral of ascon_core is
    type fsm_state is (idle, running, finished);
    signal curr_state : fsm_state := idle;

    signal internal_state : std_logic_vector(319 downto 0);


    signal round_counter : natural range 0 to ROUNDS := 0;

    signal constant_addition : std_logic_vector(319 downto 0);
    signal nonlinear_substition : std_logic_vector(319 downto 0);
    signal linear_diffusion : std_logic_vector(319 downto 0);


begin
    

    process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                round_counter <= 0;
                finished_o <= '0';
                curr_state <= idle;
                internal_state <= (others => '0');
                state_o <= (others => '0');
            else
                

                if curr_state = idle then
                    finished_o <= '0';
                    if start_i = '1' then
                        internal_state <= state_i;
                        round_counter <= 0;
                        curr_state <= running;
                    end if;
                end if;

                if curr_state = running then
                    if round_counter = ROUNDS then
                        round_counter <= 0;
                        finished_o <= '1';
                        curr_state <= finished;
                        state_o <= internal_state;
                    else
                        round_counter <= round_counter + 1;
                        internal_state <= linear_diffusion;
                    end if;
                end if;

                if curr_state = finished then
                    state_o <= (others => '0');
                    finished_o <= '0';
                    curr_state <= idle;
                end if;
            end if;    
        end if;
    end process;

    constant_addition <= internal_state(319 downto 192) & (internal_state(191 downto 128) xor TABLE5((16 - ROUNDS + round_counter))) & internal_state(127 downto 0) when round_counter < 12 else (others => '0');

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
