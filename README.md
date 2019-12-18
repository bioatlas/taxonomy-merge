# taxonomy-merging
Scripts for running and preparing input to the [ALA Taxonomy builder and nameindexer](https://github.com/AtlasOfLivingAustralia/documentation/wiki/A-Guide-to-Getting-Names-into-the-ALA). These tools may be used to merge the [GBIF taxonomy backbone](https://www.gbif.org/dataset/d7dddbf4-2cf0-4f39-9b2a-bb099caae36c) with the [Genome Taxonomy DataBase (GTDB) taxonomy](https://gtdb.ecogenomic.org/about), and with a list of Swedish Amplicon Sequence Variants (ASVs), to improve taxonomic coverage of prokaryotes in the BioAtlas. 

## Overview of files

*get-bb-subset.sh*, *prep-gtdb-for-r.sh* <br>make subsets of GBIF backbone / GTDB taxonomy -> manageable size & structure for further editing i R

*prep-xxx-for-merge.R* <br>edits data, and adds parent taxa -> file suitable for ALA Taxonomy builder

*merge-taxonomy.sh* <br>applies ALA Taxonomy builder, and outputs zip file to be transferred to the BioAtlas

## Taxonomy implementation in the BioAtlas
The steps below describe how to implement the merged taxonomy in a test version of the BioAtlas, and assumes that scp & ssh connection options (host, user, RSA key file) are specified in a *.ssh/config file*, allowing me to use the *cloud* alias. I use the *dyntaxa* label and *dyntaxa-index* directory for convenience only.

1. Copy taxonomy-dwca (and if needed, the java tool nameindexer.zip) to server
```console
scp ~/data/lucene/runs/xxx/dyntaxa.dwca.zip cloud:repos/ala-docker/dyntaxa-index
```
2. Login to cloud server, and navigate to ala-docker dir
```console
ssh cloud
cd /repos/ala-docker
```
3. Build nameindex image \[*name:tag* - edit as needed\], using the namindexer tool in the *dyntaxa-index* directory. 
```console
docker build --no-cache -t bioatlas/ala-dyntaxaindex:xxx dyntaxa-index
```
4. Test search index (by searching for taxon zzz)
```console
docker run --rm -it bioatlas/ala-dyntaxaindex:xxx nameindexer -testSearch zzz
```
Should output something similar to:
```console
...
Classification: "null",Bacteria,Acidobacteriota,Acidobacteriae,Acidobacteriales,Acidobacteriaceae,Edaphobacter
Scientific name: zzz
...
Match type: exactMatch
```
5. 
Setup nameindex service to start from newly created index image 
```console
nano docker-compose.yml
```
*Ctrl+w* to search for e.g. 'dynt'. Comment out current image and add new image, like so:
```console
nameindex:
#image: bioatlas/ala-nameindex:v0.4
#image: bioatlas/ala-dyntaxaindex:v0.4
image: bioatlas/ala-dyntaxaindex:191124
command: /bin/ash
container_name: nameindex
...
```
*Ctrl+x* to save

6. Clean-up data volumes (will remove indices, and all data from ingested datasets)
```console
docker-compose stop nameindex biocachebackend biocacheservice specieslists
docker rm -vf solr cassandradb nameindex biocachebackend biocacheservice specieslists
docker volume rm ala-docker_data_solr ala-docker_db_data_cassandra ala-docker_data_nameindex
```
Start up (will create new nameindex service, as configurated in docker-compose.yml)
```console
docker-compose up -d
docker-compose restart webserver
```



## References
Parks, D. H., et al. (2018). "A standardized bacterial taxonomy based on genome phylogeny substantially revises the tree of life." Nature Biotechnology, 36: 996-1004.


