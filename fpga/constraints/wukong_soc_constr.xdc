## ==============================================================================
## QMTECH-XC7A100T_200T-WUKONG-BOARD V03 Master XDC File
## ==============================================================================

## ------------------------------------------------------------------------------
## Configuration & Bitstream Settings
## ------------------------------------------------------------------------------
#set_property CFGBVS VCCO [current_design]
#set_property CONFIG_VOLTAGE 3.3 [current_design]
#set_property BITSTREAM.CONFIG.UNUSEDPIN PULLUP [current_design]
#set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
#set_property CONFIG_MODE SPIx4 [current_design]
#set_property BITSTREAM.CONFIG.CONFIGRATE 50 [current_design]

## ------------------------------------------------------------------------------
## System Clock & Reset
## ------------------------------------------------------------------------------
set_property -dict { PACKAGE_PIN M21 IOSTANDARD LVCMOS33 } [get_ports { clk_0 }]
create_clock -period 20.000 -name clk_0 -waveform {0 10} [get_ports { clk_0 }]
#set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets {sys_clk_IBUF}]

set_property -dict { PACKAGE_PIN H7  IOSTANDARD LVCMOS33 } [get_ports { resetn_0 }]
#set_property -dict { PACKAGE_PIN M6  IOSTANDARD LVCMOS33 } [get_ports { button2 }]


set_property SEVERITY {Warning} [get_drc_checks LUTLP-1]

## ------------------------------------------------------------------------------
## User LEDs
## ------------------------------------------------------------------------------
#set_property -dict { PACKAGE_PIN G21 IOSTANDARD LVCMOS33 } [get_ports { led[0] }]
#set_property -dict { PACKAGE_PIN G20 IOSTANDARD LVCMOS33 } [get_ports { led[1] }]

## ------------------------------------------------------------------------------
## UART (CH340N)
## ------------------------------------------------------------------------------
set_property -dict { PACKAGE_PIN F3  IOSTANDARD LVCMOS33 } [get_ports { uart0_rxd_i_0 }]
set_property -dict { PACKAGE_PIN E3  IOSTANDARD LVCMOS33 } [get_ports { uart0_txd_o_0 }]

## ------------------------------------------------------------------------------
## Micro SD Card
## ------------------------------------------------------------------------------
#set_property -dict { PACKAGE_PIN H8  IOSTANDARD LVCMOS33 } [get_ports { sd_dat2 }]
#set_property -dict { PACKAGE_PIN J6  IOSTANDARD LVCMOS33 } [get_ports { sd_dat3_cd }]
#set_property -dict { PACKAGE_PIN L4  IOSTANDARD LVCMOS33 } [get_ports { sd_clk }]
#set_property -dict { PACKAGE_PIN J8  IOSTANDARD LVCMOS33 } [get_ports { sd_cmd }]
#set_property -dict { PACKAGE_PIN M5  IOSTANDARD LVCMOS33 } [get_ports { sd_dat0 }]
#set_property -dict { PACKAGE_PIN M7  IOSTANDARD LVCMOS33 } [get_ports { sd_dat1 }]
#set_property -dict { PACKAGE_PIN N6  IOSTANDARD LVCMOS33 } [get_ports { sd_cd_det }]

## ------------------------------------------------------------------------------
## HDMI (TPD12S016 Level Shifter)
## ------------------------------------------------------------------------------
#set_property -dict { PACKAGE_PIN D4  IOSTANDARD TMDS_33 } [get_ports { TMDS_clk_p }]
#set_property -dict { PACKAGE_PIN C4  IOSTANDARD TMDS_33 } [get_ports { TMDS_clk_n }]
#set_property -dict { PACKAGE_PIN E1  IOSTANDARD TMDS_33 } [get_ports { TMDS_data_p[0] }]
#set_property -dict { PACKAGE_PIN D1  IOSTANDARD TMDS_33 } [get_ports { TMDS_data_n[0] }]
#set_property -dict { PACKAGE_PIN F2  IOSTANDARD TMDS_33 } [get_ports { TMDS_data_p[1] }]
#set_property -dict { PACKAGE_PIN E2  IOSTANDARD TMDS_33 } [get_ports { TMDS_data_n[1] }]
#set_property -dict { PACKAGE_PIN G2  IOSTANDARD TMDS_33 } [get_ports { TMDS_data_p[2] }]
#set_property -dict { PACKAGE_PIN G1  IOSTANDARD TMDS_33 } [get_ports { TMDS_data_n[2] }]

