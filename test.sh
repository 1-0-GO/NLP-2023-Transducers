test() {
    fst2word() {
        awk '{if(NF>=3){printf("%s",$3)}}END{printf("\n")}'
    }

    trans=$1
    arr="${@:2}"
    echo ""
    echo "***********************************************************"
    echo "Testing $trans with $arr (output is a string  using 'syms-out.txt')"
    echo "***********************************************************"
    for w in $arr; do
        res=$(python3 ./scripts/word2fst.py $w | fstcompile --isymbols=syms.txt --osymbols=syms.txt | fstarcsort |
                        fstcompose - compiled/$trans | fstshortestpath | fstproject --project_type=output |
                        fstrmepsilon | fsttopsort | fstprint --acceptor --isymbols=./syms-out.txt | fst2word)
        echo "$w = $res"
    done

    echo "\nThe end"
}    

test mmm2mm.fst JAN FEB DEC 