# Based on https://github.com/emscripten-core/emsdk/tree/master/docker
FROM emscripten/emsdk:3.1.27 AS base

ENV CUSTOM_TOOLCHAIN_FLAGS=/customtoolchainflags.cmake

COPY customtoolchainflags.cmake /

FROM base AS qtbuilder

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
RUN curl -L https://download.qt.io/official_releases/qt/6.5/6.5.0/single/qt-everywhere-src-6.5.0.tar.xz --output src.tar.xz
RUN XZ_OPT='-T0' tar -xf src.tar.xz
RUN ln -s qt-everywhere-src-* qt5
WORKDIR /development/qt5

# Build Qt for x64
RUN mkdir -p /development/qt5_build_x64
WORKDIR /development/qt5_build_x64
RUN /development/qt5/configure -nomake examples -nomake tests -prefix /usr/local/Qt-x64
RUN cmake --build . $EXTRA_BUILD_PARAMS
RUN cmake --install .

# Build Qt for WASM
WORKDIR /development/qt5/qtdeclarative
RUN curl 'https://codereview.qt-project.org/gitweb?p=qt/qtdeclarative.git;a=patch;h=fd7fe4450bcb13b5ccf37b166afdd8c8fd9ae5c5' --output patch1.patch
RUN patch -p1 < patch1.patch
RUN curl 'https://codereview.qt-project.org/gitweb?p=qt/qtdeclarative.git;a=patch;h=d66db6c80241e9ce7098e2650fb59a2183a42c84' --output patch2.patch
RUN patch -p1 < patch2.patch
WORKDIR /development/qt5
RUN mkdir -p /development/qt5_build
WORKDIR /development/qt5_build
RUN /development/qt5/configure -qt-host-path /usr/local/Qt-x64 -xplatform wasm-emscripten -feature-wasm-exceptions -feature-thread -nomake examples -prefix /usr/local/Qt-wasm
RUN cmake --build . $EXTRA_BUILD_PARAMS
RUN cmake --install .

FROM base as hdf5-builder

# COMPILE AND INSTALL SPECIFIC VERSION (1.8.23) OF HDF5
WORKDIR /build
# Download sources from official repo
RUN wget https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.8/hdf5-1.8.23/src/hdf5-1.8.23.tar.gz && \
    tar -xf hdf5-1.8.23.tar.gz
WORKDIR /build/hdf5-1.8.23
#inject wasm specific flags in the projects
RUN emcmake cmake -S . -B build-wasm -DCMAKE_INSTALL_PREFIX:PATH=/usr/local/hdf5 \
    -DCMAKE_BUILD_TYPE:STRING=Release \
    -DBUILD_SHARED_LIBS:BOOL=OFF \
    -DBUILD_TESTING:BOOL=OFF \
    -DHDF5_BUILD_CPP_LIB:BOOL=ON \
    -DHDF5_BUILD_EXAMPLES:BOOL=OFF \
    -DCMAKE_TOOLCHAIN_FILE=$CUSTOM_TOOLCHAIN_FLAGS
WORKDIR /build/hdf5-1.8.23/build-wasm
# Hugely important patch: redirect the output of the binary to a file (it should use the 1st argument... But it doesn't)
RUN sed -i 's/js H5/js > H5/g' src/CMakeFiles/gen_hdf5-static.dir/build.make
RUN emmake make -j`nproc` install

FROM base AS boost-builder

# COMPILE AND INSTALL SPECIFIC VERSION (1.59) OF BOOST
WORKDIR /build
RUN wget http://sourceforge.net/projects/boost/files/boost/1.81.0/boost_1_81_0.tar.gz && \
    tar -xf boost_1_81_0.tar.gz
WORKDIR /build/boost_1_81_0
# Configure to install everything to dedicated folder (easier to copy later)
RUN ./bootstrap.sh --with-icu=/emsdk/upstream/emscripten/cache/ports/icu/icu --prefix=/usr/local/boost
# actually we use headers-only build, using the --with-headers library allow us to install boost without actually building anything
# if one want to build libraries, he can remove the --with-headers flags and all libraries will be built.
# Build was tested with: --without-python --without-iostreams --without-test
RUN ./b2 toolset=emscripten variant=release \
    --prefix=/usr/local/boost --build-dir=/build/tmp \
    link=static threading=multi \
    linkflags='-s USE_PTHREADS=1' cflags='-s USE_PTHREADS=1 -fwasm-exceptions' cxxflags='-pthread -fwasm-exceptions' \
    --with-headers \
    -j`nproc` install

FROM base AS eigen-builder

# add Eigen
WORKDIR /build
RUN wget https://gitlab.com/libeigen/eigen/-/archive/3.4.0/eigen-3.4.0.tar.gz && \
    tar -xf eigen-3.4.0.tar.gz
WORKDIR /build/eigen-3.4.0
RUN emcmake cmake -S . -B build-wasm -DCMAKE_INSTALL_PREFIX:PATH=/usr/local/eigen -DCMAKE_BUILD_TYPE:STRING=Release
WORKDIR /build/eigen-3.4.0/build-wasm
RUN emmake make -j`proc` install

FROM base

# Copy Qt binaries to new container
COPY --from=boost-builder /usr/local/boost/ /usr/local/boost/
COPY --from=eigen-builder /usr/local/eigen/ /usr/local/eigen/
COPY --from=hdf5-builder /usr/local/hdf5/ /usr/local/hdf5/
COPY --from=qtbuilder /usr/local/Qt-x64/  /usr/local/Qt-x64/
COPY --from=qtbuilder /usr/local/Qt-wasm/ /usr/local/Qt-wasm/

RUN apt-get update && apt-get -y install \
    ninja-build      \
    libtool-bin

# Build custom sources
WORKDIR /project/build

# Default build command will explicitly target wasm
CMD /usr/local/Qt-wasm/bin/qt-cmake -DCMAKE_BUILD_TYPE=Release -G Ninja /project/source && ninja
