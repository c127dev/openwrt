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
`release` (attach the images to a GitHub release, default true).

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
  in the toolchain.