## ------------------------------------------------------------------------------
## Gigabit Ethernet (RTL8211EG)
## ------------------------------------------------------------------------------
#set_property -dict { PACKAGE_PIN R1  IOSTANDARD LVCMOS33 } [get_ports { e_reset }]
#set_property -dict { PACKAGE_PIN H1  IOSTANDARD LVCMOS33 } [get_ports { e_mdio }]
#set_property -dict { PACKAGE_PIN H2  IOSTANDARD LVCMOS33 } [get_ports { e_mdc }]
#set_property -dict { PACKAGE_PIN U1  IOSTANDARD LVCMOS33 } [get_ports { e_gtxc }]

## TX
#set_property -dict { PACKAGE_PIN M2  IOSTANDARD LVCMOS33 } [get_ports { e_txc }]
#set_property -dict { PACKAGE_PIN T2  IOSTANDARD LVCMOS33 } [get_ports { e_txen }]
#set_property -dict { PACKAGE_PIN J1  IOSTANDARD LVCMOS33 } [get_ports { e_txer }]
#set_property -dict { PACKAGE_PIN R2  IOSTANDARD LVCMOS33 } [get_ports { e_txd[0] }]
#set_property -dict { PACKAGE_PIN P1  IOSTANDARD LVCMOS33 } [get_ports { e_txd[1] }]
#set_property -dict { PACKAGE_PIN N2  IOSTANDARD LVCMOS33 } [get_ports { e_txd[2] }]
#set_property -dict { PACKAGE_PIN N1  IOSTANDARD LVCMOS33 } [get_ports { e_txd[3] }]
#set_property -dict { PACKAGE_PIN M1  IOSTANDARD LVCMOS33 } [get_ports { e_txd[4] }]
#set_property -dict { PACKAGE_PIN L2  IOSTANDARD LVCMOS33 } [get_ports { e_txd[5] }]
#set_property -dict { PACKAGE_PIN K2  IOSTANDARD LVCMOS33 } [get_ports { e_txd[6] }]
#set_property -dict { PACKAGE_PIN K1  IOSTANDARD LVCMOS33 } [get_ports { e_txd[7] }]

## RX
#set_property -dict { PACKAGE_PIN P4  IOSTANDARD LVCMOS33 } [get_ports { e_rxc }]
#set_property -dict { PACKAGE_PIN L3  IOSTANDARD LVCMOS33 } [get_ports { e_rxdv }]
#set_property -dict { PACKAGE_PIN U5  IOSTANDARD LVCMOS33 } [get_ports { e_rxer }]
#set_property -dict { PACKAGE_PIN M4  IOSTANDARD LVCMOS33 } [get_ports { e_rxd[0] }]
#set_property -dict { PACKAGE_PIN N3  IOSTANDARD LVCMOS33 } [get_ports { e_rxd[1] }]
#set_property -dict { PACKAGE_PIN N4  IOSTANDARD LVCMOS33 } [get_ports { e_rxd[2] }]
#set_property -dict { PACKAGE_PIN P3  IOSTANDARD LVCMOS33 } [get_ports { e_rxd[3] }]
#set_property -dict { PACKAGE_PIN R3  IOSTANDARD LVCMOS33 } [get_ports { e_rxd[4] }]
#set_property -dict { PACKAGE_PIN T3  IOSTANDARD LVCMOS33 } [get_ports { e_rxd[5] }]
#set_property -dict { PACKAGE_PIN T4  IOSTANDARD LVCMOS33 } [get_ports { e_rxd[6] }]
#set_property -dict { PACKAGE_PIN T5  IOSTANDARD LVCMOS33 } [get_ports { e_rxd[7] }]

