FROM ubuntu:24.04

# Avoid prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install essential tools
RUN apt-get update && apt-get install -y \
    # Build essentials
    build-essential \
    git \
    curl \
    wget \
    unzip \
    # Fuse emulator for ZX Spectrum
    fuse-emulator-sdl \
    fuse-emulator-utils \
    # BASIC to TAP conversion
    zmakebas \
    # Text editors
    vim \
    nano \
    # Utilities
    make \
    # Screenshot and video capture (headless)
    xvfb \
    imagemagick \
    xdotool \
    openbox \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# Build PasmoNext from source
RUN git clone --depth 1 https://github.com/Ckirby101/pasmoNext.git /tmp/pasmoNext && \
    cd /tmp/pasmoNext/pasmo && \
    g++ -O2 -o pasmonext *.cpp && \
    mv pasmonext /usr/local/bin/ && \
    rm -rf /tmp/pasmoNext

# Add screenshot and video capture scripts
COPY scripts/spectrum-screenshot.sh /usr/local/bin/spectrum-screenshot
COPY scripts/spectrum-video.sh /usr/local/bin/spectrum-video
RUN chmod +x /usr/local/bin/spectrum-screenshot /usr/local/bin/spectrum-video
COPY scripts/inputs /scripts/inputs
RUN chmod +x /scripts/inputs/*.sh

# Create workspace directory
WORKDIR /workspace

# Add helpful message when container starts
RUN echo '#!/bin/bash\n\
echo "╔════════════════════════════════════════════════════════════╗"\n\
echo "║   ZX Spectrum Development - Code Like It'"'"'s 198x         ║"\n\
echo "╚════════════════════════════════════════════════════════════╝"\n\
echo ""\n\
echo "📦 Tools installed:"\n\
echo "  • PasmoNext       - Z80 assembler (ZX Spectrum Next support)"\n\
echo "  • Fuse emulator   - Run ZX Spectrum programs"\n\
echo "  • zmakebas        - Convert BASIC text to TAP"\n\
echo ""\n\
echo "🚀 Quick start:"\n\
echo "  pasmonext --tapbas program.asm program.tap  # Assemble to TAP"\n\
echo "  pasmonext --sna program.asm program.sna     # Assemble to snapshot"\n\
echo "  fuse --machine 48 program.tap               # Run in emulator"\n\
echo "  spectrum-screenshot prog.sna out.png        # Headless screenshot"\n\
echo "  spectrum-video prog.sna out.mp4            # Video with input"\n\
echo "  zmakebas -o program.tap -n GAME source.bas  # Convert BASIC"\n\
echo ""\n\
echo "📚 Examples available in /workspace/examples/"\n\
echo ""\n\
' > /usr/local/bin/welcome && chmod +x /usr/local/bin/welcome

# Set default command to show welcome message
CMD ["/bin/bash", "-c", "welcome && /bin/bash"]
