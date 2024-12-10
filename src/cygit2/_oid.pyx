from libc.string cimport const_char
from cpython.bytes cimport PyBytes_FromStringAndSize
from .errors import GitError

cdef extern from "git2.h":
    int git_oid_fromstr(git_oid *out, const char *str)
    char *git_oid_tostr_s(const git_oid *oid)
    void git_oid_fmt(char *str, const git_oid *oid)
    int git_oid_equal(const git_oid *a, const git_oid *b)
    int git_oid_cmp(const git_oid *a, const git_oid *b)
    void git_oid_cpy(git_oid *dst, const git_oid *src)

cdef class Oid:
    """Represents a Git object ID (SHA-1 hash)."""

    def __cinit__(self, const_char *hex=NULL):
        """Initialize an Oid, optionally from a hex string."""
        if hex != NULL:
            err = git_oid_fromstr(&self._oid, hex)
            if err < 0:
                raise GitError(err)

    @staticmethod
    cdef Oid _from_c(const git_oid *oid):
        """Create an Oid object from a C git_oid pointer."""
        cdef Oid obj = Oid()
        git_oid_cpy(&obj._oid, oid)
        return obj

    def __str__(self):
        """Convert the OID to its hex string representation."""
        # Create a buffer for the hex string (40 chars + null terminator)
        cdef char hex[41]
        git_oid_fmt(hex, &self._oid)
        hex[40] = 0  # Null terminate
        return hex.decode('ascii')

    def __repr__(self):
        return f"Oid('{str(self)}')"

    def __richcmp__(Oid self, Oid other, int op):
        """Implement rich comparison operations."""
        if not isinstance(other, Oid):
            return NotImplemented

        cdef int cmp = git_oid_cmp(&self._oid, &other._oid)
        if op == 0:   # <
            return cmp < 0
        elif op == 1: # <=
            return cmp <= 0
        elif op == 2: # ==
            return cmp == 0
        elif op == 3: # !=
            return cmp != 0
        elif op == 4: # >
            return cmp > 0
        elif op == 5: # >=
            return cmp >= 0

    def __hash__(self):
        """Make Oid hashable for use in sets and as dict keys."""
        return hash(str(self))

    @property
    def hex(self):
        """Get the hex string representation of the OID."""
        return str(self)

    def __copy__(self):
        """Implement copy support."""
        cdef Oid new_oid = Oid()
        git_oid_cpy(&new_oid._oid, &self._oid)
        return new_oid

    def __deepcopy__(self, memo):
        """Implement deepcopy support (same as copy for immutable type)."""
        return self.__copy__()

# Helper functions
cdef void hex_to_oid(const_char *hex, git_oid *oid) except *:
    """Convert a hex string to a git_oid, raising GitError on failure."""
    cdef int err
    err = git_oid_fromstr(oid, hex)
    if err < 0:
        raise GitError(err)

def is_valid_oid_string(str hex_str):
    """Check if a string is a valid OID (SHA-1 hash)."""
    cdef git_oid temp
    try:
        hex_to_oid(hex_str.encode('ascii'), &temp)
        return True
    except (GitError, UnicodeEncodeError):
        return False
