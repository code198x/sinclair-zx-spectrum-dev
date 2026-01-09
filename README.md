# Sinclair ZX Spectrum Development Environment

Docker-based development environment for ZX Spectrum programming with Sinclair BASIC and Z80 Assembly language support.

## 🎯 What's Included

- **pasmonext** - Z80 cross-assembler (Pasmo fork with enhancements)
- **Fuse Emulator** - Complete ZX Spectrum emulator (48K/128K support)
- **zmakebas** - Convert BASIC text files to TAP format
- **Build tools** - make, git, and essential utilities

## 🚀 Quick Start

### Option 1: Docker Compose (Recommended)

```bash
# Start the environment
docker-compose up -d

# Enter the container
docker-compose exec zx-spectrum-dev bash

# Stop when done
docker-compose down
```

### Option 2: VS Code Dev Container

1. Install the "Dev Containers" extension in VS Code
2. Open this folder in VS Code
3. Click "Reopen in Container" when prompted
4. VS Code will build and start the container automatically

### Option 3: Docker CLI

```bash
# Build the image
docker build -t code198x/sinclair-zx-spectrum:latest .

# Run interactively
docker run -it --rm -v $(pwd):/workspace code198x/sinclair-zx-spectrum:latest

# Or run a specific command
docker run --rm -v $(pwd):/workspace code198x/sinclair-zx-spectrum:latest \
  pasmonext program.asm
```

## 📚 Examples

Example projects are included:

### Assembly - Hello World
```bash
cd examples/assembly/hello
make          # Build
make run      # Run in Fuse
```

### Assembly - Pong Game
Simple Pong implementation demonstrating sprite movement and collision:
```bash
cd examples/assembly/pong
make          # Build
make run      # Run in Fuse
```

### BASIC - Number Guess
Number guessing game from the BASIC lessons:
```bash
cd examples/basic/number-guess
make          # Convert to TAP
make run      # Run in Fuse
```

## 🛠️ Common Commands

### Assembly Development

```bash
# Assemble a program
pasmonext --lst=program.lst program.asm

# Output is typically program.tap (for tape loading)
# Or program.sna (snapshot format)

# Run in emulator
fuse --machine 48 program.tap
```

### Screenshot Capture (Headless)

Capture screenshots from programs without a display:

```bash
# Capture from snapshot (instant load)
docker run --rm -v $(pwd):/workspace zx-spectrum-dev \
  spectrum-screenshot program.sna screenshot.png

# Capture from tape (needs longer wait for loading)
docker run --rm -v $(pwd):/workspace zx-spectrum-dev \
  spectrum-screenshot program.tap screenshot.png --wait 10

# Use 128K Spectrum
docker run --rm -v $(pwd):/workspace zx-spectrum-dev \
  spectrum-screenshot program.sna screenshot.png --machine 128
```

**Options:**
- `--wait SECONDS` - Time to wait before capture (default: 3 for .sna, 8 for .tap)
- `--machine TYPE` - Spectrum model: 48, 128, plus2, plus3 (default: 48)

**Tips:**
- Use `.sna` snapshots for faster, more reliable screenshots
- Build with `pasmonext --sna program.asm program.sna` and include `end start` directive
- Increase `--wait` if your program needs time to initialise

### BASIC Development

```bash
# Convert BASIC text to TAP
zmakebas -o program.tap -n GAMENAME source.bas

# The -n flag sets the BASIC program name (max 10 chars)

# Run the program
fuse --machine 48 program.tap
```

### Project Structure

Recommended project layout:
```
my-project/
├── src/
│   ├── main.asm      # Main source file
│   └── includes/     # Include files
├── build/            # Build output
├── Makefile          # Build automation
└── README.md         # Project documentation
```

## 🎓 Learning Resources

This environment is designed for use with the [Code Like It's 198x](https://code198x.stevehill.xyz) educational platform.

**Courses available:**
- ZX Spectrum BASIC Phase 0 - Game development fundamentals
- ZX Spectrum Assembly Phase 1 - Hardware mastery

**Code samples:** https://github.com/code198x/code-samples

## 🔧 Troubleshooting

### Running Fuse (Recommended Workflow)

**This container is designed primarily for building ZX Spectrum programs.** For the best experience:

1. **Build in the container** - Use the Docker environment for consistent compilation
2. **Run on your host** - Use Fuse installed natively on your machine for testing

```bash
# Build in container
docker run --rm -v $(pwd):/workspace ghcr.io/code198x/sinclair-zx-spectrum:latest \
  pasmonext program.asm

# Run on host (install Fuse natively)
fuse program.tap
```

**Why this approach?**
- Native Fuse provides better performance and display quality
- Avoids complex X11 forwarding configuration on macOS
- Simpler setup for beginners

### Installing Fuse on Your Host

**macOS:**
```bash
brew install fuse-emulator
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt-get install fuse-emulator-sdl
```

**Windows:**
Download from [Fuse website](http://fuse-emulator.sourceforge.net/)

### Advanced: Running Fuse from Container

If you need to run Fuse from within the container, X11 forwarding is required:

**macOS with XQuartz:**
```bash
# Install XQuartz
brew install --cask xquartz

# Enable TCP connections
defaults write org.xquartz.X11 nolisten_tcp 0

# Restart XQuartz and allow connections
xhost +localhost
```

**Linux:**
```bash
# Allow X11 connections
xhost +local:docker

# Run with display forwarding
docker run --rm -e DISPLAY=$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix ...
```

### Headless Mode

For automated builds and CI/CD:
```bash
# Just assemble, don't run emulator
pasmonext program.asm
```

### File Permissions

If you encounter permission issues:

```bash
# Change ownership to your user
sudo chown -R $(whoami):$(whoami) .
```

## 📝 Makefile Template

Create a `Makefile` in your project:

```makefile
# Assembly project
TARGET = program
SRC = $(TARGET).asm

all: $(TARGET).tap

$(TARGET).tap: $(SRC)
	pasmonext --lst=$(TARGET).lst $<

run: $(TARGET).tap
	fuse --machine 48 $<

clean:
	rm -f $(TARGET).tap $(TARGET).lst

.PHONY: all run clean
```

**Usage:**
```bash
# Build in container
docker run --rm -v $(pwd):/workspace ghcr.io/code198x/sinclair-zx-spectrum:latest make

# Run on host (requires Fuse installed locally)
make run
```

## 🐳 Building Custom Images

To customize the environment:

1. Edit `Dockerfile` to add tools or change configuration
2. Rebuild:
   ```bash
   docker-compose build
   # or
   docker build -t code198x/sinclair-zx-spectrum:latest .
   ```

## 📦 Publishing

To share your image on Docker Hub:

```bash
# Tag with version
docker tag code198x/sinclair-zx-spectrum:latest code198x/sinclair-zx-spectrum:v1.0.0

# Push to Docker Hub
docker push code198x/sinclair-zx-spectrum:latest
docker push code198x/sinclair-zx-spectrum:v1.0.0
```

## 🤝 Contributing

This environment is part of the Code Like It's 198x educational project.

**Repository:** https://github.com/code198x/sinclair-zx-spectrum-dev

## 📄 License

MIT License - See LICENSE file for details

## 🎮 About

Code Like It's 198x teaches retro game development for classic 8-bit and 16-bit systems. This ZX Spectrum environment provides everything needed to start coding for Britain's most iconic home computer.

**Website:** https://code198x.stevehill.xyz
**Course Materials:** https://github.com/code198x/
