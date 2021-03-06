#' ---	
#' title: "Phylogenetics"	
#' author: "Lucio Rezende Queiroz"	
#' date: "March 15, 2017"	
#' output:	
#'   pdf_document: default	
#'   html_notebook: default	
#'   ioslides_presentation: default	
#'   html_document: default	
#'   word_document: default	
#' ---	
#' 	
#' # Reproducibility in science	
#' 	
#' ## Tools	
#' 	
#' ![R logo](images/images.jpg)	
#' ![Rstudio logo](images/Rstudio.jpg)	
#' ![Docker logo](images/docker_logo.png)	
#' 	
#' # Dipteran dsRBP phylogenetics	
#' 	
#' # Setting envinroment	
#' 	
#' 	
args = commandArgs(trailingOnly=TRUE)	
system('git config --global user.name "luciorq"')	
system('git config --global user.email "luciorqueiroz@gmail.com"')	
#' 	
#' # Analysis	
#' 	
#' ## Loading libraries	
#' 	
#' 	
source("src/functions.R")	
source("lib/rmd2rscript.R")	
require(dplyr)	
#' 	
#' 	
#' ## Initializing variables	
#' 	
#' List of Files used for the analysis	
#' Here you can change the files used for the analysis, inside 'raw' directory	
#' 	
#' 	
if(length(args)==0) {	
  sequences_file = "dsRBPv1"	
  InterPro = "IPR014720"	
  }else{	
    sequences_file = args[1]	
    InterPro = args[2]	
}	
tblastn_db = "VB_dipteran_transcripts"	
blastx_db = "FB_fly_translated"	
#' 	
#' 	
#' ----	
#' 	
#' 	
system(paste0("grep '>' raw/",sequences_file), intern = TRUE)	
#' 	
#' 	
#' # VectorBase tBlasn	
#' 	
#' ## Transcripts used for tBlastn	
#' 	
#' tBlastn was performed against the following libraries:	
#' 	
for(line in (readLines(paste0("raw/",tblastn_db,"_list.txt")))){	
  print(unlist(strsplit(line, "/"))[length(unlist(strsplit(line, "/")))])	
  }	
#' 	
#' 	
#' ### VectorBase sequences for tBlastn	
#' 	
#' 	
DownloadLibraries(tblastn_db)	
makeBlastDB(tblastn_db,"nucl")	
#' 	
#' 	
#' ## tBlastn against VectorBase transcripts	
#' 	
#' 	
MLtoSLfasta(paste0("raw/",sequences_file))	
Blast("tblastn",paste0("data/",sequences_file,".fasta"), tblastn_db)	
#' 	
#' 	
#' ### Formatting output	
#' 	
#' 	
tblastn_table <- read.csv(paste0("data/",sequences_file,".fasta_alignment.csv"), header = FALSE)	
names(tblastn_table) <- c("querySeqId", "subjectSeqId", "queryLength", "alignmentLength", "E-value", "bitscore", "subjectTitle")	
tblastn_table$subjectTitle <- unlist(lapply(tblastn_table$subjectTitle, function(x) strsplit(as.character(x), split = "|", fixed = TRUE)[[1]][1]))	
tblastn_table <- subset(tblastn_table, (`E-value` < 1e-03))	
#' 	
#' 	
#' ----	
#' 	
#' ### Blast table {.smaller}	
#' 	
#' 	
head(tblastn_table)	
#' 	
#' 	
#' ### Retrieving hit fasta sequences	
#' 	
#' 	
write.table(tblastn_table$subjectSeqId, file = paste0("data/",sequences_file,"_ids.txt"),	
            quote = FALSE, row.names = FALSE, col.names = FALSE)	
RetrieveFasta(tblastn_db,sequences_file)	
#' 	
#' 	
#' # FlyBase BlastX	
#' 	
#' ## Translated Proteins used for reverse BlastX against Fruit Flies	
#' 	
#' 	
for(line in (readLines(paste0("raw/",blastx_db,"_list.txt")))){	
  print(unlist(strsplit(line, "/"))[length(unlist(strsplit(line, "/")))])	
  }	
#' 	
#' 	
#' ### FlyBase sequences for BlastX	
#' 	
#' 	
DownloadLibraries(blastx_db)	
makeBlastDB(blastx_db, "prot")	
#' 	
#' 	
#' ## Reverse BlastX against fruit flies	
#' 	
#' 	
#FilterFastaRedundancy(paste0("data/",sequences_file,"_blast_result.fasta"))	
FilterFastaRedundancy(paste0("data/",sequences_file,"_blast_result.fasta"),paste0("data/",sequences_file,"_blast_result_nr.fasta") )	
Blast("blastx",paste0("data/",sequences_file,"_blast_result_nr.fasta"), blastx_db, outformat = 6)	
#' 	
#' 	
#' ### Formatting output	
#' 	
#' 	
system(paste0("sort -k1,1 -k6,6nr -k5,5n data/",sequences_file,"_blast_result_nr.fasta_alignment.tab | sort -u -k 1,1 --merge > data/",sequences_file,"_filtered.tab"))	
blastx_table <- read.table(paste0("data/",sequences_file,"_filtered.tab"), header = FALSE )	
blastx_table$V7 <- blastx_table$V10	
names(blastx_table) <- c("querySeqId", "subjectSeqId", "queryLength", "alignmentLength", "E-value", "bitscore", "subjectTitle")	
blastx_table <- blastx_table[,1:7]	
#' 	
#' 	
#' ----	
#' 	
#' ### Reverse Blast table {.smaller}	
#' 	
#' 	
head(blastx_table)	
#' 	
#' 	
#' ### Formatting table	
#' 	
#' 	
#FormatTable()	
reverse_blast_list = c()	
reverse_title_list = c()	
reverse_evalue_list = c()	
for(transcript in tblastn_table$subjectSeqId){	
  i = 1	
  for(hit in blastx_table$querySeqId){	
    if(hit == transcript){	
      hit_name = as.character(blastx_table$querySeqId[i])	
      reverse_blast_list = c(reverse_blast_list, hit_name)	
      Title_name = as.character(blastx_table$subjectTitle[i])	
      reverse_title_list = c(reverse_title_list, Title_name)	
      reverse_evalue = blastx_table$`E-value`[i]	
      reverse_evalue_list = c(reverse_evalue_list, reverse_evalue)	
    }	
    i = i + 1	
  }	
}	
final_document <- tblastn_table[,c("querySeqId","subjectSeqId","E-value","subjectTitle")]	
for(i in 1:length(final_document$subjectSeqId)){	
  for(j in 1:length(reverse_blast_list)){	
    if(as.character(final_document$subjectSeqId[[i]]) == reverse_blast_list[j]){	
      final_document$reverseBlast[i] <- reverse_title_list[j]	
      final_document$reverseBlastEvalue[i] <- reverse_evalue_list[j]	
    }	
  }	
}	
	
