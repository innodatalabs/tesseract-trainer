# Set docker image
FROM ubuntu:20.04

# Skip the configuration part
ENV DEBIAN_FRONTEND noninteractive

# Update and install depedencies
RUN apt-get update && \
    apt-get install -y wget unzip bc vim python3-pip libleptonica-dev git

# Packages to complie Tesseract
RUN apt-get install -y --reinstall make && \
    apt-get install -y g++ autoconf automake libtool pkg-config libpng-dev libjpeg8-dev libtiff5-dev libicu-dev \
        libpango1.0-dev autoconf-archive

# Set working directory
WORKDIR /app

# Getting tesstrain: beware the source might change or not being available
# Complie Tesseract with training options (also feel free to update Tesseract versions and such!)
# Getting data: beware the source might change or not being available
RUN mkdir src && cd /app/src && \
    wget https://github.com/tesseract-ocr/tesseract/archive/4.1.1.zip && \
	unzip 4.1.1.zip && \
    cd /app/src/tesseract-4.1.1 && ./autogen.sh && ./configure && make && make install && ldconfig && \
    make training && make training-install

# Setting the data prefix
ENV TESSDATA_PREFIX=/usr/local/share/tessdata

# Install libraries using pip installer
RUN pip3 install Pillow pytesseract
COPY text_from_box.py trainer.sh radical-stroke.txt /app/

# Set the locale
RUN apt-get install -y locales && locale-gen en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8
ENV PYTHONPATH=/app

COPY evaluate.sh evaluate.py /app/

CMD ["/app/trainer.sh"]
