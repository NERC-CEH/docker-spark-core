FROM ubuntu:16.04

LABEL maintainer "gareth.lloyd@stfc.ac.uk"

ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

# Install Basic Packages
RUN apt-get -y update && \
    apt-get install -y locales && \
    locale-gen $LANG && \
    apt-get install -y software-properties-common && \
    apt -y autoclean && \
    apt -y dist-upgrade && \
    apt-get install -y build-essential

# Install Java
ENV JAVA_HOME=/usr/lib/jvm/java-8-oracle
RUN echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
    add-apt-repository -y ppa:webupd8team/java && \
    apt-get -y update && \
    apt-get install -y oracle-java8-installer && \
    apt-get -y autoclean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /var/cache/oracle-jdk8-installer

# Install Spark
ENV SPARK_VER 2.1.0
ENV HADOOP_VER 2.7
ENV SPARK_HOME /opt/spark
RUN wget -O /tmp/spark-${SPARK_VER}-bin-hadoop${HADOOP_VER}.tgz https://archive.apache.org/dist/spark/spark-${SPARK_VER}/spark-${SPARK_VER}-bin-hadoop${HADOOP_VER}.tgz && \
    tar -zxvf /tmp/spark-${SPARK_VER}-bin-hadoop${HADOOP_VER}.tgz && \
    rm -rf /tmp/spark-${SPARK_VER}-bin-hadoop${HADOOP_VER}.tgz && \
    mv /spark-${SPARK_VER}-bin-hadoop${HADOOP_VER} ${SPARK_HOME}

# Patch SparkR to fix issue -- https://issues.apache.org/jira/browse/SPARK-21093
ADD daemon.R.patch /opt/spark/R/lib/SparkR/worker
RUN patch -b /opt/spark/R/lib/SparkR/worker/daemon.R /opt/spark/R/lib/SparkR/worker/daemon.R.patch

# Install R
RUN echo "deb http://cran.rstudio.com/bin/linux/ubuntu xenial/" | tee -a /etc/apt/sources.list && \
    gpg --keyserver keyserver.ubuntu.com --recv-key E084DAB9 && \
    gpg -a --export E084DAB9 | apt-key add - && \
    apt-get -y update && \
    apt-get -y install r-base r-base-dev libssl-dev libcurl4-gnutls-dev jags libxml2-dev libgdal-dev libproj-dev && \
    apt-get -y autoclean
# R is used to determine the current installed version. Environment variables
# R_LIBS_SITE and R_LIBS_USER paths are included in paths searched by R for
# library packages. Only directories which exist will be included. R uses '%v'
# as a string expansion to include current version number.
ENV R_PLATFORM x86_64-centos_6-linux-gnu
ENV R_LIBS_SITE /opt/R-libs/site/$R_PLATFORM/%v
ENV R_LIBS_USER /data/R-libs/global/$R_PLATFORM/%v
ENV R_PACKRAT_CACHE_DIR /data/R-libs/cache/$R_PLATFORM
RUN R_LIB_SITE_FIXED=$(R --slave -e "write(gsub('%v', R.version\$minor,Sys.getenv('R_LIBS_SITE')), stdout())") && \
    mkdir -p $R_LIB_SITE_FIXED && \
    R -q -e "install.packages(c('devtools', 'dplyr', 'knitr', 'magrittr', 'packrat'), repos='https://cloud.r-project.org/')"

# Install Tini
RUN wget -O /tmp/tini https://github.com/krallin/tini/releases/download/v0.15.0/tini && \
    mv /tmp/tini /usr/bin/tini && \
    rm -rf /tmp/tini && \
    chmod +x /usr/bin/tini
