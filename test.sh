test() {
    fst2word() {
        awk '{if(NF>=3){printf("%s",$3)}}END{printf("\n")}'
    }

    trans=$1
    arr="${@:2}"
    printf "\n***********************************************************\n"
    echo "Testing $trans with $arr (output is a string  using 'syms-out.txt')"
    echo "***********************************************************"
    for w in $arr; do
        res=$(python3 ./scripts/word2fst.py $w | fstcompile --isymbols=syms.txt --osymbols=syms.txt | fstarcsort |
                        fstcompose - compiled/$trans | fstshortestpath | fstproject --project_type=output |
                        fstrmepsilon | fsttopsort | fstprint --acceptor --isymbols=./syms-out.txt | fst2word)
        echo "$w = $res"
    done
}    


# dates when we turned 18:
# SEP/09/2019 JAN/01/2019

test mmm2mm.fst JAN FEB FEV DEC 
test mix2numerical.fst SET/20/2018 SEP/09/2019 JAN/01/2019
test pt2en.fst SET/5/2018
test en2pt.fst FEB/05/2081 SEP/09/2019 JAN/01/2019
test day.fst 22
test month.fst 9 09
test year.fst 2025 2001 2099
test datenum2text.fst 09/15/2055 09/09/2019 01/01/2019
test mix2text.fst MAY/12/2088 MAI/12/2088 SEP/09/2019 JAN/01/2019
test date2text.fst OCT/31/2025 OUT/31/2025 10/31/2025 SEP/09/2019 JAN/01/2019


printf "\nThe end\n"