## ------------------------------------------------------------------------------
## SDRAM (Standard - IS42S16160G or similar)
## ------------------------------------------------------------------------------
#set_property -dict { PACKAGE_PIN G22 IOSTANDARD LVCMOS33 } [get_ports { SDCLK0 }]
#set_property -dict { PACKAGE_PIN H22 IOSTANDARD LVCMOS33 } [get_ports { SDCKE0 }]
#set_property -dict { PACKAGE_PIN L25 IOSTANDARD LVCMOS33 } [get_ports { SDCS0 }]
#set_property -dict { PACKAGE_PIN K26 IOSTANDARD LVCMOS33 } [get_ports { RAS }]
#set_property -dict { PACKAGE_PIN K25 IOSTANDARD LVCMOS33 } [get_ports { CAS }]
#set_property -dict { PACKAGE_PIN J26 IOSTANDARD LVCMOS33 } [get_ports { SDWE }]

#set_property -dict { PACKAGE_PIN M25 IOSTANDARD LVCMOS33 } [get_ports { Bank[0] }]
#set_property -dict { PACKAGE_PIN M26 IOSTANDARD LVCMOS33 } [get_ports { Bank[1] }]
#set_property -dict { PACKAGE_PIN J25 IOSTANDARD LVCMOS33 } [get_ports { DQM[0] }]
#set_property -dict { PACKAGE_PIN K23 IOSTANDARD LVCMOS33 } [get_ports { DQM[1] }]

#set_property -dict { PACKAGE_PIN R26 IOSTANDARD LVCMOS33 } [get_ports { Address[0] }]
#set_property -dict { PACKAGE_PIN P25 IOSTANDARD LVCMOS33 } [get_ports { Address[1] }]
#set_property -dict { PACKAGE_PIN P26 IOSTANDARD LVCMOS33 } [get_ports { Address[2] }]
#set_property -dict { PACKAGE_PIN N26 IOSTANDARD LVCMOS33 } [get_ports { Address[3] }]
#set_property -dict { PACKAGE_PIN M24 IOSTANDARD LVCMOS33 } [get_ports { Address[4] }]
#set_property -dict { PACKAGE_PIN M22 IOSTANDARD LVCMOS33 } [get_ports { Address[5] }]
#set_property -dict { PACKAGE_PIN L24 IOSTANDARD LVCMOS33 } [get_ports { Address[6] }]
#set_property -dict { PACKAGE_PIN L23 IOSTANDARD LVCMOS33 } [get_ports { Address[7] }]
#set_property -dict { PACKAGE_PIN L22 IOSTANDARD LVCMOS33 } [get_ports { Address[8] }]
#set_property -dict { PACKAGE_PIN K21 IOSTANDARD LVCMOS33 } [get_ports { Address[9] }]
#set_property -dict { PACKAGE_PIN R25 IOSTANDARD LVCMOS33 } [get_ports { Address[10] }]
#set_property -dict { PACKAGE_PIN K22 IOSTANDARD LVCMOS33 } [get_ports { Address[11] }]
#set_property -dict { PACKAGE_PIN J21 IOSTANDARD LVCMOS33 } [get_ports { Address[12] }]

#set_property -dict { PACKAGE_PIN D25 IOSTANDARD LVCMOS33 } [get_ports { Data[0] }]
#set_property -dict { PACKAGE_PIN D26 IOSTANDARD LVCMOS33 } [get_ports { Data[1] }]
#set_property -dict { PACKAGE_PIN E25 IOSTANDARD LVCMOS33 } [get_ports { Data[2] }]
#set_property -dict { PACKAGE_PIN E26 IOSTANDARD LVCMOS33 } [get_ports { Data[3] }]
#set_property -dict { PACKAGE_PIN F25 IOSTANDARD LVCMOS33 } [get_ports { Data[4] }]
#set_property -dict { PACKAGE_PIN G25 IOSTANDARD LVCMOS33 } [get_ports { Data[5] }]
#set_property -dict { PACKAGE_PIN G26 IOSTANDARD LVCMOS33 } [get_ports { Data[6] }]
#set_property -dict { PACKAGE_PIN H26 IOSTANDARD LVCMOS33 } [get_ports { Data[7] }]
#set_property -dict { PACKAGE_PIN J24 IOSTANDARD LVCMOS33 } [get_ports { Data[8] }]
#set_property -dict { PACKAGE_PIN J23 IOSTANDARD LVCMOS33 } [get_ports { Data[9] }]
#set_property -dict { PACKAGE_PIN H24 IOSTANDARD LVCMOS33 } [get_ports { Data[10] }]
#set_property -dict { PACKAGE_PIN H23 IOSTANDARD LVCMOS33 } [get_ports { Data[11] }]
#set_property -dict { PACKAGE_PIN G24 IOSTANDARD LVCMOS33 } [get_ports { Data[12] }]
#set_property -dict { PACKAGE_PIN F24 IOSTANDARD LVCMOS33 } [get_ports { Data[13] }]
#set_property -dict { PACKAGE_PIN F23 IOSTANDARD LVCMOS33 } [get_ports { Data[14] }]
#set_property -dict { PACKAGE_PIN E23 IOSTANDARD LVCMOS33 } [get_ports { Data[15] }]

