FROM debian:trixie-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
	build-essential clang flex bison g++ gawk gcc-multilib g++-multilib \
	gettext git libncurses-dev libssl-dev python3 python3-dev \
	python3-setuptools rsync unzip zlib1g-dev file wget swig time \
	ca-certificates curl xz-utils zstd ccache subversion quilt \
	libelf-dev libpython3-dev jq \
	&& rm -rf /var/lib/apt/lists/*

# Buildroot refuses to run as root, but a container job must start as root
# or the runner's own files under /__w are unwritable. The workflow drops to
# this user for make.
RUN useradd -m -u 1000 -s /bin/bash build
WORKDIR /work
