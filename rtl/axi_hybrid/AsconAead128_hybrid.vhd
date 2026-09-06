library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity AsconAead128_hybrid is
	generic (
		-- Users to add parameters here

		-- User parameters ends
		-- Do not modify the parameters beyond this line


		-- Parameters of Axi Slave Bus Interface S00_AXI
		C_S00_AXI_DATA_WIDTH	: integer	:= 32;
		C_S00_AXI_ADDR_WIDTH	: integer	:= 7;

		-- Parameters of Axi Slave Bus Interface S00_AXIS
		C_S00_AXIS_TDATA_WIDTH	: integer	:= 32
	);
	port (
		-- Users to add ports here

		-- User ports ends
		-- Do not modify the ports beyond this line


		-- Ports of Axi Slave Bus Interface S00_AXI
		s00_axi_aclk	: in std_logic;
		s00_axi_aresetn	: in std_logic;
		s00_axi_awaddr	: in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
		s00_axi_awprot	: in std_logic_vector(2 downto 0);
		s00_axi_awvalid	: in std_logic;
		s00_axi_awready	: out std_logic;
		s00_axi_wdata	: in std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		s00_axi_wstrb	: in std_logic_vector((C_S00_AXI_DATA_WIDTH/8)-1 downto 0);
		s00_axi_wvalid	: in std_logic;
		s00_axi_wready	: out std_logic;
		s00_axi_bresp	: out std_logic_vector(1 downto 0);
		s00_axi_bvalid	: out std_logic;
		s00_axi_bready	: in std_logic;
		s00_axi_araddr	: in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
		s00_axi_arprot	: in std_logic_vector(2 downto 0);
		s00_axi_arvalid	: in std_logic;
		s00_axi_arready	: out std_logic;
		s00_axi_rdata	: out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		s00_axi_rresp	: out std_logic_vector(1 downto 0);
		s00_axi_rvalid	: out std_logic;
		s00_axi_rready	: in std_logic;

		-- Ports of Axi Slave Bus Interface S00_AXIS
		s00_axis_aclk	: in std_logic;
		s00_axis_aresetn	: in std_logic;
		s00_axis_tready	: out std_logic;
		s00_axis_tdata	: in std_logic_vector(C_S00_AXIS_TDATA_WIDTH-1 downto 0);
		s00_axis_tstrb	: in std_logic_vector((C_S00_AXIS_TDATA_WIDTH/8)-1 downto 0);
		s00_axis_tlast	: in std_logic;
		s00_axis_tvalid	: in std_logic
	);
end AsconAead128_hybrid;

architecture arch_imp of AsconAead128_hybrid is

    -- User signals
        signal reset_active_high : std_logic := '0';
    -- User signals end

begin
    
    AsconAead128_hybrid_slave_lite_v1_0_S00_AXI_inst: entity work.AsconAead128_hybrid_slave_lite_v1_0_S00_AXI
     generic map(
        C_S_AXI_DATA_WIDTH => C_S_AXI_DATA_WIDTH,
        C_S_AXI_ADDR_WIDTH => C_S_AXI_ADDR_WIDTH
    )
     port map(
        S_AXI_ACLK => S_AXI_ACLK,
        S_AXI_ARESETN => S_AXI_ARESETN,
        S_AXI_AWADDR => S_AXI_AWADDR,
        S_AXI_AWPROT => S_AXI_AWPROT,
        S_AXI_AWVALID => S_AXI_AWVALID,
        S_AXI_AWREADY => S_AXI_AWREADY,
        S_AXI_WDATA => S_AXI_WDATA,
        S_AXI_WSTRB => S_AXI_WSTRB,
        S_AXI_WVALID => S_AXI_WVALID,
        S_AXI_WREADY => S_AXI_WREADY,
        S_AXI_BRESP => S_AXI_BRESP,
        S_AXI_BVALID => S_AXI_BVALID,
        S_AXI_BREADY => S_AXI_BREADY,
        S_AXI_ARADDR => S_AXI_ARADDR,
        S_AXI_ARPROT => S_AXI_ARPROT,
        S_AXI_ARVALID => S_AXI_ARVALID,
        S_AXI_ARREADY => S_AXI_ARREADY,
        S_AXI_RDATA => S_AXI_RDATA,
        S_AXI_RRESP => S_AXI_RRESP,
        S_AXI_RVALID => S_AXI_RVALID,
        S_AXI_RREADY => S_AXI_RREADY
    );
    
    AsconAead128_hybrid_slave_stream_v1_0_S00_AXIS_inst: entity work.AsconAead128_hybrid_slave_stream_v1_0_S00_AXIS
     generic map(
        C_S_AXIS_TDATA_WIDTH => C_S_AXIS_TDATA_WIDTH
    )
     port map(
        S_AXIS_ACLK => S_AXIS_ACLK,
        S_AXIS_ARESETN => S_AXIS_ARESETN,
        S_AXIS_TREADY => S_AXIS_TREADY,
        S_AXIS_TDATA => S_AXIS_TDATA,
        S_AXIS_TSTRB => S_AXIS_TSTRB,
        S_AXIS_TLAST => S_AXIS_TLAST,
        S_AXIS_TVALID => S_AXIS_TVALID
    );
	-- Add user logic here


    reset_active_high <= not s00_axi_aresetn;

    ascon_aead_inst: entity work.ascon_aead
     port map(
        clk_i => s00_axi_aclk,
        reset_i => reset_active_high,
        start_i => start_i,
        associated_data_word_left_i => associated_data_word_left_i,
        plaintext_word_left_i => plaintext_word_left_i,
        encrypt_mode_i => encrypt_mode_i,
        input_ready_i => input_ready_i,
        start_core_o => start_core_o,
        finished_o => finished_o,
        text_ready_o => text_ready_o,
        word_processed_o => word_processed_o,
        key_i => key_i,
        nonce_i => nonce_i,
        assoc_data_i => assoc_data_i,
        text_i => text_i,
        text_o => text_o,
        tag_o => tag_o,
        text_len_i => text_len_i
    );
	-- User logic ends

end arch_imp;