## ------------------------------------------------------------------------------
## DDR3 Memory (MT41K128M16JT-125:K)
## Note: Board features both SDRAM and DDR3 interfaces.
## ------------------------------------------------------------------------------
#set_property -dict { PACKAGE_PIN H17 IOSTANDARD SSTL135 } [get_ports { ddr3_reset_n }]
#set_property -dict { PACKAGE_PIN F18 IOSTANDARD DIFF_SSTL135 } [get_ports { ddr3_clk_p }]
#set_property -dict { PACKAGE_PIN F19 IOSTANDARD DIFF_SSTL135 } [get_ports { ddr3_clk_n }]
#set_property -dict { PACKAGE_PIN E18 IOSTANDARD SSTL135 } [get_ports { ddr3_cke }]
#set_property -dict { PACKAGE_PIN B19 IOSTANDARD SSTL135 } [get_ports { ddr3_cas_n }]
#set_property -dict { PACKAGE_PIN A19 IOSTANDARD SSTL135 } [get_ports { ddr3_ras_n }]
#set_property -dict { PACKAGE_PIN A18 IOSTANDARD SSTL135 } [get_ports { ddr3_we_n }]
#set_property -dict { PACKAGE_PIN G19 IOSTANDARD SSTL135 } [get_ports { ddr3_odt }]
#set_property -dict { PACKAGE_PIN B17 IOSTANDARD SSTL135 } [get_ports { ddr3_ba[0] }]
#set_property -dict { PACKAGE_PIN B18 IOSTANDARD SSTL135 } [get_ports { ddr3_ba[1] }]
#set_property -dict { PACKAGE_PIN A17 IOSTANDARD SSTL135 } [get_ports { ddr3_ba[2] }]
#set_property -dict { PACKAGE_PIN J18 IOSTANDARD SSTL135 } [get_ports { ddr3_addr[0] }]
#set_property -dict { PACKAGE_PIN G17 IOSTANDARD SSTL135 } [get_ports { ddr3_addr[1] }]
#set_property -dict { PACKAGE_PIN J17 IOSTANDARD SSTL135 } [get_ports { ddr3_addr[2] }]
#set_property -dict { PACKAGE_PIN J16 IOSTANDARD SSTL135 } [get_ports { ddr3_addr[3] }]
#set_property -dict { PACKAGE_PIN G16 IOSTANDARD SSTL135 } [get_ports { ddr3_addr[4] }]
#set_property -dict { PACKAGE_PIN D16 IOSTANDARD SSTL135 } [get_ports { ddr3_addr[5] }]
#set_property -dict { PACKAGE_PIN H16 IOSTANDARD SSTL135 } [get_ports { ddr3_addr[6] }]
#set_property -dict { PACKAGE_PIN E16 IOSTANDARD SSTL135 } [get_ports { ddr3_addr[7] }]
#set_property -dict { PACKAGE_PIN H14 IOSTANDARD SSTL135 } [get_ports { ddr3_addr[8] }]
#set_property -dict { PACKAGE_PIN F15 IOSTANDARD SSTL135 } [get_ports { ddr3_addr[9] }]
#set_property -dict { PACKAGE_PIN F20 IOSTANDARD SSTL135 } [get_ports { ddr3_addr[10] }]
#set_property -dict { PACKAGE_PIN H15 IOSTANDARD SSTL135 } [get_ports { ddr3_addr[11] }]
#set_property -dict { PACKAGE_PIN C18 IOSTANDARD SSTL135 } [get_ports { ddr3_addr[12] }]
#set_property -dict { PACKAGE_PIN J15 IOSTANDARD SSTL135 } [get_ports { ddr3_addr[13] }]
#set_property -dict { PACKAGE_PIN A22 IOSTANDARD SSTL135 } [get_ports { ddr3_dqm[0] }]
#set_property -dict { PACKAGE_PIN C22 IOSTANDARD SSTL135 } [get_ports { ddr3_dqm[1] }]
#set_property -dict { PACKAGE_PIN B20 IOSTANDARD DIFF_SSTL135 } [get_ports { ddr3_dqs_p[0] }]
#set_property -dict { PACKAGE_PIN A20 IOSTANDARD DIFF_SSTL135 } [get_ports { ddr3_dqs_n[0] }]
#set_property -dict { PACKAGE_PIN A25 IOSTANDARD DIFF_SSTL135 } [get_ports { ddr3_dqs_p[1] }]
#set_property -dict { PACKAGE_PIN A24 IOSTANDARD DIFF_SSTL135 } [get_ports { ddr3_dqs_n[1] }]
#set_property -dict { PACKAGE_PIN E21 IOSTANDARD SSTL135 } [get_ports { ddr3_dq[0] }]
#set_property -dict { PACKAGE_PIN C21 IOSTANDARD SSTL135 } [get_ports { ddr3_dq[1] }]
#set_property -dict { PACKAGE_PIN B22 IOSTANDARD SSTL135 } [get_ports { ddr3_dq[2] }]
#set_property -dict { PACKAGE_PIN B21 IOSTANDARD SSTL135 } [get_ports { ddr3_dq[3] }]
#set_property -dict { PACKAGE_PIN D19 IOSTANDARD SSTL135 } [get_ports { ddr3_dq[4] }]
#set_property -dict { PACKAGE_PIN D21 IOSTANDARD SSTL135 } [get_ports { ddr3_dq[5] }]
#set_property -dict { PACKAGE_PIN C19 IOSTANDARD SSTL135 } [get_ports { ddr3_dq[6] }]
#set_property -dict { PACKAGE_PIN D20 IOSTANDARD SSTL135 } [get_ports { ddr3_dq[7] }]
#set_property -dict { PACKAGE_PIN C23 IOSTANDARD SSTL135 } [get_ports { ddr3_dq[8] }]
#set_property -dict { PACKAGE_PIN D23 IOSTANDARD SSTL135 } [get_ports { ddr3_dq[9] }]
#set_property -dict { PACKAGE_PIN B24 IOSTANDARD SSTL135 } [get_ports { ddr3_dq[10] }]
#set_property -dict { PACKAGE_PIN B25 IOSTANDARD SSTL135 } [get_ports { ddr3_dq[11] }]
#set_property -dict { PACKAGE_PIN C24 IOSTANDARD SSTL135 } [get_ports { ddr3_dq[12] }]
#set_property -dict { PACKAGE_PIN C26 IOSTANDARD SSTL135 } [get_ports { ddr3_dq[13] }]
#set_property -dict { PACKAGE_PIN A23 IOSTANDARD SSTL135 } [get_ports { ddr3_dq[14] }]
#set_property -dict { PACKAGE_PIN B26 IOSTANDARD SSTL135 } [get_ports { ddr3_dq[15] }]

