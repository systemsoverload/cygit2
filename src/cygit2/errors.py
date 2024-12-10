from enum import IntEnum
from typing import Dict, Optional, Type


class GitErrorCode(IntEnum):
    """Git error codes from libgit2."""
    GIT_OK = 0

    # Critical errors
    GIT_ERROR = -1
    GIT_ENOTFOUND = -3
    GIT_EEXISTS = -4
    GIT_EAMBIGUOUS = -5
    GIT_EBUFS = -6
    GIT_EUSER = -7
    GIT_EBAREREPO = -8
    GIT_EUNBORNBRANCH = -9
    GIT_EUNMERGED = -10
    GIT_ENONFASTFORWARD = -11
    GIT_EINVALIDSPEC = -12
    GIT_ECONFLICT = -13
    GIT_ELOCKED = -14
    GIT_EMODIFIED = -15
    GIT_EAUTH = -16
    GIT_ECERTIFICATE = -17
    GIT_EAPPLIED = -18
    GIT_EPEEL = -19
    GIT_EEOF = -20
    GIT_EINVALID = -21
    GIT_EUNCOMMITTED = -22
    GIT_EDIRECTORY = -23
    GIT_EMERGECONFLICT = -24
    GIT_PASSTHROUGH = -30
    GIT_ITEROVER = -31
    GIT_RETRY = -32
    GIT_EMISMATCH = -33
    GIT_EINDEXDIRTY = -34
    GIT_EAPPLYFAIL = -35
    GIT_EOWNER = -36

    # Filesystem errors
    GIT_ENOTAREPO = -40
    GIT_ENOTNAMESPACED = -41


class GitError(Exception):
    """Base exception for all Git errors."""
    def __init__(self, error_code: GitErrorCode, message: Optional[str] = None):
        self.error_code = error_code
        self.message = message or ERROR_MESSAGES.get(error_code, f"Git error {error_code}")
        super().__init__(self.message)


class NotFoundError(GitError):
    """Raised when a Git object is not found."""
    pass


class ExistsError(GitError):
    """Raised when a Git object already exists."""
    pass


class AmbiguousError(GitError):
    """Raised when a reference is ambiguous."""
    pass


class BareRepoError(GitError):
    """Raised when attempting working directory operations on a bare repository."""
    pass


class UnbornBranchError(GitError):
    """Raised when HEAD points to a non-existent branch."""
    pass


class UnmergedError(GitError):
    """Raised when there are unmerged entries."""
    pass


class NonFastForwardError(GitError):
    """Raised when a non-fast-forward update is attempted."""
    pass


class InvalidSpecError(GitError):
    """Raised when a reference specification is invalid."""
    pass


class ConflictError(GitError):
    """Raised when there are conflicting changes."""
    pass


class LockedError(GitError):
    """Raised when a Git resource is locked."""
    pass


class ModifiedError(GitError):
    """Raised when there are uncommitted modifications."""
    pass


class AuthError(GitError):
    """Raised when authentication fails."""
    pass


class UncommittedError(GitError):
    """Raised when there are uncommitted changes."""
    pass


class NotARepoError(GitError):
    """Raised when a path is not a Git repository."""
    pass


# Mapping of error codes to their respective exception classes
ERROR_CLASSES: Dict[int, Type[GitError]] = {
    GitErrorCode.GIT_ENOTFOUND: NotFoundError,
    GitErrorCode.GIT_EEXISTS: ExistsError,
    GitErrorCode.GIT_EAMBIGUOUS: AmbiguousError,
    GitErrorCode.GIT_EBAREREPO: BareRepoError,
    GitErrorCode.GIT_EUNBORNBRANCH: UnbornBranchError,
    GitErrorCode.GIT_EUNMERGED: UnmergedError,
    GitErrorCode.GIT_ENONFASTFORWARD: NonFastForwardError,
    GitErrorCode.GIT_EINVALIDSPEC: InvalidSpecError,
    GitErrorCode.GIT_ECONFLICT: ConflictError,
    GitErrorCode.GIT_ELOCKED: LockedError,
    GitErrorCode.GIT_EMODIFIED: ModifiedError,
    GitErrorCode.GIT_EAUTH: AuthError,
    GitErrorCode.GIT_EUNCOMMITTED: UncommittedError,
    GitErrorCode.GIT_ENOTAREPO: NotARepoError,
}

# Human-readable error messages
ERROR_MESSAGES = {
    GitErrorCode.GIT_ERROR: "Generic error",
    GitErrorCode.GIT_ENOTFOUND: "Object not found",
    GitErrorCode.GIT_EEXISTS: "Object already exists",
    GitErrorCode.GIT_EAMBIGUOUS: "More than one object matches",
    GitErrorCode.GIT_EBUFS: "Output buffer too short",
    GitErrorCode.GIT_EUSER: "User-generated error",
    GitErrorCode.GIT_EBAREREPO: "Operation not allowed on bare repository",
    GitErrorCode.GIT_EUNBORNBRANCH: "HEAD refers to branch with no commits",
    GitErrorCode.GIT_EUNMERGED: "Unmerged entries exist",
    GitErrorCode.GIT_ENONFASTFORWARD: "Reference was not fast-forwardable",
    GitErrorCode.GIT_EINVALIDSPEC: "Invalid specification",
    GitErrorCode.GIT_ECONFLICT: "Conflict exists",
    GitErrorCode.GIT_ELOCKED: "Resource is locked",
    GitErrorCode.GIT_EMODIFIED: "Uncommitted changes exist",
    GitErrorCode.GIT_EAUTH: "Authentication error",
    GitErrorCode.GIT_ECERTIFICATE: "Server certificate is invalid",
    GitErrorCode.GIT_EAPPLIED: "Patch/merge has already been applied",
    GitErrorCode.GIT_EPEEL: "Cannot peel object",
    GitErrorCode.GIT_EEOF: "Unexpected EOF",
    GitErrorCode.GIT_EINVALID: "Invalid operation or input",
    GitErrorCode.GIT_EUNCOMMITTED: "Uncommitted changes exist",
    GitErrorCode.GIT_EDIRECTORY: "Directory exists",
    GitErrorCode.GIT_EMERGECONFLICT: "Merge conflict",
    GitErrorCode.GIT_PASSTHROUGH: "Passthrough error",
    GitErrorCode.GIT_ITEROVER: "Iteration is over",
    GitErrorCode.GIT_RETRY: "Operation needs to be retried",
    GitErrorCode.GIT_EMISMATCH: "Checksum mismatch",
    GitErrorCode.GIT_EINDEXDIRTY: "Index is dirty",
    GitErrorCode.GIT_EAPPLYFAIL: "Patch application failed",
    GitErrorCode.GIT_EOWNER: "Invalid owner",
    GitErrorCode.GIT_ENOTAREPO: "Not a Git repository",
    GitErrorCode.GIT_ENOTNAMESPACED: "Not a namespaced repository",
}


def check_error(error_code: int, message: Optional[str] = None) -> None:
    """
    Check a libgit2 return code and raise an appropriate exception if it's an error.

    Args:
        error_code: The error code returned by a libgit2 function
        message: Optional custom error message

    Raises:
        GitError: An appropriate subclass of GitError based on the error code
    """
    if error_code >= 0:
        return

    error_class = ERROR_CLASSES.get(error_code, GitError)
    error_message = message or ERROR_MESSAGES.get(error_code)
    raise error_class(error_code, error_message)
