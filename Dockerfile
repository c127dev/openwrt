FROM debian:trixie-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
	build-essential clang flex bison g++ gawk gcc-multilib g++-multilib \
	gettext git libncurses-dev libssl-dev python3 python3-dev \
	python3-setuptools rsync unzip zlib1g-dev file wget swig time \
	ca-certificates curl xz-utils zstd ccache subversion quilt \
	libelf-dev libpython3-dev jq \
	&& rm -rf /var/lib/apt/lists/*

# OpenWrt buildroot refuses to run as root.
RUN useradd -m -u 1000 build
USER build
WORKDIR /work
