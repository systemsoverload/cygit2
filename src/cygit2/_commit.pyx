from cpython.ref cimport PyObject
from libc.stdint cimport int64_t
from datetime import datetime, timedelta, timezone
from .errors import GitError
from ._oid cimport Oid

cdef class Commit:
    """Represents a Git commit object."""

    def __cinit__(self):
        """Initialize the commit object."""
        self._commit = NULL
        self._repo = None

    def __dealloc__(self):
        """Free the underlying git_commit."""
        if self._commit != NULL:
            git_commit_free(self._commit)

    @staticmethod
    cdef Commit _from_c(git_commit *commit, Repository repo):
        """Create a Commit object from a C git_commit pointer."""
        cdef Commit obj = Commit()
        obj._commit = commit
        obj._repo = repo
        return obj

    @property
    def id(self):
        """Get the OID (SHA-1) of the commit."""
        cdef const git_oid *oid = git_commit_id(self._commit)
        return Oid._from_c(oid)

    @property
    def message(self):
        """Get the commit message."""
        cdef const char *msg = git_commit_message(self._commit)
        if msg == NULL:
            return None
        encoding = self.message_encoding or 'utf-8'
        return msg.decode(encoding)

    @property
    def message_encoding(self):
        """Get the encoding of the commit message."""
        cdef const char *encoding = git_commit_message_encoding(self._commit)
        if encoding == NULL:
            return None
        return encoding.decode('utf-8')

    @property
    def summary(self):
        """Get the summary (first line) of the commit message."""
        cdef const char *summary = git_commit_summary(self._commit)
        if summary == NULL:
            return None
        encoding = self.message_encoding or 'utf-8'
        return summary.decode(encoding)

    @property
    def author(self):
        """Get the author of the commit."""
        cdef const git_signature *sig = git_commit_author(self._commit)
        if sig == NULL:
            return None
        return Signature._from_c(sig)

    @property
    def committer(self):
        """Get the committer of the commit."""
        cdef const git_signature *sig = git_commit_committer(self._commit)
        if sig == NULL:
            return None
        return Signature._from_c(sig)

    def get_time(self):
        """Get the commit time as a datetime object."""
        cdef int64_t time = git_commit_time(self._commit)
        cdef int offset = git_commit_time_offset(self._commit)

        tz = timezone(timedelta(minutes=offset))
        return datetime.fromtimestamp(time, tz)

    @property
    def parent_count(self):
        """Get the number of parent commits."""
        return git_commit_parentcount(self._commit)

    def get_parent(self, unsigned int n):
        """Get the nth parent of the commit."""
        if n >= self.parent_count:
            raise IndexError(f"Parent index {n} out of range")

        cdef git_commit *parent = NULL
        cdef int err = git_commit_parent(&parent, self._commit, n)

        if err < 0:
            raise GitError(err)

        return Commit._from_c(parent, self._repo)

    def get_parent_id(self, unsigned int n):
        """Get the OID of the nth parent."""
        if n >= self.parent_count:
            raise IndexError(f"Parent index {n} out of range")

        cdef const git_oid *oid = git_commit_parent_id(self._commit, n)
        if oid == NULL:
            raise GitError(-1)  # Generic error

        return Oid._from_c(oid)

    @property
    def parents(self):
        """Get a list of all parent commits."""
        return [self.get_parent(i) for i in range(self.parent_count)]

    @property
    def parent_ids(self):
        """Get a list of all parent commit OIDs."""
        return [self.get_parent_id(i) for i in range(self.parent_count)]

    def __str__(self):
        return f"{str(self.id)} {self.summary}"

    def __repr__(self):
        return f'<Commit {str(self.id)}>'

    @property
    def tree_id(self):
        """Get the OID of the tree referenced by this commit."""
        cdef const git_oid *oid = git_commit_tree_id(self._commit)
        return Oid._from_c(oid)

    def get_tree(self):
        """Get the tree referenced by this commit."""
        from ._tree import Tree  # Import here to avoid circular imports

        cdef git_tree *tree = NULL
        cdef int err = git_commit_tree(&tree, self._commit)

        if err < 0:
            raise GitError(err)

        return Tree._from_c(tree, self._repo)
