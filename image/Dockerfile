# Based on https://github.com/emscripten-core/emsdk/tree/master/docker
FROM emscripten/emsdk:3.1.27 AS qtbuilder

# Extra Qt build parameters
ARG EXTRA_BUILD_PARAMS=

# Qt 6.5 show warnings if default locale is not UTF-8
ENV LANG=C.UTF-8

RUN mkdir -p /development

# Install GE root certificate
# must be downloaded from https://static.gecirtnotification.com/browser_remediation/sop_server_v1.html and copied into container first
COPY GE_External_Root_CA_2_1.crt /usr/local/share/ca-certificates
RUN update-ca-certificates

# Install Mesa OpenGL and ninja (needed to build Qt for x64)
RUN apt-get update && apt-get -y install mesa-common-dev libgl1-mesa-dev libglu1-mesa-dev ninja-build

# Clone Qt sources
WORKDIR /development
RUN git clone --branch v6.5.1 https://code.qt.io/qt/qt5.git
WORKDIR /development/qt5
RUN git rev-parse HEAD
RUN ./init-repository

# Build Qt for x64
RUN mkdir -p /development/qt5_build_x64
WORKDIR /development/qt5_build_x64
RUN /development/qt5/configure -nomake examples -nomake tests -prefix /usr/local/Qt-x64
RUN cmake --build . $EXTRA_BUILD_PARAMS
RUN cmake --install .

# Build Qt for WASM
RUN mkdir -p /development/qt5_build
WORKDIR /development/qt5_build
RUN /development/qt5/configure -qt-host-path /usr/local/Qt-x64 -xplatform wasm-emscripten -feature-wasm-exceptions -feature-thread -nomake examples -prefix /opt/Qt
RUN cmake --build . $EXTRA_BUILD_PARAMS
RUN cmake --install .

# Build HDF5 for WASM
COPY customtoolchainflags.cmake /
WORKDIR /build
# Download sources from official repo
RUN wget https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.8/hdf5-1.8.23/src/hdf5-1.8.23.tar.gz && \
    tar -xf hdf5-1.8.23.tar.gz
WORKDIR /build/hdf5-1.8.23
#inject wasm specific flags in the projects
RUN emcmake cmake -S . -B build-wasm -DCMAKE_INSTALL_PREFIX:PATH=/opt/wasm-deps \
    -DHDF5_INSTALL_CMAKE_DIR=lib/cmake/ \
    -DCMAKE_BUILD_TYPE:STRING=Release \
    -DBUILD_SHARED_LIBS:BOOL=OFF \
    -DBUILD_TESTING:BOOL=OFF \
    -DHDF5_BUILD_CPP_LIB:BOOL=ON \
    -DHDF5_BUILD_EXAMPLES:BOOL=OFF \
    -DCMAKE_TOOLCHAIN_FILE=/customtoolchainflags.cmake
WORKDIR /build/hdf5-1.8.23/build-wasm
# Redirect the output of the binary to a file (it should use the 1st argument... But it doesn't)
RUN sed -i 's/js H5/js > H5/g' src/CMakeFiles/gen_hdf5-static.dir/build.make
RUN emmake make -j`nproc` install

FROM emscripten/emsdk:3.1.27

# Install GE root certificate
# must be downloaded from https://static.gecirtnotification.com/browser_remediation/sop_server_v1.html and copied into container first
COPY GE_External_Root_CA_2_1.crt /usr/local/share/ca-certificates
RUN update-ca-certificates

# Copy binaries to new container
COPY --from=qtbuilder /usr/local/Qt-x64/ /usr/local/Qt-x64/
COPY --from=qtbuilder /opt/Qt/           /opt/Qt/
COPY --from=qtbuilder /opt/wasm-deps/    /opt/wasm-deps/

# Install Boost & Eigen
# https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
RUN apt-get update && apt-get -y install \
    ninja-build      \
    libtool-bin      \
    libeigen3-dev    \
    libboost-dev

# Make symlinks to avoid adding /usr/include to include dirs.
RUN mkdir -p /opt/wasm-deps/include && mkdir -p /opt/wasm-deps/lib && mkdir -p /opt/wasm-deps/share && \
    ln -s /usr/include/boost   /opt/wasm-deps/include/boost  && \
    ln -s /usr/include/eigen3  /opt/wasm-deps/include/eigen3 && \
    ln -s /usr/lib/cmake       /opt/wasm-deps/lib/cmake && \
    ln -s /usr/share/eigen3    /opt/wasm-deps/share/eigen3

# Add qmake to PATH (doesn't seem to work)
#ENV PATH="/opt/Qt/bin:${PATH}"

# Build custom sources
WORKDIR /project/build

# Default build command will explicitly target wasm
CMD /opt/Qt/bin/qt-cmake -DCMAKE_BUILD_TYPE=Release -G Ninja /project/source && ninja
