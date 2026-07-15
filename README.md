# optimize

`optimize v2.0.0` rebuilds official Debian/Ubuntu source packages with
hardware-aware optimization while preserving the normal Debian packaging flow.

The project is a spiritual successor to `apt-build`, but the central rule is
different: `optimize` does not patch package sources or replace `debian/rules`.
It orchestrates `sbuild`, uses the source package from the configured APT
repositories, and changes only controlled build parameters.

## Goals

- Rebuild official Debian/Ubuntu source packages in clean `sbuild` environments.
- Preserve maintainer packaging logic, distribution patches, build dependencies,
  hardening defaults, and package tests by default.
- Offer hardware-aware optimization profiles with deterministic fallback.
- Keep each rebuilt package identifiable through a local version suffix.
- Produce a manifest with source, profile, flags, test mode, artifacts, and
  checksums.

## Profiles

| Profile | Behavior |
|---|---|
| `vendor` | Distribution flags unchanged. Useful as a control build. |
| `native-safe` | Default. Preserves the distribution optimization level and appends native CPU targeting such as `-march=native -pipe`. |
| `native-aggressive` | Appends `-O3` plus native CPU targeting. Higher risk and opt-in. |
| `adaptive` | Tries `native-aggressive`, then `native-safe`, then `vendor`. |
| `custom` | Selected automatically when `--cflags` or `--cxxflags` is used. |

The default is intentionally `native-safe`, not universal `-O3`. This better
matches the objective of preserving Debian/Ubuntu robustness while still
specializing generated code for the local machine.

## Usage

```bash
./optimize hello
./optimize --profile native-aggressive nginx
./optimize --profile adaptive mesa
./optimize --profile vendor zlib
./optimize --cflags "-O2 -march=znver4 -pipe" zlib
```

Build products are written under `./optimize-output` by default. To install the
generated packages, use:

```bash
./optimize --install hello
```

Installation is performed with `apt-get install ./package.deb`, not
`dpkg --force-overwrite`.

## Important Options

```text
  -p, --profile NAME          vendor, native-safe, native-aggressive, adaptive
  -c, --cflags FLAGS          custom DEB_CFLAGS_APPEND
  -x, --cxxflags FLAGS        custom DEB_CXXFLAGS_APPEND
  -j, --jobs N                parallel jobs
  -o, --output-dir DIR        output directory
      --suite CODENAME        override detected suite
      --chroot-mode MODE      auto, unshare, or schroot
      --no-check              explicitly disable package tests
      --install               install generated packages
      --keep-build            keep temporary workspace
  -k, --kernel                experimental tailored kernel build
  -V, -v, --version           show version
```

## How Package Builds Work

1. Detect Debian/Ubuntu base, suite, and architecture.
2. Verify required tools and source repositories.
3. Select an `sbuild` backend (`unshare` tarball when available, otherwise
   `schroot`).
4. Download the official source package with `apt-get source --download-only`.
5. Unpack a temporary copy per attempted profile.
6. Prepend a local changelog entry such as
   `1.2.3-1+opt2.nativesafe.20260714T120000Z`.
7. Run `sbuild` with a temporary `SBUILD_CONFIG`.
8. Copy artifacts and write `manifest.yaml`.

The version suffix is higher than the rebuilt official version and lower than a
future Debian/Ubuntu revision such as `1.2.3-2`, allowing normal distribution
updates to supersede local rebuilds.

## Tests

Package tests are enabled by default. Use `--no-check` only when explicitly
accepting that tradeoff:

```bash
./optimize --no-check hello
```

In `adaptive` mode, a build or test failure in an aggressive profile causes a
deterministic fallback to the next profile.

## Kernel Mode

Kernel builds are intentionally marked experimental:

```bash
./optimize --kernel
```

The current kernel path uses the distribution kernel source, the running kernel
configuration, `localmodconfig`, hardware inventory, and `KCFLAGS="-O2
<native-target>"` when the compiler accepts a native CPU target. If native CPU
flags cannot be validated, the kernel build continues with `KCFLAGS="-O2"` and
still applies the configuration reduction steps. It does not yet reproduce the
full official Debian/Ubuntu kernel packaging pipeline. The source resolver avoids
signed kernel wrapper packages such as `linux-signed-amd64` and uses the
buildable unsigned kernel source package instead. Review `config.diff` and keep
the previous kernel installed.

## Development Environment

The repository expects these development tools:

- `shellcheck`
- `shfmt`
- `bash-language-server`

Install them on Debian/Ubuntu systems with:

```bash
make bootstrap-dev
```

Run the local quality gate with:

```bash
make check
```

Useful targets:

```bash
make lint
make format
make test
make clean
```

CI runs the same `make check` gate before building the Debian package.
