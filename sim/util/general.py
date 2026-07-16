def split(hexstring):
    if hexstring[1] == 'x':
        hexstring = hexstring[2:]
    out_str = hexstring[0:16] + "  " + hexstring[16: 32] + "  " + hexstring[32: 48] + "  " + hexstring[48 : 64] + "  " + hexstring[64:80]
    return out_str

def pad_zeroes(hexstring, desired_len=64):
    length = len(hexstring)
    out_string = hexstring
    while length < desired_len:
        out_string = "0" + out_string
        length += 1
        
    return out_string


def invert_bytes_per_word(hexstring, word_bytes=8):
    result = ""
    if len(hexstring) > 0:
        if hexstring[1] == 'x':
            hexstring = hexstring[2:]

        if len(hexstring) % 2 == 1:
            hexstring = '0' + hexstring

        word_nibbles = 2 * word_bytes

        words = [hexstring[0 + i : word_bytes * 2 + i] for i in range(0, len(hexstring), word_nibbles)]
        for word in words:
            result += invert_bytes(word)
        return result
    return hexstring

def invert_bytes(hexstring):
    return bytes.fromhex(hexstring)[::-1].hex()