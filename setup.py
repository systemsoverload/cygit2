from skbuild import setup
from setuptools import find_packages, Extension

# Define Cython extensions
extensions = [
Extension(
        "cygit2._commit",
        ["src/cygit2/_commit.pyx"],
    ),
Extension(
        "cygit2._index",
        ["src/cygit2/_index.pyx"],
    ),
    Extension(
        "cygit2._oid",
        ["src/cygit2/_oid.pyx"],
    ),
    Extension(
        "cygit2._reference",
        ["src/cygit2/_reference.pyx"],
    ),
    Extension(
        "cygit2._repository",
        ["src/cygit2/_repository.pyx"],
    ),
    Extension(
        "cygit2._signature",
        ["src/cygit2/_signature.pyx"],
    ),
    Extension(
        "cygit2._signature",
        ["src/cygit2/_signature.pyx"],
    ),

]

setup(
    name="cygit2",
    version="0.1.0",
    description="High-performance Cython bindings for libgit2",
    author='Your Name',
    license="MIT",
    package_dir={"": "src"},
    packages=find_packages(where="src"),
    python_requires=">=3.8",
    ext_modules=extensions,
    setup_requires=["cython>=3.0.0"],
)
