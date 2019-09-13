FROM phusion/baseimage:0.9.22

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]

RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    libcurl4-openssl-dev libxml2 libxml2-dev libexpat1-dev zlib1g-dev libssl-dev \
    libjpeg-dev libpng-dev libgif-dev \
    git \
 && rm -rf /var/lib/apt/lists/* && apt-get clean

RUN useradd -ms /bin/bash app;

USER app
ADD install-perlbrew.sh /tmp/install-perlbrew.sh
RUN /tmp/install-perlbrew.sh

USER root
RUN apt-get update && apt-get install -y \
    libpq-dev \
    postgresql-client \
&& rm -rf /var/lib/apt/lists/* && apt-get clean

USER app

ADD install-cpan-modules.sh /tmp/install-cpan-modules.sh
RUN /tmp/install-cpan-modules.sh

ADD Makefile_local.PL /tmp/Makefile.PL
ADD install-cpan-extra-modules.sh /tmp/install-cpan-extra-modules.sh
RUN /tmp/install-cpan-extra-modules.sh

USER root
RUN echo "deb http://packages.cloud.google.com/apt cloud-sdk-trusty main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
RUN cat /etc/apt/sources.list.d/google-cloud-sdk.list
RUN curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
RUN apt-get update && apt-get install -y google-cloud-sdk jq

RUN mkdir /etc/service/mandatoaberto
COPY mandatoaberto.sh /etc/service/mandatoaberto/run

RUN mkdir /etc/service/mandatoaberto-email
COPY mandatoaberto-email.sh /etc/service/mandatoaberto-email/run

RUN mkdir /etc/service/mandatoaberto-segmenter
COPY mandatoaberto-segmenter.sh /etc/service/mandatoaberto-segmenter/run

RUN mkdir /etc/service/mandatoaberto-campaign
COPY mandatoaberto-campaign.sh /etc/service/mandatoaberto-campaign/run