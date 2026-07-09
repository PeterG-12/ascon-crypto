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
            out_str = l[0:16] + "  " + l[16: 32] + "  " + l[32: 48] + "  " + l[48 : 64] + "  " + l[64:80]
        except:
            out_str = "X"
        # outgoing filtered values must have a newline
        fh_out.write("%s\n" % out_str)
        fh_out.flush()

if __name__ == '__main__':
	sys.exit(main())