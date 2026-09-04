# NIST SP 800-232 ASCON AEAD128 (and Hash256)

Hardware software co-development repository showcasing development in parallel in VHDL, Python (cocotb testbench) and C. The aim of the repository is to provide a verified implementation of an Ascon AEAD-128 hardware accelerator that is viable (in terms of space and running time) for deployment on any SoC with constrained resources. The goal of the repository is also to showcase the comparison of the speed of the hardware implementation to software implementations running on different CPUs. The hardware implementation was based on the algorithms presented in [NIST Special Publication 800-232](https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-232.pdf).

The repository includes a bare-metal C driver that was loaded onto the [NEORV32 processor](https://github.com/stnolting/neorv32.git) running on the [Artix-7 Wukong Dev Board FPGA](https://github.com/ChinaQMTECH/QM_XC7A100T_WUKONG_BOARD.git) and handles the handshaking and MMIO of the hardware module. Currently the example can be accessed through a simple CLI program over UART. This was also verified with KATs and its benchmarks can be seen in the tables below.

## Features

* Ascon Core state machine
* Ascon-AEAD128 encryption/decryption hardware module
* Ascon-Hash256 hardware module
* Cocotb testbenches for each module with KAT and constrained random value tests
* Ascon-AEAD128 AXI-Lite peripheral hardware module and cocotb testbench with KAT
* Polling based bare-metal C driver deployable onto the NEORV32
* Interrupt based version of C driver using RISC-V's MEI

## Toolchain & Development Methodology

The produced KATs cover many edge cases including both empty, padding-aligned and non-aligned inputs.
The project was developed incrementally, performing comparisons at each step against the reference software implementation taken from [pyascon](https://github.com/meichlseder/pyascon.git). 

* **HDL:** [TerosHDL](https://terostechnology.github.io) extension for VSCodium
* **Verification:** Testbenches utilize [cocotb](https://www.cocotb.org/) (a modern choice that is both capable and accessible) and [GHDL](https://github.com/ghdl/ghdl.git) as a simulator, with GTKWave for debugging waveforms.
* **FPGA Synthesis & Implementation:** AMD Vivado
* **Driver & Debugging:** Clangd was used as the linter. For hardware debugging through NEORV32's JTAG interface, [OpenOCD](https://github.com/openocd-org/openocd) was used with a helpful [JTAG firmware](https://github.com/lonehog/JTAGprobe) flashed onto a cheap Raspberry Pi Pico. With these tools it is simple to connect to the board and debug the program in GDB both via its TUI and with a promising GDB GUI, [seergdb](https://github.com/epasveer/seer.git).

Many thanks to all developers that provided these tools.

## Synthesis and Implementation information
Elements used by the AsconAead128 axi-lite module

| Resource | Utilization |
| --- | --- |
| **Slice LUTs** | 2,296 |
| **LUT as Memory** | 0 |
| **Slice Registers** | 2,554 |
| **Slices** | 770 |
| **F7 Muxes** | 96 |
| **Block RAM (BRAM)** | 0 |

Vivado timing analysis for the whole SoC confirms that the timing closures across the entire SoC with headroom to run at even higher frequencies 
(It was synthesised for 50MHz)

Setup WNS: 8.544 ns (Met)
Hold WHS: 0.061 ns (Met)
Pulse Width WPWS: 7.0 ns (Met)


## Notes on usage

The modules can be observed using the testbenches:

Make sure to have the following dependencies:

* `make`
* `ghdl`
* `python3` (with `venv`)

Linux:

```bash
git clone https://github.com/PeterG-12/ascon-crypto.git ascon-crypto
cd ascon-crypto/sim
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cd tb_ascon_aead # or cd tb_ascon_hash or tb_axi_aead
make
```

## Ascon accelerator benchmark

The raw results from benchmarking can be found in the table below.
Note: the constant 161 cycle difference between encryption stems from tag checking in decryption

| Message Length | Encryption (Cycles) | Decryption & Tag Checking (Cycles) | Cocotb Encryption (Cycles) |
| --- | --- | --- | --- |
| 1 Byte | 940 | 1,101 | 113 |
| 8 Bytes | 940 | 1,101 | 113 |
| 16 Bytes | 1,132 | 1,293 | 140 |
| 32 Bytes | 1,397 | 1,558 | 179 |
| 64 Bytes | 1,927 | 2,088 | 257 |
| 1,536 Bytes | 26,307 | 26,468 | 3,845 |

Results translated to cycles per byte.

| Message Length | NEORV32 SoC Encryption (cpb) | Cocotb Simulation Encryption (cpb) |
| --- | --- | --- |
| 1 Byte | 940.00 | 113.00 |
| 8 Bytes | 117.50 | 14.13 |
| 16 Bytes | 70.75 | 8.75 |
| 32 Bytes | 43.66 | 5.59 |
| 64 Bytes | 30.11 | 4.02 |
| 1,536 Bytes | 17.13 | 2.50 |

## Comparison to estimated performance results on different CPUs in cycles per byte

Taken from [ascon-c](https://github.com/ascon/ascon-c.git)

| Message Length in Bytes | 1 | 8 | 16 | 32 | 64 | 1536 | long |
| --- | --- | --- | --- | --- | --- | --- | --- |
| AMD EPYC 7742* |  |  |  |  | 7.4 | 4.4 | 4.2 |
| AMD Ryzen 9 5950X* |  |  |  |  | 8.1 | 5.3 | 5.2 |
| Apple M1 (ARMv8)* |  |  |  |  | 9.4 | 6.3 | 6.3 |
| Cortex-A72 (ARMv8)* |  |  |  |  | 10.9 | 7.2 | 7.0 |
| Intel Xeon E5-2609 v4* |  |  |  |  | 11.3 | 7.4 | 7.2 |
| Intel Core i5-6300U | 365 | 47 | 31 | 19 | 13.5 | 8.0 | 7.8 |
| Intel Core i5-4200U | 519 | 67 | 44 | 27 | 18.8 | 11.0 | 10.6 |
| Cortex-A9 (ARMv7)* |  |  |  |  | 42.8 | 24.6 | 24.0 |
| Cortex-A7 (NEON) | 2204 | 226 | 132 | 82 | 55.9 | 31.7 | 30.7 |
| Cortex-A7 (ARMv7)* |  |  |  |  | 55.5 | 38.2 | 37.5 |
| ARM1176JZF-S (ARMv6) | 1908 | 235 | 156 | 99 | 70.4 | 43.0 | 42.9 |
| **NEORV32 + AXI-Lite HW module SoC (RISC-V)** | **940** | **117.5** | **70.8** | **43.7** | **30.1** | **17.1** | **~16.6** |
| **Cocotb HW Simulation** | **113** | **14.1** | **8.8** | **5.6** | **4.0** | **2.5** | **~2.4** |