# Based on https://github.com/emscripten-core/emsdk/tree/master/docker
FROM debian:bookworm AS qtbuilder

RUN mkdir -p /development
# Install Mesa OpenGL and ninja (needed to build Qt for x64)
RUN apt-get update && apt-get -y install mesa-common-dev libgl1-mesa-dev libglu1-mesa-dev ninja-build git python-is-python3 xz-utils lbzip2 cmake build-essential ca-certificates

# Install GE root certificate
# must be downloaded from https://static.gecirtnotification.com/browser_remediation/sop_server_v1.html and copied into container first
COPY GE_External_Root_CA_2_1.crt /usr/local/share/ca-certificates
RUN update-ca-certificates

RUN git clone https://github.com/emscripten-core/emsdk.git /emsdk && cd /emsdk && \
    ./emsdk install 3.1.25 && ./emsdk activate --embed 3.1.25

# Clone Qt sources
WORKDIR /development
RUN git clone --branch=6.5 https://code.qt.io/qt/qt5.git
WORKDIR /development/qt5
RUN git rev-parse HEAD
RUN ./init-repository --module-subset=qtbase,qtdeclarative,qtshadertools

# Build Qt for x64
RUN mkdir -p /development/qt5_build_x64
WORKDIR /development/qt5_build_x64
RUN /development/qt5/configure -nomake examples -nomake tests -prefix /usr/local/Qt-x64
RUN cmake --build .
RUN cmake --install .

# Build Qt for WASM
RUN mkdir -p /development/qt5_build
WORKDIR /development/qt5_build
ENV EMSDK /emsdk
RUN /development/qt5/configure -qt-host-path /usr/local/Qt-x64 -xplatform wasm-emscripten -feature-thread -feature-wasm-exceptions -nomake examples -prefix /usr/local/Qt-wasm
RUN cmake --build .
RUN cmake --install .


FROM debian:bookworm

# Install Boost & Eigen
# https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
RUN apt-get update && apt-get -y install \
    libtool-bin      \
    libeigen3-dev    \
    libboost-dev     \
    cmake            \
    ninja-build      \
    python-is-python3 \
    ca-certificates

# Install GE root certificate
# must be downloaded from https://static.gecirtnotification.com/browser_remediation/sop_server_v1.html and copied into container first
COPY GE_External_Root_CA_2_1.crt /usr/local/share/ca-certificates
RUN update-ca-certificates

# Copy Qt binaries to new container
COPY --from=qtbuilder /emsdk/  /emsdk/
COPY --from=qtbuilder /usr/local/Qt-x64/  /usr/local/Qt-x64/
COPY --from=qtbuilder /usr/local/Qt-wasm/ /usr/local/Qt-wasm/

# Make symlinks to avoid adding /usr/include to include dirs.
RUN mkdir -p /project/dependencies/include && mkdir -p /project/dependencies/lib && \
    ln -s /usr/include/boost   /project/dependencies/include/boost  && \
    ln -s /usr/include/eigen3  /project/dependencies/include/eigen3 && \
    ln -s /usr/lib/cmake       /project/dependencies/lib/cmake      && \
    ln -s /usr/local/Qt-wasm   /project/Qt

# Add qmake to PATH (doesn't seem to work)
#ENV PATH="/project/Qt/bin:${PATH}"

# Build custom sources
WORKDIR /project/build

# Emsdk path
ENV EMSDK /emsdk

# Default build command
CMD /usr/local/Qt-wasm/bin/qt-cmake -DCMAKE_BUILD_TYPE=Release -GNinja /project/source && ninja
