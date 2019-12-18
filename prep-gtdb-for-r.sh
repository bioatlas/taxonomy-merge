#!/usr/bin/env bash
# Maria Prager

##################################################################################################################

# Prepares GTDB taxonomy file for further manip in R
# Outputs tsv
# ToDo: Include GTDB-NCBI synonyms, merge with Archaea taxonomy

##################################################################################################################

# Edit as needed
hdr="datasetID\tkingdom\tphylum\tclass\torder\tfamily\tgenus\tspecificEpithet\tinfraspecificEpithet\totu\tasv"
dir=$(pwd)/data
gtdb=~/data/seq/GTDB/bac120_taxonomy.tsv

# Remove rank prefix & duplicates, split sp -> genus + sp-epith, add hdr & datasetID
sed $'s/\t/;/g' $gtdb | awk -v hdr=$hdr 'BEGIN{FS=";"; print hdr}
{gsub(/(d|p|c|o|f|g|s)_+/,"",$0); split($8,parts," "); $9=parts[2]}
{if (!seen[$8 $9]++) print "GTDB-bac120", $2, $3, $4, $5, $6, $7, $9}' \
OFS="\t" > $dir/gtdb-for-r-prep.tsv