## ------------------------------------------------------------------------------
## PMOD J11 (Bank 35)
## ------------------------------------------------------------------------------
#set_property -dict { PACKAGE_PIN H4 IOSTANDARD LVCMOS33 } [get_ports { pmod_j11[0] }]
#set_property -dict { PACKAGE_PIN F4 IOSTANDARD LVCMOS33 } [get_ports { pmod_j11[1] }]
#set_property -dict { PACKAGE_PIN A4 IOSTANDARD LVCMOS33 } [get_ports { pmod_j11[2] }]
#set_property -dict { PACKAGE_PIN A5 IOSTANDARD LVCMOS33 } [get_ports { pmod_j11[3] }]
#set_property -dict { PACKAGE_PIN J4 IOSTANDARD LVCMOS33 } [get_ports { pmod_j11[4] }]
#set_property -dict { PACKAGE_PIN G4 IOSTANDARD LVCMOS33 } [get_ports { pmod_j11[5] }]
#set_property -dict { PACKAGE_PIN B4 IOSTANDARD LVCMOS33 } [get_ports { pmod_j11[6] }]
#set_property -dict { PACKAGE_PIN B5 IOSTANDARD LVCMOS33 } [get_ports { pmod_j11[7] }]


## ------------------------------------------------------------------------------
## GPIO J12 (Bank 13)
## ------------------------------------------------------------------------------
#set_property -dict { PACKAGE_PIN U14 IOSTANDARD LVCMOS33 } [get_ports { gpio[3] }]
#set_property -dict { PACKAGE_PIN V14 IOSTANDARD LVCMOS33 } [get_ports { gpio[4] }]
set_property -dict { PACKAGE_PIN U15 IOSTANDARD LVCMOS33 PULLUP true } [get_ports { jtag_tdi_i_0 }]
set_property -dict { PACKAGE_PIN U16 IOSTANDARD LVCMOS33 PULLUP true } [get_ports { jtag_tms_i_0 }]
set_property -dict { PACKAGE_PIN V16 IOSTANDARD LVCMOS33 PULLDOWN true } [get_ports { jtag_tdo_o_0 }]
set_property -dict { PACKAGE_PIN V17 IOSTANDARD LVCMOS33 PULLDOWN true } [get_ports { jtag_tck_i_0 }]
#set_property -dict { PACKAGE_PIN W18 IOSTANDARD LVCMOS33 } [get_ports { gpio[10] }]
#set_property -dict { PACKAGE_PIN V19 IOSTANDARD LVCMOS33 } [get_ports { gpio[11] }]
#set_property -dict { PACKAGE_PIN W19 IOSTANDARD LVCMOS33 } [get_ports { gpio[12] }]
#set_property -dict { PACKAGE_PIN T20 IOSTANDARD LVCMOS33 } [get_ports { gpio[13] }]
#set_property -dict { PACKAGE_PIN U20 IOSTANDARD LVCMOS33 } [get_ports { gpio[14] }]
#set_property -dict { PACKAGE_PIN W21 IOSTANDARD LVCMOS33 } [get_ports { gpio[15] }]
#set_property -dict { PACKAGE_PIN Y21 IOSTANDARD LVCMOS33 } [get_ports { gpio[16] }]
#set_property -dict { PACKAGE_PIN U22 IOSTANDARD LVCMOS33 } [get_ports { gpio[17] }]
#set_property -dict { PACKAGE_PIN V22 IOSTANDARD LVCMOS33 } [get_ports { gpio[18] }]
#set_property -dict { PACKAGE_PIN V23 IOSTANDARD LVCMOS33 } [get_ports { gpio[19] }]
#set_property -dict { PACKAGE_PIN W23 IOSTANDARD LVCMOS33 } [get_ports { gpio[20] }]
#set_property -dict { PACKAGE_PIN AB24 IOSTANDARD LVCMOS33 } [get_ports { gpio[21] }]
#set_property -dict { PACKAGE_PIN AC24 IOSTANDARD LVCMOS33 } [get_ports { gpio[22] }]
#set_property -dict { PACKAGE_PIN AA24 IOSTANDARD LVCMOS33 } [get_ports { gpio[23] }]
#set_property -dict { PACKAGE_PIN AB25 IOSTANDARD LVCMOS33 } [get_ports { gpio[24] }]
#set_property -dict { PACKAGE_PIN V24 IOSTANDARD LVCMOS33 } [get_ports { gpio[25] }]
#set_property -dict { PACKAGE_PIN W24 IOSTANDARD LVCMOS33 } [get_ports { gpio[26] }]
#set_property -dict { PACKAGE_PIN AB26 IOSTANDARD LVCMOS33 } [get_ports { gpio[27] }]
#set_property -dict { PACKAGE_PIN AC26 IOSTANDARD LVCMOS33 } [get_ports { gpio[28] }]
#set_property -dict { PACKAGE_PIN Y25 IOSTANDARD LVCMOS33 } [get_ports { gpio[29] }]
#set_property -dict { PACKAGE_PIN AA25 IOSTANDARD LVCMOS33 } [get_ports { gpio[30] }]
#set_property -dict { PACKAGE_PIN W25 IOSTANDARD LVCMOS33 } [get_ports { gpio[31] }]
#set_property -dict { PACKAGE_PIN Y26 IOSTANDARD LVCMOS33 } [get_ports { gpio[32] }]
#set_property -dict { PACKAGE_PIN V26 IOSTANDARD LVCMOS33 } [get_ports { gpio[33] }]
#set_property -dict { PACKAGE_PIN W26 IOSTANDARD LVCMOS33 } [get_ports { gpio[34] }]
#set_property -dict { PACKAGE_PIN U25 IOSTANDARD LVCMOS33 } [get_ports { gpio[35] }]
#set_property -dict { PACKAGE_PIN U26 IOSTANDARD LVCMOS33 } [get_ports { gpio[36] }]
## ------------------------------------------------------------------------------
## PMOD J10 (Bank 35)
## ------------------------------------------------------------------------------
#set_property -dict { PACKAGE_PIN D5 IOSTANDARD LVCMOS33 } [get_ports { pmod_j10[0] }]
#set_property -dict { PACKAGE_PIN G5 IOSTANDARD LVCMOS33 } [get_ports { pmod_j10[1] }]
#set_property -dict { PACKAGE_PIN G7 IOSTANDARD LVCMOS33 } [get_ports { pmod_j10[2] }]
#set_property -dict { PACKAGE_PIN G8 IOSTANDARD LVCMOS33 } [get_ports { pmod_j10[3] }]
#set_property -dict { PACKAGE_PIN E5 IOSTANDARD LVCMOS33 } [get_ports { pmod_j10[4] }]
#set_property -dict { PACKAGE_PIN E6 IOSTANDARD LVCMOS33 } [get_ports { pmod_j10[5] }]
#set_property -dict { PACKAGE_PIN D6 IOSTANDARD LVCMOS33 } [get_ports { pmod_j10[6] }]
#set_property -dict { PACKAGE_PIN G6 IOSTANDARD LVCMOS33 } [get_ports { pmod_j10[7] }]

