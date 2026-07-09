# Script used for debugging parse_and_pad
debug = True

def parse_and_pad(hexstring : str):
    M = list((hexstring[0+i:16+i] for i in range(0, len(hexstring), 16)))

    print(M)

    for i in range(0, len(M)):
        new_str = ""
        old_str = M[i]

        old_str_length = len(old_str)
        for j in range(0, old_str_length, 2):
            new_str += old_str[old_str_length - 2 - j: old_str_length - j]
        M[i] = new_str

    byte_length = len(hexstring) // 2
    byte_length %= 8
    # Get length in bytes of last 64-bit word
    print(M)

    padded_word = ""
    if byte_length == 0:
        padded_word = "0000000000000001"
        M.append(padded_word)
    else:
        last = M[-1] # the last, incomplete word
        padded_word = last
        padded_word = "01" + padded_word
        for i in range(0, 8 - byte_length - 1):
            padded_word = "00" + padded_word
        M[-1] = padded_word

    if debug: print(M)    
    return M

parse_and_pad("000102")
