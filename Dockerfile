FROM alpine:latest
LABEL maintainer "Herbrand Hofker <herbrand@kafka.academy>"
ARG ROCKSDB_VERSION=6.14.6
RUN echo "@testing http://nl.alpinelinux.org/alpine/edge/testing" >>/etc/apk/repositories
RUN apk add --update --no-cache build-base linux-headers git cmake bash perl #wget mercurial g++ autoconf libgflags-dev cmake bash
RUN apk add --update --no-cache curl zlib zlib-dev bzip2 bzip2-dev snappy snappy-dev lz4 lz4-dev zstd@testing zstd-dev@testing libtbb-dev@testing libtbb@testing

# installing latest gflags
RUN cd /tmp && \
    git clone  https://github.com/gflags/gflags.git && \
    cd gflags && \
    mkdir build && \
    cd build && \
    cmake -DBUILD_SHARED_LIBS=1 -DGFLAGS_INSTALL_SHARED_LIBS=1 .. && \
    make install && \
    cd /tmp && \
    rm -R /tmp/gflags/

# Install Rocksdb
RUN cd /tmp &&  git clone --branch "v${ROCKSDB_VERSION}"  --depth 1 https://github.com/facebook/rocksdb.git 
RUN cd /tmp/rocksdb && make shared_lib
RUN mkdir -p /usr/local/rocksdb/lib &&  mkdir /usr/local/rocksdb/include 
RUN cd /tmp/rocksdb &&  \
    cp librocksdb.so* /usr/local/rocksdb/lib && \
    cp /usr/local/rocksdb/lib/librocksdb.so* /usr/lib/ && \
    cp -r include /usr/local/rocksdb/ && \
    cp -r include/* /usr/include/ 

RUN apk update
ENV DEBUG_LEVEL 0 

RUN apk add openjdk11 
RUN mkdir /rocksdb-build
ENV JAVA_HOME "/usr/lib/jvm/default-jvm"
ENV PATH "$PATH:/usr/lib/jvm/default-jvm/bin"
RUN cd /tmp/rocksdb && make jclean

RUN cd /tmp/rocksdb && make -j8 rocksdbjavastatic
RUN cp /tmp/rocksdb/java/target/librocksdbjni-* /rocksdb-build
RUN cp /tmp/rocksdb/java/target/rocksdbjni-* /rocksdb-build
#RUN rm -R /tmp/rocksdb/