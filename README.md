# ASCON AEAD128 and Hash256

Cryptographic modules and their testbenches implementation targeting lightweight and embedded environments

## Implemented features

- Ascon Core state machine
- Ascon-AEAD128 encryption/decryption hardware module
- Ascon-Hash256 hardware module
- Cocotb testbenches for each module with KAT and constrained random value tests

## Development methods

I used Vivado for creating the project and the files. Both VHDL and Python development was done in VSCodium with the help of TerosHDL extension. Testbenches are utilising cocotb a modern choice for testbenches that is both capable and accessible. I used ghdl for the simulation and GTKWave for debugging using the waveforms.

I have developed the project incrementally and comparing it at each step to the reference software implementation taken from https://github.com/meichlseder/pyascon.git. Many thanks to its developers.

The produced KATs cover many edge cases including both empty, padding-aligned and non-aligned inputs.

## Notes on usage

Currently the axi-lite interface for the modules is WIP.

The modules can be observed using the testbenches:

Make sure to have the following dependencies: 
* `make`
* `ghdl`
* `python3` (with `venv`)

Linux:

```bash
git clone git@github.com:PeterG-12/ascon-crypto.git ascon-crypto
cd ascon-crypto/sim
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cd tb_ascon_aead # or cd tb_ascon_hash
make