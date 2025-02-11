ARG BUILD_DIR=/build
ARG JAVA_VERSION=23
# Build and test jar
FROM bellsoft/liberica-openjdk-alpine:${JAVA_VERSION} AS jar_builder
ENV M2_HOME=/opt/maven
RUN mkdir -p $M2_HOME && wget -qO- https://dlcdn.apache.org/maven/maven-3/3.9.9/binaries/apache-maven-3.9.9-bin.tar.gz | tar -xzvf - -C $M2_HOME --strip-components=1

ARG BUILD_DIR
WORKDIR $BUILD_DIR
COPY . .
RUN $M2_HOME/bin/mvn --batch-mode clean package
# Build native image
FROM ghcr.io/graalvm/native-image-community:${JAVA_VERSION} AS native_image_builder
ARG BUILD_DIR
WORKDIR $BUILD_DIR

ARG MUSL_LOCATION=https://more.musl.cc/10/x86_64-linux-musl
ARG ZLIB_LOCATION=https://zlib.net/fossils/zlib-1.2.11.tar.gz
ARG MUSL_NAME=armv7r-linux-musleabihf-native.tgz
ENV TOOLCHAIN_DIR=/usr/local/musl \
    CC=$TOOLCHAIN_DIR/bin/gcc

RUN mkdir -p $TOOLCHAIN_DIR \
    && microdnf install -y wget tar gzip make \
    && wget $MUSL_LOCATION/$MUSL_NAME && tar -xvf $MUSL_NAME -C $TOOLCHAIN_DIR --strip-components=1  \
    && wget $ZLIB_LOCATION && tar -xvf zlib-1.2.11.tar.gz \
    && cd zlib-1.2.11 \
    && ./configure --prefix=$TOOLCHAIN_DIR --static \
    && make && make install

ENV PATH=$TOOLCHAIN_DIR/bin:$PATH

ARG UPX_VERSION=4.2.4
ARG UPX_ARCHIVE=upx-${UPX_VERSION}-amd64_linux.tar.xz
RUN microdnf -y install wget xz && \
    wget -q https://github.com/upx/upx/releases/download/v${UPX_VERSION}/${UPX_ARCHIVE} && \
    tar -xJf ${UPX_ARCHIVE} && \
    rm -rf ${UPX_ARCHIVE} && \
    mv upx-${UPX_VERSION}-amd64_linux/upx . && \
    rm -rf upx-${UPX_VERSION}-amd64_linux

COPY --from=jar_builder $BUILD_DIR/target/oracle-sql-rearranger.jar $BUILD_DIR/
COPY --from=jar_builder $BUILD_DIR/target/lib/ $BUILD_DIR/lib/
RUN native-image --diagnostics-mode --verbose --target=linux-aarch64 -march=armv8-a --static --libc=glibc -Os --module-path lib:oracle-sql-rearranger.jar --module kg/kg.Main -o native_binary_out -H:+UnlockExperimentalVMOptions -H:-CheckToolchain
RUN ls -al # size check
RUN ./native_binary_out || true # test if runnable

# Compress the executable with UPX
RUN ./upx --lzma --best -o app.upx native_binary_out
RUN ./app.upx || true # test if runnable
RUN ls -al # size check

#
FROM scratch
ARG BUILD_DIR
COPY --from=native_image_builder $BUILD_DIR/app.upx /app
ENTRYPOINT ["/app"]
