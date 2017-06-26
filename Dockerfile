FROM ubuntu:16.04

LABEL maintainer "gareth.lloyd@stfc.ac.uk"

# Install packages
RUN apt-get update && \
	apt-get -y install r-base openjdk-8-jdk

# Add KnitR for R html rendering with Zeppelin
RUN R -e "install.packages('knitr', repo='https://cloud.r-project.org/')"

# Additional packages for plots and command piping
RUN R -e "install.packages('ggplot2', repo='https://cloud.r-project.org/')"
RUN R -e "install.packages('magrittr', repo='https://cloud.r-project.org/')"
