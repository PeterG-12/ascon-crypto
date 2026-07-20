library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library work;
use work.ascon_package.ALL;

entity demo_wrapper is
    port(
        clk_i            : in  std_logic;
        reset_i          : in  std_logic;
        start_i          : in  std_logic;
        word_left_i      : in  std_logic;
        message_i        : in  std_logic_vector(63 downto 0);
        finished_o       : out std_logic;
        word_processed_o : out std_logic;
        message_digest_o : out std_logic_vector(255 downto 0)
    );
end demo_wrapper;

architecture Behavioral of demo_wrapper is
    

begin
    ascon_hash256_inst: entity work.ascon_hash256
     port map(
        clk_i => clk_i,
        reset_i => reset_i,
        start_i => start_i,
        word_left_i => word_left_i,
        finished_o => finished_o,
        word_processed_o => word_processed_o,
        message_digest_o => message_digest_o,
        message_i => message_i
    );

end Behavioral;
