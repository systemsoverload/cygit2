# cygit2

cygit2 is a high-performance Python binding for libgit2, implemented in Cython. It provides a Pythonic interface to Git operations while maintaining the speed and efficiency of libgit2. 

## Development

To set up the development environment:

1. Install [rye](https://rye-up.com/guide/installation/):
```bash
curl -sSf https://rye-up.com/get | bash
```

2. Clone the repository and navigate to the project directory:
```bash
git clone https://github.com/yourusername/cygit2.git
cd cygit2
```

3. Set up the development environment with rye:
```bash
rye sync
```

4. Build the Cython extensions:
```bash
rye run python -m build
```

5. Run the tests:
```bash
rye run pytest
```

For development, you'll need to have libgit2 installed on your system. On Ubuntu/Debian:
```bash
sudo apt-get install libgit2-dev
```

On macOS with Homebrew:
```bash
brew install libgit2
```

## License

MIT License - see LICENSE file for details.
