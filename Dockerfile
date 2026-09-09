# syntax=docker/dockerfile:1
FROM haskell:9.6.5-slim-buster AS build

# Ensure cabal matches the version used by CI
RUN cabal update && cabal --version

# Install system dependencies required by the build (matches
# .github/workflows/build-cli.yml)
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        pkg-config \
        build-essential \
        libgmp-dev \
        libffi-dev \
        zlib1g-dev \
        git \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Build libblst from source and register it with pkg-config, mirroring the
# "ZER blst bridge" step from the GitHub Actions workflow.
RUN git clone --depth 1 https://github.com/supranational/blst.git /tmp/blst \
    && cd /tmp/blst \
    && ./build.sh \
    && mkdir -p /usr/local/lib/pkgconfig \
    && cp libblst.a /usr/local/lib/ \
    && mkdir -p /usr/local/include \
    && cp bindings/blst.h bindings/blst_aux.h /usr/local/include/ \
    && printf "%s\n" \
        "prefix=/usr/local" \
        "libdir=\${prefix}/lib" \
        "includedir=\${prefix}/include" \
        "Name: libblst-any" \
        "Description: blst" \
        "Version: 0.3.0" \
        "Libs: -L\${libdir} -lblst" \
        "Cflags: -I\${includedir}" \
        > /usr/local/lib/pkgconfig/libblst-any.pc \
    && ldconfig \
    && rm -rf /tmp/blst

ENV PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:/usr/lib/x86_64-linux-gnu/pkgconfig:/usr/lib/pkgconfig:/usr/share/pkgconfig"
ENV PKG_CONFIG_LIBDIR="/usr/local/lib/pkgconfig:/usr/lib/x86_64-linux-gnu/pkgconfig:/usr/lib/pkgconfig:/usr/share/pkgconfig"

WORKDIR /src

# Copy cabal/project files first to leverage Docker layer caching for
# dependency resolution.
COPY cabal.project cardano-loans.cabal cardano-loans-standalone.cabal ./

RUN cabal update --index-state=2026-01-01T00:00:00Z

# Now copy the rest of the source and build the CLI executable.
COPY . .

RUN cabal build exe:cardano-loans -v2 \
    && mkdir -p /app \
    && cp "$(cabal list-bin exe:cardano-loans)" /app/cardano-loans \
    && chmod +x /app/cardano-loans

FROM debian:bullseye-slim AS runtime

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libgmp10 \
        libffi7 \
        zlib1g \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY --from=build /app/cardano-loans /app/cardano-loans

ENTRYPOINT ["/app/cardano-loans"]
CMD []
