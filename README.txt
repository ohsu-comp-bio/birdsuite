############################################################################
# The Broad Institute
# SOFTWARE COPYRIGHT NOTICE AGREEMENT
# This software and its documentation are copyright 2007 by the
# Broad Institute/Massachusetts Institute of Technology. All rights are
# reserved.

# This software is supplied without any warranty or guaranteed support
# whatsoever. Neither the Broad Institute nor MIT can be responsible for its
# use, misuse, or functionality.
############################################################################

BIRDSUITE RELEASE 1.4

Tue Apr 22 2008

http://wwwdev.broad.mit.edu/mpg/birdsuite/

INTRODUCTION

The Birdsuite is a fully open-source set of tools to detect and report SNP genotypes,
common Copy-Number Variants (CNVs), and rare/de novo CNVs in samples processed with the
Affymetrix platform.  This document describes the usage of Birdsuite, and the meaning of
its various outputs.

For installation instructions, see INSTALL.TXT.

PREREQUISITES

The cel files passed to Birdsuite should all have mini-DM scores of >= 86%.

INVOCATION

Invoke Birdsuite with <EXE_DIR>/birdsuite.sh, where <EXE_DIR> is the directory in which
you installed the Birdsuite executables.  Note that there are some other utility programs
(c.f. UTILITY PROGRAMS below) that may be useful in running birdsuite.sh.

The following arguments are required to run birdsuite.sh:

--basename BASE:       This is used to name all the output files produced by Birdsuite.

--chipType CHIP_TYPE:  This is used to select the appropriate metadata files corresponding
                       to the Affy chip.  Currently only GenomeWideSNP_6 and
                       GenomeWideSNP_5 are supported. 

--genderFile GENDER_FILE: The gender file must align with the list of cel files passed to
                       Birdsuite.  It must contain a header line "gender", and then a line
                       for each cel file, with 0 representing female, 1 representing male,
                       and 2 representing unknown.

Cel files may be specified by enumerating them on the command line, or putting the list of
files into a file with header line "cel_files", and specifying this file on the command
line with option --celFiles.

The following arguments are optional:

--outputDir OUTPUT_DIR: Write outputs somewhere other than the current directory. 

--genomeBuild GENOME_BUILD: Use the specified genome build.  hg18 is the default.
                            Currently hg17 and hg18 are supported.  This option has both
                            direct and indirect effect.  The direct effect is that
                            Birdseye calls will be relative to the specified genome
                            build.  The indirect effects are due to the fact that a probe
                            may be considered part of a CNP in one build but not the
                            other, which may result in changes in the way a probe is
                            handled by Birdseed, Birdseye and Larry Bird.

--force:                    Passed through to apt_probeset_summarize.  Use this option if
                            one or more of the cel files was processed with a non-standard
                            CDF.

--noLsf:                    By default Birdsuite use the Load-Sharing Facility (LSF) to
                            parallelize parts of the Birdsuite pipeline.
                            C.f. http://www.platform.com/Products/platform-lsf-family/platform-lsf/product
                            Use this option if you do not have LSF installed on your
                            system, or do not wish to use LSF.

--firstStep STEP
--lastStep STEP:            These options tell Birdsuite what stage of the pipeline to
                            start and stop at.  They are typically used only for
                            debugging.

--exeDir EXE_DIR
--metadataDir METADATA_DIR: These options tell Birdsuite where to find metadata and
                            executables.  If you have set up your installation as
                            instructed in INSTALL.txt, you should not need to supply these
                            options. 


OUTPUT FILES

(BASE is a placeholder for the text passed to the --basename option.)


apt-probeset-summarize.log  This file is produced by apt_probeset_summarize, the first
                            step in Birdsuite.

BASE.allele_summary         Allele summary file produced by apt_probeset_summarize.

BASE.annotated_summary      Allele summary file with probe locus information for each
                            probe(set), sorted in genomic order.

BASE.locus_summary          Same as annotated_summary above, except values for A and B
                            alleles for a SNP are averaged together.

