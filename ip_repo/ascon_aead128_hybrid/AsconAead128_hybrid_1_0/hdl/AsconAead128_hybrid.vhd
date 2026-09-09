library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity AsconAead128_hybrid is
  generic (
    -- Users to add parameters here
    USE_STREAM : boolean := true;
    -- User parameters ends
    -- Do not modify the parameters beyond this line
    -- Parameters of Axi Slave Bus Interface S00_AXI
    C_S00_AXI_DATA_WIDTH : integer := 32;
    C_S00_AXI_ADDR_WIDTH : integer := 7;

    -- Parameters of Axi Master Bus Interface M00_AXIS
    C_M00_AXIS_TDATA_WIDTH : integer := 32;
    C_M00_AXIS_START_COUNT : integer := 32;

    -- Parameters of Axi Slave Bus Interface S00_AXIS
    C_S00_AXIS_TDATA_WIDTH : integer := 32
  );
  port (
    -- Users to add ports here

    -- User ports ends
    -- Do not modify the ports beyond this line
    -- Ports of Axi Slave Bus Interface S00_AXI
    aclk    : in std_logic;
    aresetn : in std_logic;

    s00_axi_awaddr  : in std_logic_vector(C_S00_AXI_ADDR_WIDTH - 1 downto 0);
    s00_axi_awprot  : in std_logic_vector(2 downto 0);
    s00_axi_awvalid : in std_logic;
    s00_axi_awready : out std_logic;
    s00_axi_wdata   : in std_logic_vector(C_S00_AXI_DATA_WIDTH - 1 downto 0);
    s00_axi_wstrb   : in std_logic_vector((C_S00_AXI_DATA_WIDTH/8) - 1 downto 0);
    s00_axi_wvalid  : in std_logic;
    s00_axi_wready  : out std_logic;
    s00_axi_bresp   : out std_logic_vector(1 downto 0);
    s00_axi_bvalid  : out std_logic;
    s00_axi_bready  : in std_logic;
    s00_axi_araddr  : in std_logic_vector(C_S00_AXI_ADDR_WIDTH - 1 downto 0);
    s00_axi_arprot  : in std_logic_vector(2 downto 0);
    s00_axi_arvalid : in std_logic;
    s00_axi_arready : out std_logic;
    s00_axi_rdata   : out std_logic_vector(C_S00_AXI_DATA_WIDTH - 1 downto 0);
    s00_axi_rresp   : out std_logic_vector(1 downto 0);
    s00_axi_rvalid  : out std_logic;
    s00_axi_rready  : in std_logic;

    -- Ports of Axi Slave Bus Interface S00_AXIS
    s00_axis_tready  : out std_logic;
    s00_axis_tdata   : in std_logic_vector(C_S00_AXIS_TDATA_WIDTH - 1 downto 0);
    s00_axis_tstrb   : in std_logic_vector((C_S00_AXIS_TDATA_WIDTH/8) - 1 downto 0);
    s00_axis_tlast   : in std_logic;
    s00_axis_tvalid  : in std_logic;

    -- Ports of Axi Master Bus Interface M00_AXIS
    m00_axis_tvalid  : out std_logic;
    m00_axis_tdata   : out std_logic_vector(C_M00_AXIS_TDATA_WIDTH - 1 downto 0);
    m00_axis_tstrb   : out std_logic_vector((C_M00_AXIS_TDATA_WIDTH/8) - 1 downto 0);
    m00_axis_tlast   : out std_logic;
    m00_axis_tready  : in std_logic;

    module_interrupt_o : out std_logic
  );
end AsconAead128_hybrid;

