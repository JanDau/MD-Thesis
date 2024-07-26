# Use Ubuntu 18.04 LTS as base image
FROM ubuntu:18.04

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies for R and R packages
RUN apt-get update && apt-get install -y \
    build-essential \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    wget \
    software-properties-common \
    libbz2-dev \
    liblzma-dev \
    libpcre3-dev \
    libicu-dev \
    libreadline-dev \
	gfortran \
	libtiff5-dev \
	libcairo2-dev \
	libpng-dev \
	cmake

# Download and install R 3.4.0
RUN wget https://cloud.r-project.org/src/base/R-3/R-3.4.0.tar.gz && \
    tar -xzf R-3.4.0.tar.gz && \
    cd R-3.4.0 && \
    ./configure --with-readline=no --with-x=no && \
    make && \
    make install

# Clean up the tar.gz file after installation
RUN cd ../ && \
    rm -rf R-3.4.0.tar.gz R-3.4.0

# -- Install R environment --
# Set the Server and Install remotes package
RUN R -e "options(repos = list(CRAN = 'https://cloud.r-project.org/')); install.packages('remotes')"

# Reading the list of required packages (in exactly that order)
COPY r_package_list.txt /tmp/r_package_list.txt

RUN R -e "packages <- read.delim('/tmp/r_package_list.txt', header = FALSE, stringsAsFactors = FALSE, sep='='); apply(packages, 1, function(x) remotes::install_version(as.character(x[1]), version = as.character(x[2]), repos = 'https://cloud.r-project.org/', upgrade = 'never'))"

# Clean up unnecessary files and clear apt cache to reduce image size
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/*