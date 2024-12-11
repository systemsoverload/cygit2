from cpython.bytes cimport PyBytes_FromString
from libc.string cimport strlen
from libc.stdint cimport uint32_t
from libc.stdlib cimport malloc, free

from .errors import GitError
from ._commit cimport Commit
from ._signature cimport Signature
from ._reference cimport Reference
from ._index cimport Index
from ._oid cimport Oid, hex_to_oid
from ._tree cimport Tree

# Status constants
STATUS_CURRENT = 0
GIT_STATUS_INDEX_NEW = (1 << 0)
GIT_STATUS_INDEX_MODIFIED = (1 << 1)
GIT_STATUS_INDEX_DELETED = (1 << 2)
GIT_STATUS_INDEX_RENAMED = (1 << 3)
GIT_STATUS_INDEX_TYPECHANGE = (1 << 4)
GIT_STATUS_WT_NEW = (1 << 7)
GIT_STATUS_WT_MODIFIED = (1 << 8)
GIT_STATUS_WT_DELETED = (1 << 9)
GIT_STATUS_WT_TYPECHANGE = (1 << 10)
GIT_STATUS_WT_RENAMED = (1 << 11)
GIT_STATUS_IGNORED = (1 << 14)

def _status_to_str(unsigned int status):
    if status == STATUS_CURRENT:
        return "current"
    elif status & GIT_STATUS_INDEX_NEW:
        return "new"
    elif status & GIT_STATUS_INDEX_MODIFIED:
        return "modified"
    elif status & GIT_STATUS_INDEX_DELETED:
        return "deleted"
    elif status & GIT_STATUS_INDEX_RENAMED:
        return "renamed"
    elif status & GIT_STATUS_INDEX_TYPECHANGE:
        return "typechange"
    elif status & GIT_STATUS_WT_NEW:
        return "untracked"
    elif status & GIT_STATUS_WT_MODIFIED:
        return "modified"
    elif status & GIT_STATUS_WT_DELETED:
        return "deleted"
    elif status & GIT_STATUS_WT_TYPECHANGE:
        return "typechange"
    elif status & GIT_STATUS_WT_RENAMED:
        return "renamed"
    elif status & GIT_STATUS_IGNORED:
        return "ignored"
    return "unknown"

