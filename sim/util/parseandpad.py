def parse_and_pad(hexstring : str, out_bytes = 8):
    

    M = [hexstring[0+i:2*out_bytes+i] for i in range(0, len(hexstring), 2*out_bytes)]

    for i in range(0, len(M)):
        new_str = ""
        old_str = M[i]

        old_str_length = len(old_str)
        for j in range(0, old_str_length, 2):
            new_str += old_str[old_str_length - 2 - j: old_str_length - j]
        M[i] = new_str

    byte_length = len(hexstring) // 2
    byte_length %= out_bytes

    padded_word = ""
    word_len = out_bytes - byte_length

    if byte_length == 0:
        padded_word = "0000000000000001"
        M.append(padded_word)
    else:
        last = M[-1] # the last, incomplete word
        padded_word = last
        padded_word = "01" + padded_word
        for i in range(0, out_bytes - byte_length - 1):
            padded_word = "00" + padded_word
        M[-1] = padded_word
    
    return (M, word_len)

def parse(hexstring: str, r_bytes: int) -> tuple:

    r_bytes = 2 * r_bytes #Considering nibbles

    l = len(hexstring) // r_bytes
    
    blocks = []
    
    for i in range(l):
        block = hexstring[i * r_bytes : (i + 1) * r_bytes]
        blocks.append(block)
        
    final_block = hexstring[l * r_bytes : len(hexstring)]
    blocks.append(final_block)
    return blocks, len(final_block) * 4





def pad(hexstring: str, r_bytes: int) -> str:
    leading_zeroes = 0
    for c in hexstring:
        if c == '0':
            leading_zeroes += 1
        else:
            break
    

    if False:
        if leading_zeroes % 2 == 0:
            hexstring = hexstring[leading_zeroes:]
        else:
            hexstring = hexstring[leading_zeroes-1:]


    data_bytes = bytes.fromhex(hexstring)

    pad_len = r_bytes - (len(data_bytes) % r_bytes)

    a_padding =  b'\x01' + (b'\x00' * (pad_len - 1)) 
    a_padded =  data_bytes + a_padding
    
    result = a_padded.hex()

    return result


def split320(l):
        if len(l) % 2 == 1:
            l = "0" + l
        out_str = l[0:16] + "  " + l[16: 32] + "  " + l[32: 48] + "  " + l[48 : 64] + "  " + l[64:80]
        return out_str


x = parse("000102030405060708090A0B0C0D0E0F101112131415161718", 16)
print(x)
print(pad(x[0][1], 16))