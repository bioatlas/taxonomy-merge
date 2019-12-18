#!/usr/bin/env bash
# Maria Prager

##################################################################################################################

# Makes subsets of GBIF Taxonomy backbone DwCA
# -> files of manageable size (for R or Excel)
# Extracts rows from Taxon.tsv based on given kingdom(s),
# Extracts rows with matching taxonIDs in extension files
# Outputs DwCA
# ToDo: Add datasetID cols in GBIF extensions, to include these in merge
# Also add auto-edit of meta.xml to match cols

##################################################################################################################

# Edit as needed:
# Backbone DwCA folder
bbdir=~/data/Checklist-original/bb-full
# Kingdoms to include in subset
# Select from: Animalia Archaea Bacteria Chromista Fungi Plantae Protozoa Viruses
kingdoms=("Bacteria Fungi")

##################################################################################################################

# # For testing on smaller files only
# tdir=~/data/lucene/sources/bb-tiny
# rm -rf $tdir
# mkdir $tdir
# for file in $bbdir/*.*; do
#   tname=$(basename "$file")
#   if [ ${tname: -4} == ".tsv" ]; then
#     echo "Making tiny $tname"
#     head -n 100000 $file > $tdir/$tname
#   else
#     echo "Copying tiny $tname"
#     cp $file $tdir/$name; fi
# done
# bbdir=$tdir

##################################################################################################################

# Filter Taxon.tsv and tsv extensions
function filter_bb {
  taxfile=$bbdir/Taxon.tsv
  # Abbrev kingdom names for output
  for i in ${kingdoms[@]}; do
    k="${i:0:3}"
    kabb+=($k)
  done
  kstr=$(echo "${kabb[*]}" | tr ' ' '-')
  if [ ! -f $taxfile ]; then echo "The backbone Taxon.tsv not found in $bbdir!"; return
  else
    subdir=~/data/lucene/sources/bb-$kstr-$(date +"%y%m%d-%H%M")
    mkdir $subdir
    echo "Filtering Taxon.txt"
    # For Taxon.tsv, store hdrs, then include hdr + rows w matching kingdom(s)
    # NOTE: Awk 'in' compares with array index - not value,
    # -> dict[parts[i]]="" has kingdom as index (value is not used)
    awk -F"\t" -v k="${kingdoms}" 'BEGIN{split(k, parts, " "); for (i in parts) dict[parts[i]]=""} \
    NR == 1 {for(i=1; i<=NF; i++) {f[$i]=i}} ($(f["kingdom"]) == "kingdom" || $(f["kingdom"]) in dict)' \
    OFS="\t" $taxfile > $subdir/Taxon.tsv
    # For tsv extensions, include rows with taxonIDs matching filtered Taxon.tsv
    for file in $bbdir/*.*; do
      name=$(basename "$file")
      if [ ${name: -4} == ".tsv" ]; then
        if [ "$name" != "Taxon.tsv" ]; then
          echo "Filtering $name"
          # NR==FNR -> {apply to Taxon.tsv file}, next -> apply rest to ext. files only
          # $1 assumed to be taxonID so no hdr name-matching used here
          awk -F"\t" 'NR==FNR {a[$1]=$1; next} a[$1] {print}' \
          OFS="\t" $subdir/Taxon.tsv $bbdir/$name > $subdir/$name
        fi
      else
        cp $file $subdir/$name
        echo "Copying $name"
      fi
    done
  fi
}

##################################################################################################################

# Run
filter_bb;
