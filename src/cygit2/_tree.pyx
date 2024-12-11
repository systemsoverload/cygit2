from cpython.ref cimport PyObject
from libc.stdint cimport uint32_t
from .errors import GitError
from ._oid cimport Oid

cdef class Tree:
    """Represents a Git tree object."""

    def __cinit__(self):
        """Initialize the tree object."""
        self._tree = NULL
        self._repo = None

    def __dealloc__(self):
        """Free the underlying git_tree."""
        if self._tree != NULL:
            git_tree_free(self._tree)

    @staticmethod
    cdef Tree _from_c(git_tree *tree, Repository repo):
        """Create a Tree object from a C git_tree pointer."""
        cdef Tree obj = Tree()
        obj._tree = tree
        obj._repo = repo
        return obj

    cdef dict _entry_to_dict(self, const git_tree_entry *entry):
        """Convert a git_tree_entry to a Python dictionary."""
        if entry == NULL:
            return None

        return {
            'name': git_tree_entry_name(entry).decode('utf-8'),
            'id': Oid._from_c(git_tree_entry_id(entry)),
            'filemode': git_tree_entry_filemode(entry),
            'type': self._filemode_to_type(git_tree_entry_filemode(entry))
        }

    def _filemode_to_type(self, git_filemode_t mode):
        """Convert a git filemode to a string type."""
        if mode == GIT_FILEMODE_TREE:
            return 'tree'
        elif mode == GIT_FILEMODE_BLOB:
            return 'blob'
        elif mode == GIT_FILEMODE_BLOB_EXECUTABLE:
            return 'blob_executable'
        elif mode == GIT_FILEMODE_LINK:
            return 'link'
        elif mode == GIT_FILEMODE_COMMIT:
            return 'commit'
        else:
            return 'unknown'

    def __len__(self):
        """Get the number of entries in the tree."""
        return git_tree_entrycount(self._tree)

    def __getitem__(self, key):
        """Get a tree entry by index or name."""
        cdef const git_tree_entry *entry

        if isinstance(key, int):
            if key < 0 or key >= len(self):
                raise IndexError("Tree entry index out of range")
            entry = git_tree_entry_byindex(self._tree, key)
        elif isinstance(key, str):
            entry = git_tree_entry_byname(self._tree, key.encode('utf-8'))
        else:
            raise TypeError("Index must be an integer or string")

        if entry == NULL:
            raise KeyError(f"No such entry: {key}")

        return self._entry_to_dict(entry)

    def __iter__(self):
        """Iterate over all entries in the tree."""
        for i in range(len(self)):
            yield self[i]

    @property
    def entries(self):
        """Get a list of all entries in the tree."""
        return list(self)

    def get_entry_by_path(self, str path):
        """Get a tree entry by its path."""
        cdef const git_tree_entry *entry

        entry = git_tree_entry_byname(self._tree, path.encode('utf-8'))
        if entry == NULL:
            raise KeyError(f"No entry found at path: {path}")

        return self._entry_to_dict(entry)

    @property
    def repository(self):
        """Get the repository that owns this tree."""
        return self._repo

    def __str__(self):
        return f"Tree(entries={len(self)})"

    def __repr__(self):
        return f"<Tree at {hex(id(self))} with {len(self)} entries>"

    def lookup(self, str path):
        """Look up an entry by path, returning its data."""
        try:
            entry = self.get_entry_by_path(path)
            if entry['type'] == 'blob':
                # Get the blob data if it's a file
                return self._repo.lookup_blob(entry['id']).data
            else:
                # Return the entry info for other types
                return entry
        except KeyError:
            raise KeyError(f"Path not found: {path}")