BASE.probeset_summary       A single intensity value for each common-CNP,sample pair.

BASE.canary_calls           Calls file for common CNPs, with a copy number for each
                            common-CNP,sample pair. 

BASE.canary_confs           Confidence file that is the partner to canary_calls file,
                            indicated the confidence of each Canary call.  0=most
                            confident, 1=least confident.

BASE.canary_log             Log produced by Canary.

BASE.birdseed_exclusions    For each probe, a list of the 0-based sample indices for
                            samples that have unusual copy number as determined by Canary.

BASE.birdseed_calls         Conventional Birdseed genotype call file.  0=AA, 1=AB, 2=BB,
                            -1=no call

BASE.birdseed_confs         Confidence file that is partner to birdseed_calls file.
                            0=most confident, 1=least confident.

BASE.birdseed_clusters      SNP clusters found in the process of running Birdseed.

BASE.*.birdseye_dir         24 subdirectories, each with data so that Birdseye can be run
                            in parallel on each chromosome.  
BASE.birdseye_canary_calls  Merged Birdseye and Canary calls.  Each line contains a copy
                            number count for a chromosome and range, and a confidence.  In
                            this file, a larger number indicates higher confidence.

BASE.birdseye_calls         Raw Birdseye calls.  This is just the concatenation of the
                            Birdseye calls from each birdseye_dir subdirectory.

BASE.birdseye_cn_clusters   CN probe clusters used by Birdseye.

BASE.larry_bird_calls       SNP genotype calls with arbitrary copy number.  Each call is of
                            the form N,M , where N is the number of the A allele and M is
                            the number of the B allele.  No-call is represented as -1,-1.

BASE.larry_bird_confs       Confidence file that is the partner to larry_bird_calls.
                            0=most confident, 1=least confident. 

BASE.report.txt             Summary statistics of Larry Bird SNP calls in the spirit of
                            those produced by apt_probeset_genotype.  The various
                            CNx_percent columns are the percentage of SNPs for that sample
                            for which the number of copies (i.e. N+M for a call N,M)
                            equals x.  These columns sum to 100.  The diallelic
                            percentages (AB_percent, AA_percent, BB_percent) have as their
                            denominator the number of diallelic calls, so these three
                            percentages sum to 100. 

SAMPLE.birdsuite.rpt        The same information as found in BASE.report.txt, split by cel
                            file.  


UTILITY PROGRAMS

birdsuite_qc.py:

birdsuite_qc.py is a convenience program that runs mini-DM and gender calls the cel
files.  It produces a list of cel files that pass the mini-DM threshold, and also a gender
file for those cel files.  These two files can then be input to birdsuite.sh using the
--celFiles and --genderFile options.

Usage: EXEDIR/birdsuite_qc.py --cel_files_out output.cels --gender_out output.gender
--metadata_dir METADATADIR --exe_dir EXEDIR cel-files...

birdsuite_pipeline.py:

birdsuite_pipeline.py is a convenience program that runs birdsuite_qc.py on a list of cel
files, producing a list of files that pass mini-DM threshold along with their genders, and
then launches birdsuite.sh on those cel files.

make_bed.py:

make_bed.py produces a BED (binary PED) file in the format expected by PLINK from Birdseed
or Larry Bird calls and confidences files.  See
http://pngu.mgh.harvard.edu/~purcell/plink/binary.shtml for details on BED files.  By
using make_bed.py to create a BED file, make_bim.py (see below) to create a BIM file, and
creating a FAM file yourself from your pedigree data, you will have the basic inputs
needed to run PLINK.

make_bim.py:

make_bim.py produces a BIM (binary MAP) file in the format expected by PLINK.  In order to
use make_bim.py, you will need to download from the Affymetrix website the SNP annotation
file for the chip you are using and the genome build you desire.  See
http://pngu.mgh.harvard.edu/~purcell/plink/binary.shtml for details on BIM files.
