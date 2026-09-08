#!/usr/bin/env python3
import sys

def main():
    fh_in = sys.stdin
    fh_out = sys.stdout

    while True:
        # incoming values have newline
        l = fh_in.readline()

        out_str = "U"

        if not l:
            return 0
        try:
            # 128 bits split into four 32-bit words (8 hex chars each)
            out_str = l[0:8] + "  " + l[8:16] + "  " + l[16:24] + "  " + l[24:32]
        except:
            out_str = "X"
        # outgoing filtered values must have a newline
        fh_out.write("%s\n" % out_str)
        fh_out.flush()

if __name__ == '__main__':
    sys.exit(main())