## ------------------------------------------------------------------------------
## PMOD J13 (Bank 14)
## ------------------------------------------------------------------------------
#set_property -dict { PACKAGE_PIN N22 IOSTANDARD LVCMOS33 } [get_ports { pmod_j13[0] }]
#set_property -dict { PACKAGE_PIN N21 IOSTANDARD LVCMOS33 } [get_ports { pmod_j13[1] }]
#set_property -dict { PACKAGE_PIN R20 IOSTANDARD LVCMOS33 } [get_ports { pmod_j13[2] }]
#set_property -dict { PACKAGE_PIN T22 IOSTANDARD LVCMOS33 } [get_ports { pmod_j13[3] }]
#set_property -dict { PACKAGE_PIN P20 IOSTANDARD LVCMOS33 } [get_ports { pmod_j13[4] }]
#set_property -dict { PACKAGE_PIN N23 IOSTANDARD LVCMOS33 } [get_ports { pmod_j13[5] }]
#set_property -dict { PACKAGE_PIN P21 IOSTANDARD LVCMOS33 } [get_ports { pmod_j13[6] }]
#set_property -dict { PACKAGE_PIN R21 IOSTANDARD LVCMOS33 } [get_ports { pmod_j13[7] }]

## ------------------------------------------------------------------------------
## PMOD J14 (Bank 14)
## ------------------------------------------------------------------------------
#set_property -dict { PACKAGE_PIN P23 IOSTANDARD LVCMOS33 } [get_ports { pmod_j14[0] }]
#set_property -dict { PACKAGE_PIN R23 IOSTANDARD LVCMOS33 } [get_ports { pmod_j14[1] }]
#set_property -dict { PACKAGE_PIN T24 IOSTANDARD LVCMOS33 } [get_ports { pmod_j14[2] }]
#set_property -dict { PACKAGE_PIN T25 IOSTANDARD LVCMOS33 } [get_ports { pmod_j14[3] }]
#set_property -dict { PACKAGE_PIN N24 IOSTANDARD LVCMOS33 } [get_ports { pmod_j14[4] }]
#set_property -dict { PACKAGE_PIN P24 IOSTANDARD LVCMOS33 } [get_ports { pmod_j14[5] }]
#set_property -dict { PACKAGE_PIN R22 IOSTANDARD LVCMOS33 } [get_ports { pmod_j14[6] }]
#set_property -dict { PACKAGE_PIN T23 IOSTANDARD LVCMOS33 } [get_ports { pmod_j14[7] }]