architecture arch_imp of AsconAead128_hybrid is

  -- User signals
  signal reset_active_high : std_logic := '0';

  signal key_axi_lite              : std_logic_vector(127 downto 0) := (others => '0');
  signal nonce_axi_lite            : std_logic_vector(127 downto 0) := (others => '0');
  signal tag_axi_lite              : std_logic_vector(127 downto 0) := (others => '0');
  signal text_out_axi_lite         : std_logic_vector(127 downto 0) := (others => '0');
  signal text_in_axi_lite          : std_logic_vector(127 downto 0) := (others => '0');
  signal associated_data_axi_lite  : std_logic_vector(127 downto 0) := (others => '0');
  signal status_register_axi_lite  : std_logic_vector(31 downto 0)  := (others => '0');
  signal control_register_axi_lite : std_logic_vector(31 downto 0)  := (others => '0');
  signal text_len_axi_lite         : natural range 0 to 128         := 0;

  signal associated_data_count_axi_lite : unsigned(31 downto 0) := (others => '0');
  signal text_count_axi_lite            : unsigned(31 downto 0) := (others => '0');
  signal associated_data_index          : unsigned(31 downto 0) := (others => '0');
  signal text_count_index               : unsigned(31 downto 0) := (others => '0');
  signal total_read                     : unsigned(31 downto 0) := (others => '0');

  signal start_core_axi_lite     : std_logic := '0';
  signal finished_axi_lite       : std_logic;
  signal text_ready_axi_lite     : std_logic;
  signal word_processed_axi_lite : std_logic;

  signal stream_slave_counter  : natural range 0 to 4 := 0;
  signal stream_master_counter : natural range 0 to 4 := 0;

  type state_t is (Idle, Ready, Valid, Valid_tag);
  signal stream_slave_state  : state_t := Idle;
  signal stream_master_state : state_t := Idle;

  signal text_in_stream         : std_logic_vector(127 downto 0) := (others => '0');
  signal associated_data_stream : std_logic_vector(127 downto 0) := (others => '0');
  signal text_out_stream        : std_logic_vector(127 downto 0) := (others => '0');

  type word_holder_t is array (0 to 3) of std_logic_vector(31 downto 0);

  signal text_in_holder         : word_holder_t := (others => (others => '0'));
  signal associated_data_holder : word_holder_t := (others => (others => '0'));
  signal text_out_holder        : word_holder_t := (others => (others => '0'));
  signal tag_holder             : word_holder_t := (others => (others => '0'));

  signal start_prev          : std_logic := '0';
  signal word_processed_prev : std_logic := '0';
  signal out_buffer_fill     : std_logic := '0';

  signal input_ready_stream : std_logic := '0';

  signal core_initialized            : std_logic              := '0';
  signal associated_data_left_stream : std_logic              := '0';
  signal text_left_stream            : std_logic              := '0';
  signal text_len_stream             : natural range 0 to 128 := 0;
  signal start_latched               : std_logic              := '0';
  signal last_latched                : std_logic              := '0';

  signal asscociated_data_state : natural range 0 to 2 := 0;
  -- User signals end