#final_document$reverseBlast <- reverse_blast_list	
#final_document$reverseBlastEvalue <- reverse_evalue_list	
final_document <- subset(final_document, (`E-value` < 1e-03))	
final_document <- arrange(final_document, subjectSeqId)	
write.csv(final_document, file = paste0("results/",sequences_file,".csv"), row.names = FALSE)	
#' 	
#' 	
#' ----	
#' 	
#' ### formatted table {.smaller}	
#' 	
#' 	
head(final_document)	
#' 	
#' 	
#' ----	
#' 	
#' ### Retrieving transcripts fasta sequences	
#' 	
#' 	
write.table(final_document$subjectSeqId, file = paste0("data/",sequences_file,"_nucl_ids.txt"),	
            quote = FALSE, row.names = FALSE, col.names = FALSE)	
RetrieveFasta(tblastn_db,paste0(sequences_file,"_nucl"))	
paste0("data/",sequences_file,"_nucl_blast_result.fasta")	
#' 	
#' 	
#' ## Finding dsRBP domain in ORFs from transcripts	
#' 	
#' GetORF(sequences_file)	
#' ```	
#' ### Extracting domain information from ORFs	
#' 	
RunIprScan((paste0("data/",sequences_file,"_orf.fasta")), 	
          (paste0("data/iprscan_results/",sequences_file,"_orf")))	
#' 	
#' run local	
#' interproscan.sh -i data/dsRBPv1_orf.fasta -d data/iprscan_results/dsRBPv1_local -f XML &	
#' 	
#' ----	
#' 	
#' Number of transcripts:	
#' 	
print("Number of transcripts:")	
system(paste0("ls -l data/iprscan_results/",sequences_file,"_orf/ | cut -f 1 -d'_' | grep -oP '...........RA$' | sort -k1,1 | sort -k1,1 -u | wc -l"), intern = TRUE)	
#' 	
#' Number of ORFs:	
#' 	
print("Number of ORFs:")	
system(paste0("ls -l data/iprscan_results/",sequences_file,"_orf/ | cut -f 1 -d'_' | grep -oP '...........RA$' | sort -k1,1 | sort -k1,1 | wc -l"), intern = TRUE)	
#' 	
#' 	
#' ## Retrieving ORFs with `r InterPro` domain	
#' 	
ORFwithDomain(sequences_file, InterPro)	
#' 	
#' Number of ORFs with hit for `r InterPro` domain	
#' 	
print(paste0("Number of ORFS with hit for ",InterPro," domain:"))	
system(paste0("grep '>' data/",sequences_file,"_domain_filtered_ORF.fasta | wc -l"), intern = TRUE )	
#' 	
#' 	
#' ## Concatenating novel translated transcripts to the 'raw' data	
#' 	
#' 	
system(paste0("cat data/",sequences_file,".fasta > data/",sequences_file,"_result.fasta"))	
system(paste0("cat data/",sequences_file,"_domain_filtered_ORF.fasta >> data/",sequences_file,"_result.fasta"))	
system(paste0("grep '>' data/",sequences_file,"_result.fasta | wc -l"), intern = TRUE)	
#' 	
#' 	
#' ## Interpro domains with more hits:	
#' 	
#' 	
print("Hits per domain:")	
system(paste0("python src/ipr2tsv.py data/iprscan_results/",sequences_file,"_orf/ | cut -f 2 | sort | uniq -c | sort -k1,1 -nr | head -10"), intern = TRUE)	
#' 	
#' 	
#' 	
#' # Building Trees	
#' 	
#' ## MAFFT alignment	
#' 	
#' number of sequences aligned after redundancy filter:	
#' 	
FilterFastaRedundancy(paste0("data/",sequences_file,"_result.fasta"),paste0("data/",sequences_file,"_result_nr.fasta") )	
Alignment("mafft","--auto", sequences_file)	
print("Number of sequences used for alignemnt:")	
system(paste0("grep '>' data/",sequences_file,"_result_nr.fasta | wc -l"), intern = TRUE)	
#' 	
#' 	
#' ## Trees	
#' 	
#' 	
BuildTrees(sequences_file, "Ce.Rde-4")	
#' 	
#' 	
#' # Converting this notebook to an executable script	
#' 	
#' 	
rmd2rscript("dsRBP.Rmd")	
#' 	
#' # How can we improve?	
#' 	
#' 	
#' ## Acknowledgement	
#' 	
#' ![RNAi Lab Group](images/rnai_group.png)	
#' 	
#' ![ppg_logo](images/logoBioinformatica.png)	
#' 	
