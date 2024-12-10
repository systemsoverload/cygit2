from libc.stdint cimport uint32_t, int32_t, int64_t
from libc.stdlib cimport malloc, free
from cpython cimport PyObject
from cpython.bytes cimport PyBytes_FromString
from ._reference cimport Reference
from ._index cimport Index
from ._commit cimport Commit

cdef extern from "git2.h":
    # Forward declarations of all git types
    ctypedef struct git_repository
    ctypedef struct git_object
    ctypedef struct git_commit
    ctypedef struct git_tree
    ctypedef struct git_tag
    ctypedef struct git_blob
    ctypedef struct git_reference
    ctypedef struct git_index
    ctypedef struct git_diff_file
    ctypedef struct git_diff_delta
    ctypedef struct git_status_entry
    ctypedef struct git_status_options
    ctypedef struct git_status_list
    ctypedef struct git_clone_options

    # Time related structures
    ctypedef struct git_time:
        int64_t time
        int32_t offset

    ctypedef struct git_signature:
        char* name
        char* email
        git_time when

    # Status related structures
    ctypedef struct git_diff_file:
        const char *path
        size_t size
        unsigned int flags
        unsigned short mode
        unsigned char id[20]

    ctypedef struct git_diff_delta:
        git_diff_file old_file
        git_diff_file new_file
        unsigned int status
        unsigned int similarity
        unsigned int flags

    ctypedef struct git_status_entry:
        git_diff_delta head_to_index
        git_diff_delta index_to_workdir
        unsigned int status

    ctypedef struct git_status_options:
        unsigned int version
        unsigned int show
        unsigned int flags

    # Constants
    cdef int GIT_STATUS_OPTIONS_VERSION
    cdef int GIT_BRANCH_LOCAL
    cdef int GIT_BRANCH_REMOTE

    # Repository functions
    int git_repository_init(git_repository **out, const char *path, uint32_t is_bare)
    int git_repository_open(git_repository **out, const char *path)
    void git_repository_free(git_repository *repo)
    const char * git_repository_path(git_repository *repo)
    const char * git_repository_workdir(git_repository *repo)
    int git_repository_is_bare(git_repository *repo)
    int git_repository_is_empty(git_repository *repo)
    int git_repository_head(git_reference **out, git_repository *repo)
    int git_repository_index(git_index **out, git_repository *repo)
    int git_repository_set_head(git_repository *repo, const char *refname)

    # Status functions
    int git_status_init_options(git_status_options *opts, unsigned int version)
    int git_status_list_new(git_status_list **out, git_repository *repo, const git_status_options *opts)
    size_t git_status_list_entrycount(git_status_list *statuslist)
    const git_status_entry* git_status_byindex(git_status_list *statuslist, size_t idx)
    void git_status_list_free(git_status_list *statuslist)

    # Branch functions
    int git_branch_create(git_reference **out, git_repository *repo, const char *branch_name, const git_commit *target, int force)
    int git_branch_lookup(git_reference **out, git_repository *repo, const char *branch_name, int branch_type)

    # Clone functions
    ctypedef struct git_clone_options:
        unsigned int version
        int bare

    int git_clone(git_repository **out, const char *url, const char *local_path, const git_clone_options *options)
    int git_clone_init_options(git_clone_options *opts, unsigned int version)

# Python wrapper class
cdef class Repository:
    cdef:
        git_repository *_repo
        bytes _path
        bint _owned

    @staticmethod
    cdef Repository from_repo(git_repository *repo, bytes path)

    cdef _check_error(self, int err)
