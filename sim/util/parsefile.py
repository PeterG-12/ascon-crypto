from dataclasses import dataclass

def parse_hash_file(file_name):
    kat_directory = {}

    with open(file_name, "r") as f:
        lines = f.readlines()
        msg = ""
        for line in lines:
            split_line = line.split(" = ")
            if "Msg" in line:
                msg = split_line[1].strip().lower()
            if "MD" in line:
                kat_directory[msg] = split_line[1].strip().lower()
    
    return kat_directory


@dataclass(frozen=True)
class AeadEncrypt:
    key: str
    nonce: str
    pt: str
    ad: str

def parse_aead_encrypt_file(file_name):
    kat_directory = {}

    with open(file_name, "r") as f:
        lines = f.readlines()
        
        key = ""
        nonce = ""
        ad = ""
        pt = ""


        for line in lines:
            split = line.split(" = ", 1)
            keystring = split[0]
            valstring = ""
            if len(split) > 1: 
                keystring, valstring = line.split("=", 1)
                valstring = valstring.strip().lower()

            if "Key" in keystring:
                key = valstring
            if "Nonce" in keystring:
                nonce = valstring
            if "PT" in keystring:
                pt = valstring
            if "AD" in keystring:
                ad = valstring
            if "CT" in keystring:
                obj = AeadEncrypt(key, nonce, pt, ad)
                kat_directory[obj] = valstring
    
    return kat_directory

def parse_aead_decrypt_file(file_name):
    kat_directory = {}

    with open(file_name, "r") as f:
        lines = f.readlines()
        
        key = ""
        nonce = ""
        ad = ""
        pt = ""


        for line in lines:
            split = line.split(" = ", 1)
            keystring = split[0]
            valstring = ""
            if len(split) > 1: 
                keystring, valstring = line.split("=", 1)
                valstring = valstring.strip().lower()

            if "Key" in keystring:
                key = valstring
            if "Nonce" in keystring:
                nonce = valstring
            if "PT" in keystring:
                pt = valstring
            if "AD" in keystring:
                ad = valstring
            if "CT" in keystring:
                obj = AeadEncrypt(key, nonce, pt, ad)
                kat_directory[obj] = valstring
    
    return kat_directory

if __name__ == "__main__":
    parse_aead_encrypt_file("../LWC_AEAD_KAT_128_128.txt")