cdef class Repository:
    def __cinit__(self):
        self._repo = NULL
        self._path = None
        self._owned = True

    def __dealloc__(self):
        if self._owned and self._repo is not NULL:
            git_repository_free(self._repo)
            self._repo = NULL

    @staticmethod
    cdef Repository from_repo(git_repository *repo, bytes path):
        cdef Repository inst = Repository()
        inst._repo = repo
        inst._path = path
        return inst

    @staticmethod
    def init(path, bint bare=False):
        """Initialize a new Git repository at the given path."""
        cdef Repository repo = Repository()
        cdef bytes py_path = path.encode('utf-8')
        cdef int err

        err = git_repository_init(&repo._repo, py_path, 1 if bare else 0)
        if err < 0:
            raise GitError(err)

        repo._path = py_path
        return repo

    @staticmethod
    def open(path):
        """Open an existing Git repository at the given path."""
        cdef Repository repo = Repository()
        cdef bytes py_path = path.encode('utf-8')
        cdef int err

        err = git_repository_open(&repo._repo, py_path)
        if err < 0:
            raise GitError(err)

        repo._path = py_path
        return repo

    @staticmethod
    def clone(url, path, bare=False):
        """Clone a Git repository from url to path."""
        cdef Repository repo = Repository()
        cdef bytes py_url = url.encode('utf-8')
        cdef bytes py_path = path.encode('utf-8')
        cdef git_clone_options opts
        cdef int err

        err = git_clone_init_options(&opts, 1)
        if err < 0:
            raise GitError(err)

        opts.bare = 1 if bare else 0

        err = git_clone(&repo._repo, py_url, py_path, &opts)
        if err < 0:
            raise GitError(err)

        repo._path = py_path
        return repo

    cdef _check_error(self, int err):
        if err < 0:
            raise GitError(err)

    @property
    def path(self):
        """Path to the Git repository."""
        cdef const char* path = git_repository_path(self._repo)
        return PyBytes_FromString(path).decode('utf-8')

    @property
    def workdir(self):
        """Working directory path of the repository."""
        cdef const char* path = git_repository_workdir(self._repo)
        if path == NULL:
            return None
        return PyBytes_FromString(path).decode('utf-8')

    @property
    def is_bare(self):
        """Check if this is a bare repository."""
        return bool(git_repository_is_bare(self._repo))

    @property
    def is_empty(self):
        """Check if the repository is empty."""
        return bool(git_repository_is_empty(self._repo))

    @property
    def head(self):
        """Get the HEAD reference of the repository."""
        cdef git_reference *ref = NULL
        cdef int err

        err = git_repository_head(&ref, self._repo)
        if err < 0:
            if err == -3:  # No HEAD exists
                return None
            raise GitError(err)

        return Reference._from_c(ref, self)

    def create_commit(self, const char *ref, Signature author,
                     Signature committer, const char *message,
                     Tree tree, list parents):
        """Create a new commit object."""
        cdef git_oid oid
        cdef const git_commit **parent_commits = NULL
        cdef size_t parent_count = len(parents)
        cdef int err

        if parent_count > 0:
            parent_commits = <const git_commit **>malloc(parent_count * sizeof(git_commit *))
            for i in range(parent_count):
                parent_commits[i] = (<Commit>parents[i])._commit

        try:
            err = git_commit_create(
                &oid, self._repo, ref, author._sig, committer._sig,
                "UTF-8", message, tree._tree, parent_count, parent_commits
            )
            self._check_error(err)
        finally:
            if parent_commits != NULL:
                free(parent_commits)

        return Oid._from_c(&oid)

    def lookup_commit(self, oid):
        """Look up a commit object by its OID."""
        cdef git_commit *commit = NULL
        cdef git_oid c_oid
        cdef int err

        hex_to_oid(oid, &c_oid)
        err = git_commit_lookup(&commit, self._repo, &c_oid)
        if err < 0:
            raise GitError(err)

        return Commit._from_c(commit, self)

    def create_reference(self, const char *name, Oid oid, bint force=False):
        """Create a new reference with the specified name pointing to the given OID."""
        cdef git_reference *ref = NULL
        cdef int err

        err = git_reference_create(&ref, self._repo, name, &oid._oid, force, NULL, NULL)
        if err < 0:
            raise GitError(err)

        return Reference._from_c(ref, self)

    @property
    def index(self):
        """Get the repository index."""
        cdef git_index *index = NULL
        cdef int err

        err = git_repository_index(&index, self._repo)
        if err < 0:
            raise GitError(err)

        return Index._from_c(index, self)

    def set_head(self, const char *refname):
        """Set HEAD to point to the specified reference."""
        cdef int err

        err = git_repository_set_head(self._repo, refname)
        if err < 0:
            raise GitError(err)

    def status(self):
        """Get the working directory status."""
        cdef git_status_list *status_list = NULL
        cdef git_status_options opts
        cdef const git_status_entry *entry
        cdef const char *path_ptr = NULL
        cdef int err
        cdef dict result = {}
        cdef size_t i, count

        err = git_status_init_options(&opts, GIT_STATUS_OPTIONS_VERSION)
        if err < 0:
            raise GitError(err)

        err = git_status_list_new(&status_list, self._repo, &opts)
        if err < 0:
            raise GitError(err)

        try:
            count = git_status_list_entrycount(status_list)
            for i in range(count):
                entry = git_status_byindex(status_list, i)
                if entry == NULL:
                    continue

                # First check head_to_index path
                path_ptr = entry.head_to_index.new_file.path
                if path_ptr == NULL:
                    # If not found, try index_to_workdir path
                    path_ptr = entry.index_to_workdir.new_file.path
                    if path_ptr == NULL:
                        continue

                # At this point path_ptr is guaranteed to be non-NULL
                result[path_ptr.decode('utf-8')] = _status_to_str(entry.status)

            return result
        finally:
            if status_list != NULL:
                git_status_list_free(status_list)

    def create_branch(self, const char *name, Commit target, bint force=False):
        """Create a new branch with the specified name pointing to the target commit."""
        cdef git_reference *ref = NULL
        cdef int err

        err = git_branch_create(&ref, self._repo, name, target._commit, force)
        if err < 0:
            raise GitError(err)

        return Reference._from_c(ref, self)

    def lookup_branch(self, const char *name, int branch_type=GIT_BRANCH_LOCAL):
        """Look up a branch by name."""
        cdef git_reference *ref = NULL
        cdef int err

        err = git_branch_lookup(&ref, self._repo, name, branch_type)
        if err < 0:
            raise GitError(err)

        return Reference._from_c(ref, self)

    def default_signature(self):
        """Get the default signature for the repository."""
        cdef git_signature *sig = NULL
        cdef int err

        err = git_signature_default(&sig, self._repo)
        if err < 0:
            raise GitError(err)

        try:
            # Create a new Signature object and transfer ownership
            result = Signature._from_c(sig)
            return result
        finally:
            if sig != NULL:
                git_signature_free(sig)
