# openwrt compiler

Container image and firmware build for this fork.

## Build locally

```bash
git clone https://github.com/c127dev/openwrt.git
cd openwrt
git checkout mercusys-mr80x-v2-wired
git worktree add .packaging compiler

podman build -t openwrt-compiler .packaging
podman run --rm --user build -v "$PWD:/work:z" -w /work openwrt-compiler bash -c '
  ./scripts/feeds update -a && ./scripts/feeds install -a &&
  cp .packaging/configs/mr80x-v2-wired.diffconfig .config &&
  make defconfig && make -j"$(nproc)"'
```

Images land in `bin/targets/qualcommax/ipq50xx/`.

## Build on GitHub

Actions tab, workflow `build`, branch `compiler`, Run workflow. Or:

```bash
curl -X POST \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $GH_TOKEN" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    https://api.github.com/repos/c127dev/openwrt/actions/workflows/build.yml/dispatches \
    -d '{"ref":"compiler","inputs":{"source_ref":"mercusys-mr80x-v2-wired"}}'
```

204 means accepted. Token: fine-grained, this repo, Actions read and write.

Inputs: `source_ref` (branch or sha), `config` (file under `configs/`),
`release` (attach the images to a GitHub release, default true),
`imagebuilder` (default true), `all_kmods` (default true), `sdk`
(default false).

## Adding packages to a released image

The release carries `openwrt-imagebuilder-*.tar.zst`. On x86_64 Linux:

```bash
tar xf openwrt-imagebuilder-*.tar.zst
cd openwrt-imagebuilder-*
make info
make image PROFILE=mercusys_mr80x-v2 \
    PACKAGES="sqm-scripts luci-app-sqm tc-full kmod-sched-cake"
```

It selects from packages already built, so `all_kmods` decides whether an
arbitrary kmod is available. It compiles nothing; a package that needs
building needs the SDK instead.

`openwrt-packages-<tag>.tar.zst` unpacks into an apk feed. The image carries
the key that signed it, so only the URL has to be added:

```
echo https://example/packages/aarch64_cortex-a53/base/packages.adb \
    >> /etc/apk/repositories.d/customfeeds.list
```

Packages installed that way live in the overlay and do not survive
sysupgrade. Rolling them into the image does.

The image is pushed to `ghcr.io/c127dev/openwrt-compiler`. Release tags are
`vYYYY.MM.DD.<run>`, UTC.

Set repository secrets `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` to also
push `docker.io/<user>/openwrt-compiler`. With either unset the step logs
`ghcr.io only` and the run continues.

## Adding a config

```bash
make menuconfig
./scripts/diffconfig.sh > .packaging/configs/<name>.diffconfig
```

Then dispatch with `config=<name>.diffconfig`.

## Known limits

- A push to `compiler` starts a run that stops at `plan`. That is what
  registers the workflow with the Actions API; only `workflow_dispatch`
  builds.
- A full single-device build needs roughly 25 GB. The hosted runner has
  little margin over that; a disk-full failure shows up as a link error deep
  in the toolchain. `all_kmods` and `sdk` both add to that, and the host's
  own free space cannot be reclaimed from a container job, so the usual
  runner-cleanup steps do not apply here. Turn them off per dispatch if a
  build dies without naming a cause, and compare the two `df -h /` steps.
