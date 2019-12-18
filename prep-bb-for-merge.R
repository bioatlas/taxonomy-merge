################################################################################################
# prep-bb-for-merge.R   
# Author: Maria Prager

# Makes subset of GBIF backbone (requires subset of manageable size for R - see get-bb-subset.sh) 
# based on taxon list, e.g. genus Tricladium
# Includes ancestors, as well as children, of given focal taxa
# Currently excludes taxa starting with '?'- see function read.bb
# Outputs tsv-file to use in taxonomy-merge

# Also filters extension files, but this needs some editing to work

################################################################################################
# EXTENSIONS

# install.packages("rstudioapi") 
library(rstudioapi)

################################################################################################
# FUNCTIONS

# Read Taxon.tsv, if found
read.bb <- function(bb) {
  if (file.exists(bb)) {
    df <- read.csv(bb, header=T, sep='\t', stringsAsFactors=FALSE, quote = "")
    # Use canonicalName as scientificName (to remove authors) for all but SH's and others lacking canononical name 
    df$scientificName[df$canonicalName!=''] <- df$canonicalName[df$canonicalName!='']
    # Keep only accepted names (to reduce file size for now)
    # df <- df[df$taxonomicStatus == 'accepted', ]
    df<-df[!(startsWith(df$scientificName, '?')), ]
    return(df)
  } else { print(paste("Could not find file", bb)) }
}

# Filter extension files linked to core
filter.extensions <- function(in.dir, out.dir, ids) {
  files <- list.files(in.dir, pattern="*.tsv", full.names=TRUE, recursive=FALSE)
  for (file in files) {
    df <- read.csv(file, header=T, sep='\t', stringsAsFactors=FALSE, quote = "")
    df <- df[df$taxonID %in% ids, ] 
    filt.file <- paste0(out.dir, "/", basename(file))
    write.table(df, filt.file, sep='\t', row.names = F, na = '', quote = FALSE)
  }
}

# Get ancestors and their descendants, for single tacon name
filter.on.name <- function(df, name) {
  all = df[FALSE,]; anc = df[FALSE,]; chd = df[FALSE,]
  ids <- df$taxonID[df$scientificName == name]
  # If no match, return empty df
  if (length(ids) == 0) { print(paste(name, 'was not found.')); return(all)}
  ranks <- c('kingdom',  'phylum',  'class',  'order',  'family',  'genus', 'specificEpithet', 'infraspecificEpithet')
  for (i in ids) {
    rank <- df$taxonRank[df$taxonID == i]
    full.tax <- df[df$taxonID == i, ranks ]
    # (Name matching will include homonyms, if present, but not important here, I think)
    # Get ancestors (+ focal taxon) as names matching any ranks in taxonomy
    anc <- df[df$scientificName %in% full.tax, ]
    # Get descendants, e.g. taxa that share name of current rank, but not taxon name, with focal taxon
    chd <- df[df[[rank]] == name & !is.na(df[[rank]]),]
    all <- rbind(all, anc, chd)
  }
  all <- all[!duplicated(all$taxonID),]
  return(all)
}

# Concatenate filtered df:s for multiple names
concat.filtered <- function (bb.df, taxa){
  old.filt.df <- bb.df[FALSE,]
  for (i in 1:length(taxa)) {
    new.filt.df <- filter.on.name(bb.df, taxa[i])
    if (nrow(new.filt.df) == 0) {if(i == length(taxa)){return(old.filt.df)}; next}
    if (nrow(old.filt.df) > 0) {
      merged.df <- rbind(old.filt.df, new.filt.df)
      dedup.df <- merged.df[!duplicated(merged.df$taxonID),]
    }
    else { dedup.df <- new.filt.df }
    if (i == length(taxa)){return(dedup.df)}
    else { old.filt.df <- dedup.df }
  }
}

################################################################################################
# MAIN

start_time <- Sys.time()

# Edit as needed
setwd(dirname(getActiveDocumentContext()$path))
annot.file <- '~/data/lucene/sources/bb-Bac-Fun/Taxon.Tsv'
# Fungi & Bacteria taxa to filter on
fu.taxa <- c('xxx')
pk.taxa <- c('yyy')

# Read backbone subset
bb.df <- read.bb(annot.file)
# Filter and concat within fungi/bacteria
fu.concat.df <- concat.filtered(bb.df, fu.taxa)
pk.concat.df <- concat.filtered(bb.df, pk.taxa)

# Merge Fungi + bacteria
fu.pk.df <- rbind(fu.concat.df, pk.concat.df)

# If no rows are filtered, add empty row (to avoid error downstream)
if (nrow(fu.pk.df) == 0) {fu.pk.df[nrow(fu.pk.df)+1,] <- NA}

# Add for TaxonomyBuilder (check if really needed!)
fu.pk.df$nomenclaturalCode <- ''

# Handle author info to enable bb matching (se merge-taxonomy.sh)
fu.pk.df$tempAuthor <- fu.pk.df$scientificNameAuthorship
fu.pk.df$scientificNameAuthorship <- 'x'

# Remove duplicates, if any
dedup.df <- fu.pk.df[!duplicated(fu.pk.df$taxonID),]

# Save filtered data to tsvs
write.table(dedup.df, file = "~/data/lucene/sources/bb-filt.tsv", sep='\t', row.names = F, na = '', quote = FALSE)

# Filter extension files - Needs editing (e.g. add datasetIDs + fix meta.xml to fit output)
# filter.extensions(in.dir, out.dir, dedup.df$taxonID)
# xml.files <- list.files(in.dir, pattern="*.xml", full.names=TRUE, recursive=FALSE)
# invisible(file.copy(xml.files, out.dir))

end_time <- Sys.time()
end_time - start_time

