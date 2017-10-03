FROM ubuntu:14.04

ENV BIRDSUITE_VERSION 1.5.5
ENV MCLUST_VERSION 5.3
ENV UTILS_VERSION 1.0
ENV CNPUTILS_VERSION 1.0
ENV CANARY_VERSION 1.0
ENV MCRINSTALLER_VERSION 75
ENV APT_VERSION 1.20.5

ENV BIRDSUITE /opt/birdsuite

RUN apt-get update  && \
    apt-get install -y build-essential bc gcc git make wget libxp6 openjdk-6-jdk python python-numpy python-dev python-pip r-base r-base-dev

WORKDIR /opt/

# Download Birdsuite
RUN git clone https://github.com/ohsu-comp-bio/birdsuite.git

# Copy metadata
COPY metadata metadata/

# Install APT
RUN wget https://downloads.thermofisher.com/Affymetrix_Softwares/apt-${APT_VERSION}-x86_64-intel-linux.zip && \
    unzip apt-${APT_VERSION}-x86_64-intel-linux.zip && \
    rm apt-${APT_VERSION}-x86_64-intel-linux.zip && \
    chmod +x apt-${APT_VERSION}-x86_64-intel-linux/bin/apt-probeset-summarize && \
    ln -s /opt/apt-${APT_VERSION}-x86_64-intel-linux/bin/apt-probeset-summarize ${BIRDSUITE}/bin/apt-probeset-summarize.64 && \
    ln -s /opt/apt-${APT_VERSION}-x86_64-intel-linux/bin/apt-geno-qc ${BIRDSUITE}/bin/apt-geno-qc


# Install MCR
WORKDIR MCR
RUN wget ftp://ftp.broadinstitute.org/pub/mpg/birdsuite/MCRInstaller.${MCRINSTALLER_VERSION}.glnxa64.bin.gz && \
    gunzip MCRInstaller.${MCRINSTALLER_VERSION}.glnxa64.bin.gz && \
    chmod +x MCRInstaller.${MCRINSTALLER_VERSION}.glnxa64.bin && \
    ./MCRInstaller.${MCRINSTALLER_VERSION}.glnxa64.bin -P bean421.installLocation="${BIRDSUITE}/bin/MCR75_glnxa64" -silent

# Install python libs
WORKDIR ${BIRDSUITE}/bin
RUN pip install --upgrade setuptools
RUN python install.py -g /opt/birdsuite/eggs/

## Install R packages
WORKDIR ${BIRDSUITE}/lib

# Install mclust
RUN wget https://cran.r-project.org/src/contrib/mclust_${MCLUST_VERSION}.tar.gz && \
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

# Run Birdsuite
ENV PATH=${BIRDSUITE}/bin:$PATH
WORKDIR /opt/
ENTRYPOINT ["birdsuite.sh"]
