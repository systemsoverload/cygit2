# src/cygit2/__init__.py

"""
cygit2: High-performance Cython bindings for libgit2
"""

from ._repository import Repository
# from ._index import Index
# from ._reference import Reference
from .errors import (
    GitError,
    NotFoundError,
    ExistsError,
    AmbiguousError,
    BareRepoError,
    UnbornBranchError,
    UnmergedError,
    NonFastForwardError,
    InvalidSpecError,
    ConflictError,
    LockedError,
    ModifiedError,
    AuthError,
    UncommittedError,
    NotARepoError,
)

__version__ = "0.1.0"

__all__ = [
    "Repository",
    # "Index",
    # "Reference",
    "GitError",
    # "NotFoundError",
    # "ExistsError",
    # "AmbiguousError",
    # "BareRepoError",
    # "UnbornBranchError",
    # "UnmergedError",
    # "NonFastForwardError",
    # "InvalidSpecError",
    # "ConflictError",
    # "LockedError",
    # "ModifiedError",
    # "AuthError",
    # "UncommittedError",
    # "NotARepoError",
]
