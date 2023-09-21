#!env python3
import argparse
import sys
import re

with open('../syms.txt') as syms:
    all_symbols = [line.strip().split()[0] for line in syms]
single_numbers_or_slashes = [s for s in all_symbols if re.match(r"[0-9]|\/", )]
months_same_in_pt_and_en = ["JAN", "MAR", "JUN", "JUL", "NOV"]

defined_symbols = {"single_nums_or_slashes": single_numbers_or_slashes,
                   "months_same_in_pt_and_en": months_same_in_pt_and_en
                }

def print_line(f, t, i, o, w=None):
    if o == "=": o = i
    # the ouput is the same as the input to the transducer
    if w == None:
        print("%s\t%s\t%s\t%s" % (f, t, i, o))
    else:
        print("%s\t%s\t%s\t%s\t%s" % (f, t, i, o, w))


def expand(line):
    cols = line.strip().split()
    # line indicating final state
    if len(cols) == 1:
        print("%s" % cols[0])

    # line indicating final state and cost at arrival
    elif len(cols) == 2:
        print("%s\t%s\t" % cols[0], cols[1])

    elif 4 <= len(cols) <= 5:
        weight = None
        if len(cols) == 5: weight = cols[4]
        col2 = defined_symbols.get(cols[2])

        if col2 != None :
            for s in col2:
                print_line(cols[0], cols[1], s, cols[3], weight)
        else:
            print_line(cols[0], cols[1], cols[2], cols[3], weight)
    else:
        print("Error, incorrect number of columns:", cols, file=sys.stderr)


if __name__ == '__main__':
    PARSER = argparse.ArgumentParser(formatter_class=argparse.RawDescriptionHelpFormatter,
        description="Converts an FST written in our compact notation to a concrete FST that is used by openfst")
    PARSER.add_argument('file', help='input file')
    args = PARSER.parse_args()

    with open(args.file) as f:
        while True:
            line = f.readline()
            if line == '': break
            if not re.match(r"^\s*$",line): expand(line)