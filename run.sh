#!/bin/bash

mkdir -p compiled images

rm -f ./compiled/*.fst ./images/*.pdf

# ############ Compile source transducers ############
for i in sources/*.txt; do
	echo "Compiling: $i"
    fstcompile --isymbols=syms.txt --osymbols=syms.txt $i | fstarcsort > compiled/$(basename $i ".txt").fst
done

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
echo "Starting to generate PDFs"
for i in compiled/*.fst; do
	echo "Creating image: images/$(basename $i '.fst').pdf"
   fstdraw --portrait --isymbols=syms.txt --osymbols=syms.txt $i | dot -Tpdf > images/$(basename $i '.fst').pdf
done

./test.sh