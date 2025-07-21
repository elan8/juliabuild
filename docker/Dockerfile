# Use the official Julia Packaging Windows x86_64 image as the base
FROM juliapackaging/package-windows-x86_64:latest

# Set environment variable to build GPL-free
ENV USE_GPL_LIBS=0

# Set working directory
WORKDIR /build
# Clone Julia v1.11.6 source code
RUN git clone --branch v1.11.6 --depth 1 https://github.com/JuliaLang/julia.git

# Set working directory to Julia source
WORKDIR /build/julia

# (Optional) Show environment and version for debugging
RUN echo "Building Julia GPL-free" && \
    echo "USE_GPL_LIBS=$USE_GPL_LIBS" && \
    git --version

# Build Julia
RUN make -j 4

# (Optional) Set default command to Julia REPL
CMD ["./julia", "--version"] 