library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity AsconAead128_hybrid is
  generic (
    -- Users to add parameters here

    -- User parameters ends
    -- Do not modify the parameters beyond this line
    -- Parameters of Axi Slave Bus Interface S00_AXI
    C_S00_AXI_DATA_WIDTH : integer := 32;
    C_S00_AXI_ADDR_WIDTH : integer := 7;

    -- Parameters of Axi Slave Bus Interface S00_AXIS
    C_S00_AXIS_TDATA_WIDTH : integer := 32
  );
  port (
    -- Users to add ports here

    -- User ports ends
    -- Do not modify the ports beyond this line
    -- Ports of Axi Slave Bus Interface S00_AXI
    s00_axi_aclk    : in std_logic;
    s00_axi_aresetn : in std_logic;
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
    s00_axis_aclk    : in std_logic;
    s00_axis_aresetn : in std_logic;
    s00_axis_tready  : out std_logic;
    s00_axis_tdata   : in std_logic_vector(C_S00_AXIS_TDATA_WIDTH - 1 downto 0);
    s00_axis_tstrb   : in std_logic_vector((C_S00_AXIS_TDATA_WIDTH/8) - 1 downto 0);
    s00_axis_tlast   : in std_logic;
    s00_axis_tvalid  : in std_logic;

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
  signal start_core_axi_lite       : std_logic                      := '0';
  signal finished_axi_lite         : std_logic;
  signal text_ready_axi_lite       : std_logic;
  signal word_processed_axi_lite   : std_logic;

  -- User signals end

begin

  AsconAead128_hybrid_slave_lite_v1_0_S00_AXI_inst : entity work.AsconAead128_hybrid_slave_lite_v1_0_S00_AXI
    generic map(
      C_S_AXI_DATA_WIDTH => C_S00_AXI_DATA_WIDTH,
      C_S_AXI_ADDR_WIDTH => C_S00_AXI_ADDR_WIDTH
    )
    port map
    (
      S_AXI_ACLK    => s00_axi_aclk,
      S_AXI_ARESETN => s00_axi_aresetn,
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

      module_interrupt_o => module_interrupt_o
    );

  AsconAead128_hybrid_slave_stream_v1_0_S00_AXIS_inst : entity work.AsconAead128_hybrid_slave_stream_v1_0_S00_AXIS
    generic map(
      C_S_AXIS_TDATA_WIDTH => C_S00_AXIS_TDATA_WIDTH
    )
    port map
    (
      S_AXIS_ACLK    => s00_axi_aclk,
      S_AXIS_ARESETN => s00_axis_aresetn,
      S_AXIS_TREADY  => s00_axis_tready,
      S_AXIS_TDATA   => s00_axis_tdata,
      S_AXIS_TSTRB   => s00_axis_tstrb,
      S_AXIS_TLAST   => s00_axis_tlast,
      S_AXIS_TVALID  => s00_axis_tvalid
    );
  -- Add user logic here
  reset_active_high <= not s00_axi_aresetn;

  ascon_aead_inst : entity work.ascon_aead
    port map
    (
      clk_i                       => s00_axi_aclk,
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
      text_len_i                  => text_len_axi_lite
    );
  -- User logic ends

end arch_imp;
