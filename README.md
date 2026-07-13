# optimize

> Build optimized Debian/Ubuntu packages from source with hardware-specific compiler flags.

A modern replacement for `apt-build`. Downloads official source packages, compiles them in an isolated `sbuild` chroot with aggressive optimization flags (`-O3 -march=native -pipe`), and delivers ready-to-install `.deb` files — bringing Arch-style compilation to the Debian/Ubuntu ecosystem.

## ✨ Features

- **Hardware-specific optimization** — Compiles packages with `-O3 -march=native -pipe` to leverage your CPU's full instruction set
- **Custom Kernel Tailoring** — Use `--kernel` to automatically build a lean, native-optimized kernel trimmed strictly to your active hardware via `localmodconfig`
- **Isolated builds** — Uses `sbuild` chroots to guarantee clean, reproducible builds that won't conflict with your system packages
- **Universal compatibility** — Works on Debian and all derivatives: Ubuntu, Linux Mint, Pop!_OS, MX Linux, Zorin OS, and more
- **Automatic environment detection** — Dynamically discovers your distribution, codename, and architecture — no hardcoded values
- **Smart dependency management** — Auto-installs required tools (`sbuild`, `dpkg-dev`, `devscripts`, etc.) if missing
- **Source repo handling** — Detects and enables `deb-src` repositories in both DEB822 and legacy formats
- **Customizable flags** — Override default optimization flags via CLI for fine-tuned control
- **Clean operation** — Automatic cleanup of temporary files, even on interruption

## 📋 Requirements

- A **Debian-based** Linux distribution (Debian, Ubuntu, or any derivative)
- **sudo** access
- Internet connection (to download source packages and create chroots)

## 🚀 Installation

```bash
# Clone the repository
git clone https://github.com/helton/optimize.git
cd optimize

# Make the script executable
chmod +x optimize

# (Optional) Install system-wide
sudo cp optimize /usr/local/bin/
```

## 📖 Usage

### Basic Usage

```bash
# Build a package with default optimization flags
./optimize nginx

# Build the GNU hello package (great for testing)
./optimize hello
```

### Custom Kernel Build

Build a fully optimized kernel tailored specifically to your active hardware (disables unused modules via `localmodconfig` and applies `-march=native -O2`):

```bash
sudo ./optimize --kernel
```

### Custom Flags

```bash
# Use custom CFLAGS
./optimize --cflags="-O2 -march=znver4 -pipe" zlib

# Use custom CFLAGS and CXXFLAGS
./optimize --cflags="-O2 -march=native" --cxxflags="-O2 -march=native" mesa
```

### Parallel Jobs

```bash
# Limit to 4 parallel build jobs
./optimize -j4 mesa
```

### All Options

```
optimize [OPTIONS] <package-name>

OPTIONS
    -c, --cflags FLAGS      Custom CFLAGS   (default: "-O3 -march=native -pipe")
    -x, --cxxflags FLAGS    Custom CXXFLAGS (default: "-O3 -march=native -pipe")
    -j, --jobs N            Parallel build jobs (default: auto via nproc)
    -k, --kernel            Build a custom tailored kernel for this hardware
    -h, --help              Show help message
    -V, --version           Show version information
```

## 🔧 How It Works

```
optimize nginx
    │
    ├─ 1. Detect OS & Architecture
    │     └─ Reads /etc/os-release, resolves upstream codename
    │
    ├─ 2. Check Dependencies
    │     └─ Installs sbuild, dpkg-dev, devscripts if missing
    │
    ├─ 3. Ensure Source Repos
    │     └─ Verifies deb-src is enabled (DEB822 + legacy formats)
    │
    ├─ 4. Ensure Chroot Exists
    │     └─ Creates sbuild chroot if needed (mk-sbuild or sbuild-createchroot)
    │
    ├─ 5. Configure Optimization Flags
    │     └─ Injects flags into ~/.sbuildrc via $build_environment
    │
    ├─ 6. Download Source
    │     └─ apt-get source <package> into /tmp/optimize.XXXXXXXXXX
    │
    ├─ 7. Build in Isolated Chroot
    │     └─ sbuild -d <suite> --arch=<arch> --no-run-lintian -A
    │
    └─ 8. Deliver .deb Files
          └─ Copies to your current directory with install instructions
```

## 🐧 Supported Distributions

| Distribution | Base | Detection Method |
|---|---|---|
| **Debian** (bookworm, trixie, sid) | debian | `VERSION_CODENAME` |
| **Ubuntu** (noble, jammy, focal) | ubuntu | `UBUNTU_CODENAME` |
| **Linux Mint** (wilma, etc.) | ubuntu | `UBUNTU_CODENAME` → upstream |
| **Pop!_OS** | ubuntu | `UBUNTU_CODENAME` |
| **MX Linux** | debian | `VERSION_CODENAME` |
| **Zorin OS** | ubuntu | `UBUNTU_CODENAME` |
| **Other Debian derivatives** | auto | `ID_LIKE` chain |

## ⚙️ Configuration

### Optimization Flags

The script manages its own block in `~/.sbuildrc` between marker comments:

```perl
# >>> optimize optimization flags >>>
$build_environment = {
    'DEB_CFLAGS_APPEND'   => '-O3 -march=native -pipe',
    'DEB_CXXFLAGS_APPEND' => '-O3 -march=native -pipe',
};
# <<< optimize optimization flags <<<
```

Your existing `.sbuildrc` settings outside this block are preserved.

### Default Flags Explained

| Flag | Purpose |
|---|---|
| `-O3` | Maximum optimization level — enables aggressive inlining, vectorization, and loop transformations |
| `-march=native` | Targets your specific CPU — enables AVX, SSE4.2, BMI2, and other instruction sets your CPU supports |
| `-pipe` | Uses pipes instead of temporary files between compilation stages — speeds up builds |

## ⚠️ Important Notes

- **Packages are NOT portable**: Binaries compiled with `-march=native` use CPU-specific instructions and may crash on different hardware
- **First run takes longer**: Creating the sbuild chroot requires downloading a base system (typically 200-500 MB)
- **Some packages may fail**: Not all packages compile cleanly with `-O3`. If a build fails, try with `-O2`:
  ```bash
  ./optimize --cflags="-O2 -march=native -pipe" <package>
  ```

## 🔍 Troubleshooting

### "Source repositories (deb-src) are not enabled"

The script will offer to enable them automatically. If you prefer manual setup:

**DEB822 format** (Ubuntu 24.04+, Debian Trixie+):
```bash
sudo sed -i 's/^Types: deb$/Types: deb deb-src/' /etc/apt/sources.list.d/*.sources
sudo apt update
```

**Legacy format** (older systems):
```bash
sudo sed -i '/^#\s*deb-src/s/^#\s*//' /etc/apt/sources.list
sudo apt update
```

### "User is not in the sbuild group"

```bash
sudo usermod -aG sbuild $USER
# Then log out and log back in
```

### Build fails with specific packages

Try reducing the optimization level:
```bash
./optimize --cflags="-O2 -march=native -pipe" <package>
```

## 📄 License

[MIT](LICENSE)

