from libc.string cimport const_char
from libc.stdint cimport uint32_t
from cpython.bytes cimport PyBytes_FromStringAndSize
from .errors import GitError
from ._oid cimport Oid

cdef extern from "git2.h":
    ctypedef struct git_index_entry:
        git_oid id
        const char *path
        uint32_t mode
        uint32_t flags

    int git_index_add(git_index *index, const git_index_entry *entry)
    int git_index_add_bypath(git_index *index, const char *path)
    int git_index_remove(git_index *index, const char *path, int stage)
    int git_index_remove_bypath(git_index *index, const char *path)
    int git_index_write(git_index *index)
    int git_index_read(git_index *index, int force)
    int git_index_clear(git_index *index)
    size_t git_index_entrycount(const git_index *index)
    const git_index_entry *git_index_get_byindex(git_index *index, size_t n)
    const git_index_entry *git_index_get_bypath(git_index *index, const char *path, int stage)
    int git_index_find(size_t *at_pos, git_index *index, const char *path)
    void git_index_free(git_index *index)
    int git_index_write_tree(git_oid *out, git_index *index)

cdef class Index:
    """Represents a Git index (staging area)."""

    def __cinit__(self):
        """Initialize Index object."""
        self._index = NULL
        self._repo = None

    def __dealloc__(self):
        """Free the underlying git_index."""
        if self._index != NULL:
            git_index_free(self._index)

    @staticmethod
    cdef Index _from_c(git_index *index, Repository repo):
        """Create an Index object from a C git_index pointer."""
        cdef Index obj = Index()
        obj._index = index
        obj._repo = repo
        return obj

    def add(self, str path):
        """Add a file to the index by path."""
        cdef int err
        cdef bytes py_path = path.encode('utf-8')

        err = git_index_add_bypath(self._index, py_path)
        if err < 0:
            raise GitError(err)

    def remove(self, str path):
        """Remove a file from the index."""
        cdef int err
        cdef bytes py_path = path.encode('utf-8')

        err = git_index_remove_bypath(self._index, py_path)
        if err < 0:
            raise GitError(err)

    def clear(self):
        """Clear the index."""
        cdef int err = git_index_clear(self._index)
        if err < 0:
            raise GitError(err)

    def write(self):
        """Write the index to disk."""
        cdef int err = git_index_write(self._index)
        if err < 0:
            raise GitError(err)

    def read(self, bint force=False):
        """Read the index from disk."""
        cdef int err = git_index_read(self._index, force)
        if err < 0:
            raise GitError(err)

    def write_tree(self):
        """Write the index content as a tree."""
        cdef git_oid tree_oid
        cdef int err

        err = git_index_write_tree(&tree_oid, self._index)
        if err < 0:
            raise GitError(err)

        return Oid._from_c(&tree_oid)

    @property
    def entry_count(self):
        """Get the number of entries in the index."""
        return git_index_entrycount(self._index)

    def get_entry(self, size_t n):
        """Get an entry by its index."""
        cdef const git_index_entry *entry = git_index_get_byindex(self._index, n)
        if entry == NULL:
            raise IndexError("Index entry not found")

        return self._entry_to_dict(entry)

    def get_entry_by_path(self, str path, int stage=0):
        """Get an entry by its path."""
        cdef const git_index_entry *entry
        cdef bytes py_path = path.encode('utf-8')

        entry = git_index_get_bypath(self._index, py_path, stage)
        if entry == NULL:
            raise KeyError(f"No entry found for path: {path}")

        return self._entry_to_dict(entry)

    def find(self, str path):
        """Find the position of an entry in the index."""
        cdef size_t pos
        cdef int err
        cdef bytes py_path = path.encode('utf-8')

        err = git_index_find(&pos, self._index, py_path)
        if err < 0:
            raise GitError(err)

        return pos

    def __len__(self):
        """Get the number of entries in the index."""
        return self.entry_count

    def __iter__(self):
        """Iterate over all entries in the index."""
        for i in range(self.entry_count):
            yield self.get_entry(i)

    def __getitem__(self, key):
        """Get an entry by index or path."""
        if isinstance(key, int):
            return self.get_entry(key)
        elif isinstance(key, str):
            return self.get_entry_by_path(key)
        else:
            raise TypeError("Index key must be integer or string")

    cdef _entry_to_dict(self, const git_index_entry *entry):
        """Convert a git_index_entry to a Python dictionary."""
        return {
            'path': entry.path.decode('utf-8'),
            'id': Oid._from_c(&entry.id),
            'mode': entry.mode,
            'flags': entry.flags
        }

    @property
    def repository(self):
        """Get the repository that owns this index."""
        return self._repo
