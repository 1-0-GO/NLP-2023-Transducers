#!/bin/bash

mkdir -p compiled images

rm -f ./compiled/*.fst ./images/*.pdf

printf "Starting compilation of source transducers\n"
# ############ Compile source transducers ############
for i in sources/*.txt tests/*.txt;  do
	echo "Compiling: $i"
    fstcompile --isymbols=syms.txt --osymbols=syms.txt $i | fstarcsort > compiled/$(basename $i ".txt").fst
done

printf "\nGenerating more transducers using FST opperations on source transducers\n"
# ############ CORE OF THE PROJECT  ############

# mmmpt2mmmen: MMMpt -> MMMen

# mmmen2mm: MMMen -> [d][d]

# mmmpt2mm: MMMpt-> [d][d]
fstcompose compiled/mmmpt2mmmen.fst compiled/mmmen2mm.fst > compiled/mmmpt2mm.fst

# mmm2mm: MMM -> [d][d]
fstunion compiled/mmmpt2mm.fst compiled/mmmen2mm.fst > compiled/mmm2mm.fst

# copy: [c] -> [c]

# mix2numerical: MMM[c]* -> [d][d][c]*
fstconcat compiled/mmm2mm.fst compiled/copy.fst > compiled/mix2numerical.fst

# pt2en: MMMpt[c]* -> MMMen[c]*
fstconcat compiled/mmmpt2mmmen.fst compiled/copy.fst > compiled/pt2en.fst

# en2pt: MMMen[c]* -> MMMpt[c]*
fstinvert compiled/pt2en.fst > compiled/en2pt.fst

# day_single: [d] -> de

# day_zero: 0[d] -> de

# day_tens: [d]0 -> de

# day_teens: 1[d] -> de

# day_20_30: 2_/3_ -> de-

# day_th: 2[d]/3[d] -> de-de
fstconcat compiled/day_20_30.fst compiled/day_single.fst > compiled/day_th.fst

# day: [d]/0[d]/d[0]/1[d]/2[d]/3[d] -> de/de-de
fstunion compiled/day_single.fst compiled/day_zero.fst > compiled/day_single_zero.fst
fstunion compiled/day_single_zero.fst compiled/day_tens.fst > compiled/day_single_zero_tens.fst
fstunion compiled/day_single_zero_tens.fst compiled/day_teens.fst > compiled/day_single_zero_tens_teens.fst
fstunion compiled/day_single_zero_tens_teens.fst compiled/day_th.fst > compiled/day.fst

# m2mm: [d] -> 0[d]

# mm2mmmen: [d][d] -> MMM
fstinvert compiled/mmmen2mm.fst > compiled/mm2mmmen.fst

# mmmen: [d] (-> [d][d]) -> MMM
fstcompose compiled/m2mm.fst compiled/mm2mmmen.fst > compiled/mmmen.fst

# month: [d] (-> [d][d]) -> month 
fstcompose compiled/mmmen.fst compiled/mmmen2month.fst > compiled/month.fst

# year_20: 20 -> two_thousand_and_

# year_ones: [d] -> de

# year_tens: [d]0 -> de

# year_teens: 1[d] -> de

# year_comp: [d][d] -> de
fstconcat compiled/year_tens.fst compiled/year_ones.fst > compiled/year_comp.fst

# year: 20[d][d] -> de
fstunion compiled/year_comp.fst compiled/year_teens.fst > compiled/year_comp_teens.fst
fstconcat compiled/year_20.fst compiled/year_comp_teens.fst > compiled/year.fst

# slash2eps: / -> eps 

# slash2comma: / -> ,

# datenum2text: ([d][d]|[d])/([d][d]|[d])/20[d][d] -> me_de,ye
fstconcat compiled/month.fst compiled/slash2eps.fst > compiled/month_slash.fst
fstconcat compiled/month_slash.fst compiled/day.fst > compiled/month_day.fst
fstconcat compiled/month_day.fst compiled/slash2comma.fst > compiled/month_day_comma.fst
fstconcat compiled/month_day_comma.fst compiled/year.fst > compiled/datenum2text.fst

# create equiv. FST to datenum2text.fst with no two successful paths with the same input labels
# necessary for the fstcompose to work
fstdisambiguate compiled/datenum2text.fst > compiled/datenum2textdis.fst

# mix2text: MMMpt[c]*|MMMen[c]* ((-> MMMen[c]*) -> [d][d][c]*) -> me_de,ye
fstcompose compiled/mix2numerical.fst compiled/datenum2textdis.fst > compiled/mix2text.fst

# date2text
fstunion compiled/datenum2text.fst compiled/mix2text.fst > compiled/date2text.fst


# ############ generate PDFs  ############
printf "\nStarting to generate PDFs\n"
for i in compiled/*.fst; do
	echo "Creating image: images/$(basename $i '.fst').pdf"
   fstdraw --portrait --isymbols=syms.txt --osymbols=syms.txt $i | dot -Tpdf > images/$(basename $i '.fst').pdf
done

printf "\nStarting testing of transducers\n"
#1 - generates files
trans=date2text
echo "***********************************************************"
echo "Testing $trans. The output is a transducer: fst and pdf".
echo "***********************************************************"
for w in compiled/t-*.fst; do
    fstcompose $w compiled/$trans.fst | fstshortestpath | fstproject --project_type=output |
                  fstrmepsilon | fsttopsort > compiled/$(basename $w ".fst")-out.fst
done
for i in compiled/t-*-out.fst; do
	echo "Creating image: images/$(basename $i '.fst').pdf"
   fstdraw --portrait --isymbols=syms.txt --osymbols=syms.txt $i | dot -Tpdf > images/$(basename $i '.fst').pdf
done

#3 - presents the output with the tokens concatenated (uses a different syms on the output)
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
# SEP/09/2019 MAR/13/2017

test mmm2mm.fst JAN FEB FEV DEC 
test mix2numerical.fst SET/20/2018 SEP/09/2019 MAR/13/2017
test pt2en.fst SET/5/2018
test en2pt.fst FEB/05/2081 SEP/09/2019 MAR/13/2017
test day.fst 22
test month.fst 9 09
test year.fst 2025 2001 2099
test datenum2text.fst 09/15/2055 09/09/2019 03/13/2017
test mix2text.fst MAY/12/2088 MAI/12/2088 SEP/09/2019 MAR/13/2017
test date2text.fst OCT/31/2025 OUT/31/2025 10/31/2025 SEP/09/2019 MAR/13/2017

printf "\n\n***********************************************************\n"
printf "                        THE END"
printf "\n***********************************************************\n\n\n"