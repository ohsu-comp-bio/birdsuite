FROM ubuntu:14.04

ENV BIRDSUITE_VERSION 1.5.5
ENV MCLUST_VERSION 5.3
ENV UTILS_VERSION 1.0
ENV CNPUTILS_VERSION 1.0
ENV CANARY_VERSION 1.0
ENV MCRINSTALLER_VERSION 75.glnxa64
ENV APT_VERSION 1.20.5

ENV BIRDSUITE /opt/birdsuite
ENV METADATA /opt/metadata
ENV AFFY /opt/data

RUN apt-get update  && \
    apt-get install -y build-essential bc gcc make wget libxp6 openjdk-6-jdk python python-numpy python-dev python-pip r-base r-base-dev

# Download Birdsuite
RUN mkdir $BIRDSUITE && \
    wget ftp://ftp.broadinstitute.org/pub/mpg/birdsuite/birdsuite_executables_${BIRDSUITE_VERSION}.tgz -O ${BIRDSUITE}/birdsuite_executables_${BIRDSUITE_VERSION}.tgz && \
    cd $BIRDSUITE && \
    tar -zxvf birdsuite_executables_${BIRDSUITE_VERSION}.tgz

# Copy metadata
## FIX ##
## Need to COPY metadata over or use --volumes ##
RUN mkdir $METADATA && \
    wget ftp://ftp.broadinstitute.org/pub/mpg/birdsuite/birdsuite_metadata_${BIRDSUITE_VERSION}.tgz -O ${METADATA}/birdsuite_metadata_${BIRDSUITE_VERSION}.tgz && \
    cd $METADATA && \
    tar -zxvf birdsuite_metadata_${BIRDSUITE_VERSION}.tgz

RUN cd $AFFY && \
    unzip genomewidesnp6_libraryfile.zip && \
    cp CD_GenomeWideSNP_6_rev3/Full/GenomeWideSNP_6/LibFiles/GenomeWideSNP_6.Full.* ${METADATA}/

# Download APT
RUN cd ${BIRDSUITE} && \
    wget https://downloads.thermofisher.com/Affymetrix_Softwares/apt-${APT_VERSION}-x86_64-intel-linux.zip && \
    unzip apt-${APT_VERSION}-x86_64-intel-linux.zip && \
    chmod +x ${BIRDSUITE}/apt-${APT_VERSION}-x86_64-intel-linux/bin/apt-probeset-summarize && \
    ln -s ${BIRDSUITE}/apt-${APT_VERSION}-x86_64-intel-linux/bin/apt-probeset-summarize ${BIRDSUITE}/apt-probeset-summarize.64 && \
    ln -s ${BIRDSUITE}/apt-${APT_VERSION}-x86_64-intel-linux/bin/apt-geno-qc ${BIRDSUITE}/apt-geno-qc

# Install MCR
RUN mkdir /opt/MCR && \
    wget ftp://ftp.broadinstitute.org/pub/mpg/birdsuite/MCRInstaller.${MCRINSTALLER_VERSION}.bin.gz -O /opt/MCR/MCRInstaller.${MCRINSTALLER_VERSION}.bin.gz && \
    cd /opt/MCR && \
    gunzip MCRInstaller.${MCRINSTALLER_VERSION}.bin.gz && \
    chmod +x MCRInstaller.${MCRINSTALLER_VERSION}.bin && \
    ./MCRInstaller.${MCRINSTALLER_VERSION}.bin -P bean421.installLocation="${BIRDSUITE}/MCR75_glnxa64" -silent && \
    rm -rf /opt/MCR

WORKDIR $BIRDSUITE

# Install python libs
RUN pip install -y setuptools
RUN python install.py 

## Install R packages

# Install mclust
RUN wget https://cran.r-project.org/src/contrib/mclust_${MCLUST_VERSION}.tar.gz -O ${BIRDSUITE}/mclust_${MCLUST_VERSION}.tar.gz && \
    R CMD INSTALL mclust_${MCLUST_VERSION}.tar.gz && \
    rm mclust_${MCLUST_VERSION}.tar.gz 

# Rebuild and install broadgap.utils
RUN tar -zxvf broadgap.utils_${UTILS_VERSION}.tar.gz && \
    rm -rf broadgap.utils/man && \
    R CMD build broadgap.utils && \
    rm -rf broadgap.utils && \
    R CMD INSTALL broadgap.utils_${UTILS_VERSION}.tar.gz && \
    rm broadgap.utils_${UTILS_VERSION}.tar.gz

# Rebuild and install broadgap.cnputils
RUN tar -zxvf broadgap.cnputils_${CNPUTILS_VERSION}.tar.gz && \ 
    R CMD build broadgap.cnputils && \
    rm -rf broadgap.cnputils && \
    R CMD INSTALL broadgap.cnputils_${CNPUTILS_VERSION}.tar.gz && \
    rm broadgap.cnputils_${CNPUTILS_VERSION}.tar.gz

# Rebuild and install broadgap.canary
RUN tar -zxvf broadgap.canary_${CANARY_VERSION}.tar.gz && \
    R CMD build broadgap.canary && \
    rm -rf broadgap.canary && \
    R CMD INSTALL broadgap.canary_${CANARY_VERSION}.tar.gz && \
    rm broadgap.canary_${CANARY_VERSION}.tar.gz