begin

  AsconAead128_hybrid_slave_lite_v1_0_S00_AXI_inst : entity work.AsconAead128_hybrid_slave_lite_v1_0_S00_AXI
    generic map(
      USE_STREAM         => USE_STREAM,
      C_S_AXI_DATA_WIDTH => C_S00_AXI_DATA_WIDTH,
      C_S_AXI_ADDR_WIDTH => C_S00_AXI_ADDR_WIDTH
    )
    port map
    (
      S_AXI_ACLK    => aclk,
      S_AXI_ARESETN => aresetn,
      S_AXI_AWADDR  => s00_axi_awaddr,
      S_AXI_AWPROT  => s00_axi_awprot,
      S_AXI_AWVALID => s00_axi_awvalid,
      S_AXI_AWREADY => s00_axi_awready,
      S_AXI_WDATA   => s00_axi_wdata,
      S_AXI_WSTRB   => s00_axi_wstrb,
      S_AXI_WVALID  => s00_axi_wvalid,
      S_AXI_WREADY  => s00_axi_wready,
      S_AXI_BRESP   => s00_axi_bresp,
      S_AXI_BVALID  => s00_axi_bvalid,
      S_AXI_BREADY  => s00_axi_bready,
      S_AXI_ARADDR  => s00_axi_araddr,
      S_AXI_ARPROT  => s00_axi_arprot,
      S_AXI_ARVALID => s00_axi_arvalid,
      S_AXI_ARREADY => s00_axi_arready,
      S_AXI_RDATA   => s00_axi_rdata,
      S_AXI_RRESP   => s00_axi_rresp,
      S_AXI_RVALID  => s00_axi_rvalid,
      S_AXI_RREADY  => s00_axi_rready,

      key_axi_lite              => key_axi_lite,
      nonce_axi_lite            => nonce_axi_lite,
      tag_axi_lite              => tag_axi_lite,
      text_out_axi_lite         => text_out_axi_lite,
      text_in_axi_lite          => text_in_axi_lite,
      associated_data_axi_lite  => associated_data_axi_lite,
      status_register_axi_lite  => status_register_axi_lite,
      control_register_axi_lite => control_register_axi_lite,
      text_len_axi_lite         => text_len_axi_lite,
      start_core_axi_lite       => start_core_axi_lite,
      finished_axi_lite         => finished_axi_lite,
      text_ready_axi_lite       => text_ready_axi_lite,
      word_processed_axi_lite   => word_processed_axi_lite,

      associated_data_count => associated_data_count_axi_lite,
      text_count            => text_count_axi_lite,

      module_interrupt_o => module_interrupt_o
    );

  text_in_stream <= text_in_holder(1) & text_in_holder(0) & text_in_holder(3) & text_in_holder(2);

  axi_stream_slave : process (aclk)
  begin
    if rising_edge(aclk) then
      if aresetn = '0' then
        s00_axis_tready       <= '0';
        stream_slave_counter  <= 0;
        start_prev            <= '0';
        start_latched         <= '0';
        last_latched          <= '0';
        associated_data_index <= (others => '0');
        text_count_index      <= (others => '0');
        total_read            <= (others => '0');

      else
        start_prev <= control_register_axi_lite(0);

        if s00_axis_tlast = '1' then
          last_latched <= '1';
        end if;

        case stream_slave_state is
          when Idle =>
            -- Start rising edge
            s00_axis_tready <= '0';
            if start_prev = '0' and control_register_axi_lite(0) = '1' then
              associated_data_index <= (others => '0');
              text_count_index      <= (others => '0');
              total_read            <= (others => '0');

              if to_integer(associated_data_count_axi_lite) = 0 then
                associated_data_left_stream <= '0';
                text_count_index            <= to_unsigned(1, 32);
              else
                associated_data_left_stream <= '1';
                associated_data_index       <= to_unsigned(1, 32);
              end if;

              if to_integer(text_count_axi_lite) <= 1 then
                text_left_stream                   <= '0';
                text_len_stream                    <= text_len_axi_lite;
              else
                text_len_stream  <= 128;
                text_left_stream <= '1';
              end if;

              start_latched      <= '1';
              input_ready_stream <= '1';
            end if;

            if start_latched = '1' then
              input_ready_stream <= '0';
              start_latched      <= '0';
              s00_axis_tready    <= '1';
              stream_slave_state <= Ready;
            end if;

            if core_initialized = '1' then
              if start_core_axi_lite = '1' and stream_slave_counter = 0 then
                if total_read < (associated_data_count_axi_lite + text_count_axi_lite) or (text_count_index = 0 and total_read = associated_data_count_axi_lite) then
                  input_ready_stream <= '0';
                  s00_axis_tready    <= '1';
                  stream_slave_state <= Ready;
                end if;
              end if;

              if word_processed_axi_lite = '1' then
                if (associated_data_count_axi_lite > 0) and (associated_data_index < associated_data_count_axi_lite) then
                  text_left_stream            <= '1';
                  associated_data_left_stream <= '1';
                  associated_data_index       <= associated_data_index + 1;
                elsif (text_count_index < text_count_axi_lite) then
                  if text_count_index = (text_count_axi_lite - 1) then
                    text_len_stream  <= text_len_axi_lite;
                    text_left_stream <= '0';
                  else
                    text_left_stream <= '1';
                  end if;
                  associated_data_left_stream <= '0';

                  text_count_index <= text_count_index + 1;
                else
                  text_left_stream            <= '0';
                  associated_data_left_stream <= '0';
                end if;
              end if;
            end if;

          when Ready =>
            if s00_axis_tvalid = '1' then
              text_in_holder(stream_slave_counter) <= s00_axis_tdata;
              stream_slave_counter                 <= stream_slave_counter + 1;

              if stream_slave_counter = 3 then
                stream_slave_state   <= Idle;
                stream_slave_counter <= 0;
                s00_axis_tready      <= '0';
                input_ready_stream   <= '1';
                total_read           <= total_read + 1;

              end if;
            end if;
          when others => null;
        end case;

      end if;
    end if;
  end process;

  axi_stream_master : process (aclk)
  begin
    if rising_edge(aclk) then
      if aresetn = '0' then
        stream_master_counter <= 0;
        m00_axis_tdata        <= (others => '0');
        word_processed_prev   <= '0';
        out_buffer_fill       <= '0';
        m00_axis_tvalid       <= '0';

      else
        word_processed_prev <= word_processed_axi_lite;
        m00_axis_tlast      <= '0';

        case stream_master_state is
          when Idle =>
            m00_axis_tvalid <= '0';
            m00_axis_tdata  <= (others => '0');
            if text_ready_axi_lite = '1' and stream_master_counter = 0 then
              m00_axis_tvalid <= '1';
              out_buffer_fill <= '1';

              stream_master_state   <= Valid;
              stream_master_counter <= stream_master_counter + 1;

              text_out_holder(3) <= text_out_stream(63 downto 32);
              text_out_holder(2) <= text_out_stream(31 downto 0);
              text_out_holder(1) <= text_out_stream(127 downto 96);
              m00_axis_tdata     <= text_out_stream(95 downto 64);
              --text_out_holder(0) <= text_out_stream(95 downto 64);
            end if;

            if finished_axi_lite = '1' and stream_master_counter = 0 then
              m00_axis_tvalid <= '1';

              stream_master_state   <= Valid_tag;
              stream_master_counter <= stream_master_counter + 1;
              tag_holder(3)         <= tag_axi_lite(63 downto 32);
              tag_holder(2)         <= tag_axi_lite(31 downto 0);
              tag_holder(1)         <= tag_axi_lite(127 downto 96);
              m00_axis_tdata        <= tag_axi_lite(95 downto 64);
              --tag_holder(0) <= tag_axi_lite(95 downto 64);
            end if;

          when Valid =>
            if m00_axis_tready = '1' then

              m00_axis_tdata        <= text_out_holder(stream_master_counter);
              stream_master_counter <= stream_master_counter + 1;

              if stream_master_counter = 3 then
                stream_master_state   <= Idle;
                out_buffer_fill       <= '0';
                stream_master_counter <= 0;
              end if;
            end if;
          when Valid_tag =>
            if m00_axis_tready = '1' then

              m00_axis_tdata        <= tag_holder(stream_master_counter);
              stream_master_counter <= stream_master_counter + 1;

              if stream_master_counter = 3 then
                stream_master_state   <= Idle;
                out_buffer_fill       <= '0';
                stream_master_counter <= 0;
                m00_axis_tlast        <= '1';
              end if;
            end if;
          when others => null;
        end case;
      end if;
    end if;
  end process;

  -- Add user logic here
  reset_active_high <= not aresetn;

  stream_core : if USE_STREAM = true generate
  begin
    ascon_aead_inst : entity work.ascon_aead
      port map
      (
        clk_i                       => aclk,
        reset_i                     => reset_active_high,
        start_i                     => control_register_axi_lite(0),
        associated_data_word_left_i => associated_data_left_stream,
        plaintext_word_left_i       => text_left_stream,
        encrypt_mode_i              => control_register_axi_lite(3),
        input_ready_i               => input_ready_stream,
        start_core_o                => start_core_axi_lite,
        finished_o                  => finished_axi_lite,
        text_ready_o                => text_ready_axi_lite,
        word_processed_o            => word_processed_axi_lite,
        key_i                       => key_axi_lite,
        nonce_i                     => nonce_axi_lite,
        assoc_data_i                => text_in_stream,
        text_i                      => text_in_stream,
        text_o                      => text_out_stream,
        tag_o                       => tag_axi_lite,
        text_len_i                  => text_len_stream,
        stall_i                     => out_buffer_fill,
        core_initialized_o          => core_initialized
      );
  end generate;

  non_stream_core : if USE_STREAM = false generate
  begin
    ascon_aead_inst : entity work.ascon_aead
      port map
      (
        clk_i                       => aclk,
        reset_i                     => reset_active_high,
        start_i                     => control_register_axi_lite(0),
        associated_data_word_left_i => control_register_axi_lite(1),
        plaintext_word_left_i       => control_register_axi_lite(2),
        encrypt_mode_i              => control_register_axi_lite(3),
        input_ready_i               => control_register_axi_lite(4),
        start_core_o                => start_core_axi_lite,
        finished_o                  => finished_axi_lite,
        text_ready_o                => text_ready_axi_lite,
        word_processed_o            => word_processed_axi_lite,
        key_i                       => key_axi_lite,
        nonce_i                     => nonce_axi_lite,
        assoc_data_i                => associated_data_axi_lite,
        text_i                      => text_in_axi_lite,
        text_o                      => text_out_axi_lite,
        tag_o                       => tag_axi_lite,
        text_len_i                  => text_len_axi_lite,
        stall_i                     => '0',
        core_initialized_o          => core_initialized
      );
  end generate;
  -- User logic ends

end arch_imp;
