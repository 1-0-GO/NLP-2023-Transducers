#!/bin/bash

mkdir -p compiled images

rm -f ./compiled/*.fst ./images/*.pdf

# ############ Compile source transducers ############
for i in sources/*.txt tests/*.txt; do
	echo "Compiling: $i"
    fstcompile --isymbols=syms.txt --osymbols=syms.txt $i | fstarcsort > compiled/$(basename $i ".txt").fst
done

# ############ CORE OF THE PROJECT  ############

# mmm2mm: MMM -> [d][d]
# fstcompile --isymbols=syms.txt --osymbols=syms.txt mmm2mm.txt | fstarcsort > mmm2mm.fst
# fstdraw --portrait --isymbols=syms.txt --osymbols=syms.txt compiled/mmm2mm.fst | dot -Tpdf > images/mmm2mm.pdf

# copy: [c] -> [c]
# fstcompile --isymbols=syms.txt --osymbols=syms.txt copy.txt | fstarcsort > copy.fst

# mix2numerical: MMM[c]* -> [d][d][c]*
fstconcat compiled/mmm2mm.fst compiled/copy.fst > compiled/mix2numerical.fst
# fstdraw --portrait --isymbols=syms.txt --osymbols=syms.txt compiled/mix2numerical.fst | dot -Tpdf > images/mix2numerical.pdf

# mmmpt2mmmen: MMMpt -> MMMen
# fstcompile --isymbols=syms.txt --osymbols=syms.txt mmmpt2mmmen.txt | fstarcsort > mmmpt2mmmen.fst

# pt2en: MMMpt[c]* -> MMMen[c]*
fstconcat compiled/mmmpt2mmmen.fst compiled/copy.fst > compiled/pt2en.fst
# fstdraw --portrait --isymbols=syms.txt --osymbols=syms.txt compiled/pt2en.fst | dot -Tpdf > images/pt2en.pdf

# en2pt: MMMen[c]* -> MMMpt[c]*
fstinvert compiled/pt2en.fst > compiled/en2pt.fst
# fstdraw --portrait --isymbols=syms.txt --osymbols=syms.txt compiled/en2pt.fst | dot -Tpdf > images/en2pt.pdf

# day_single: [d] -> de
# fstcompile --isymbols=syms.txt --osymbols=syms.txt day_single.txt | fstarcsort > day_single.fst

# day_zero: 0[d] -> de
# fstcompile --isymbols=syms.txt --osymbols=syms.txt day_zero.txt | fstarcsort > day_zero.fst

# day_tens: [d]0 -> de
# fstcompile --isymbols=syms.txt --osymbols=syms.txt day_tens.txt | fstarcsort > day_tens.fst

# day_teens: 1[d] -> de
# fstcompile --isymbols=syms.txt --osymbols=syms.txt day_teens.txt | fstarcsort > day_teens.fst

# day_20_30: 2_/3_ -> de-
# fstcompile --isymbols=syms.txt --osymbols=syms.txt day_20_30.txt | fstarcsort > day_20_30.fst

# day_th: 2[d]/3[d] -> de-de
fstconcat compiled/day_20_30.fst compiled/day_single.fst > compiled/day_th.fst

# day: [d]/0[d]/d[0]/1[d]/2[d]/3[d] -> de/de-de
fstunion compiled/day_single.fst compiled/day_zero.fst > compiled/day_single_zero.fst
fstunion compiled/day_single_zero.fst compiled/day_tens.fst > compiled/day_single_zero_tens.fst
fstunion compiled/day_single_zero_tens.fst compiled/day_teens.fst > compiled/day_single_zero_tens_teens.fst
fstunion compiled/day_single_zero_tens_teens.fst compiled/day_th.fst > compiled/day.fst
# fstdraw --portrait --isymbols=syms.txt --osymbols=syms.txt compiled/day.fst | dot -Tpdf > images/day.pdf

# m2mm: [d] -> 0[d]
# fstcompile --isymbols=syms.txt --osymbols=syms.txt m2mm.txt | fstarcsort > m2mm.fst

# mm2mmm: [d][d] -> MMM
fstinvert compiled/mmm2mm.fst > compiled/mm2mmm.fst

# month: [d] (-> [d][d]) -> MMM
fstcompose compiled/m2mm.fst compiled/mm2mmm.fst > compiled/month.fst
# fstdraw --portrait --isymbols=syms.txt --osymbols=syms.txt compiled/month.fst | dot -Tpdf > images/month.pdf

# year_20: 20 -> two_thousand_and_
# fstcompile --isymbols=syms.txt --osymbols=syms.txt year_20.txt | fstarcsort > year_20.fst

# year_ones: [d] -> de
# fstcompile --isymbols=syms.txt --osymbols=syms.txt year_ones.txt | fstarcsort > year_ones.fst

# year_tens: [d]0 -> de
# fstcompile --isymbols=syms.txt --osymbols=syms.txt year_tens.txt | fstarcsort > year_tens.fst

# year_teens: 1[d] -> de
# fstcompile --isymbols=syms.txt --osymbols=syms.txt year_teens.txt | fstarcsort > year_teens.fst

# year_comp: [d][d] -> de
fstconcat compiled/year_tens.fst compiled/year_ones.fst > compiled/year_comp.fst

# year: 20[d][d] -> de
fstunion compiled/year_comp.fst compiled/year_teens.fst > compiled/year_comp_teens.fst
fstconcat compiled/year_20.fst compiled/year_comp_teens.fst > compiled/year.fst
# fstdraw --portrait --isymbols=syms.txt --osymbols=syms.txt compiled/year.fst | dot -Tpdf > images/year.pdf

# comma:  -> ,
# fstcompile --isymbols=syms.txt --osymbols=syms.txt comma.txt | fstarcsort > comma.fst

# datenum2text: ([d][d]|[d])/([d][d]|[d])/20[d][d] -> me_de,ye
fstconcat compiled/month.fst compiled/day.fst > compiled/month_day.fst
fstconcat compiled/month_day.fst compiled/comma.fst > compiled/month_day_comma.fst
fstconcat compiled/month_day_comma.fst compiled/year.fst > compiled/datenum2text.fst
# fstdraw --portrait --isymbols=syms.txt --osymbols=syms.txt compiled/datenum2text.fst | dot -Tpdf > images/datenum2text.pdf

# en2en: MMMen[c]* -> MMMen[c]*
fstproject --project_type=output compiled/pt2en.fst > compiled/en2en.fst

# mix2en: MMMpt[c]*|MMMen[c]* -> MMMen[c]*
fstunion compiled/pt2en.fst compiled/en2en.fst > compiled/mix2en.fst
# fstdraw --portrait --isymbols=syms.txt --osymbols=syms.txt compiled/mix2en.fst | dot -Tpdf > images/mix2en.pdf

# [TODO: o pdf ficou diferente?]
# en2numerical: MMMpt[c]*|MMMen[c]* (-> MMMen[c]*) -> [d][d][c]*
fstcompose compiled/mix2en.fst compiled/mix2numerical.fst > compiled/en2numerical.fst
# fstdraw --portrait --isymbols=syms.txt --osymbols=syms.txt compiled/en2numerical.fst | dot -Tpdf > images/en2numerical.pdf

# [TODO: not working]
# mix2text: MMMpt[c]*|MMMen[c]* ((-> MMMen[c]*) -> [d][d][c]*) -> me_de,ye
fstcompose compiled/en2numerical.fst compiled/datenum2text.fst > compiled/mix2text.fst
# fstdraw --portrait --isymbols=syms.txt --osymbols=syms.txt compiled/mix2text.fst | dot -Tpdf > images/mix2text.pdf

# mix_or_date: MMMpt[c]*|MMMen[c]* (-> MMMen[c]*) -> [d][d][c]*|([d][d]|[d])/([d][d]|[d])/20[d][d] -> [d][d][c]*
# fstunion mix2numerical.fst mix2numerical.fst > mix_or_date.fst

# date2text
# fstcompose mix_or_date.fst daenum2text.fst > date2text.fst
# fstdraw --portrait --isymbols=syms.txt --osymbols=syms.txt date2text.fst | dot -Tpdf > date2text.pdf


# ############ generate PDFs  ############
echo "Starting to generate PDFs"
for i in compiled/*.fst; do
	echo "Creating image: images/$(basename $i '.fst').pdf"
   fstdraw --portrait --isymbols=syms.txt --osymbols=syms.txt $i | dot -Tpdf > images/$(basename $i '.fst').pdf
done



# ############      3 different ways of testing     ############
# ############ (you can use the one(s) you prefer)  ############

#1 - generates files
echo "\n***********************************************************"
echo "Testing 4 (the output is a transducer: fst and pdf)"
echo "***********************************************************"
for w in compiled/t-*.fst; do
    fstcompose $w compiled/n2text.fst | fstshortestpath | fstproject --project_type=output |
                  fstrmepsilon | fsttopsort > compiled/$(basename $i ".fst")-out.fst
done
for i in compiled/t-*-out.fst; do
	echo "Creating image: images/$(basename $i '.fst').pdf"
   fstdraw --portrait --isymbols=syms.txt --osymbols=syms.txt $i | dot -Tpdf > images/$(basename $i '.fst').pdf
done


#2 - present the output as an acceptor
echo "\n***********************************************************"
echo "Testing 1 2 3 4 (output is a acceptor)"
echo "***********************************************************"
trans=n2text.fst
echo "\nTesting $trans"
for w in "1" "2" "3" "4"; do
    echo "\t $w"
    python3 ./scripts/word2fst.py $w | fstcompile --isymbols=syms.txt --osymbols=syms.txt | fstarcsort |
                     fstcompose - compiled/$trans | fstshortestpath | fstproject --project_type=output |
                     fstrmepsilon | fsttopsort | fstprint --acceptor --isymbols=syms.txt
done

#3 - presents the output with the tokens concatenated (uses a different syms on the output)
fst2word() {
	awk '{if(NF>=3){printf("%s",$3)}}END{printf("\n")}'
}

trans=n2text.fst
echo "\n***********************************************************"
echo "Testing 5 6 7 8  (output is a string  using 'syms-out.txt')"
echo "***********************************************************"
for w in 5 6 7 8; do
    res=$(python3 ./scripts/word2fst.py $w | fstcompile --isymbols=syms.txt --osymbols=syms.txt | fstarcsort |
                       fstcompose - compiled/$trans | fstshortestpath | fstproject --project_type=output |
                       fstrmepsilon | fsttopsort | fstprint --acceptor --isymbols=./scripts/syms-out.txt | fst2word)
    echo "$w = $res"
done

echo "\nThe end"
