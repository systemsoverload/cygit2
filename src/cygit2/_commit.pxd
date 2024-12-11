from libc.stdint cimport int64_t
from ._oid cimport git_oid, Oid
from ._repository cimport Repository
from ._signature cimport git_signature, Signature
from ._tree cimport Tree

cdef extern from "git2.h":
    ctypedef struct git_repository:
        pass

    ctypedef struct git_tree:
        pass

    ctypedef struct git_commit:
        pass

     # Basic commit functions
    int git_commit_lookup(git_commit **commit, git_repository *repo, const git_oid *id)
    void git_commit_free(git_commit *commit)

    # Commit data accessors
    const git_signature *git_commit_author(const git_commit *commit)
    const git_signature *git_commit_committer(const git_commit *commit)
    const char *git_commit_message(const git_commit *commit)
    const char *git_commit_message_encoding(const git_commit *commit)
    const char *git_commit_summary(const git_commit *commit)
    const git_oid *git_commit_id(const git_commit *commit)

    # Time-related functions
    int64_t git_commit_time(const git_commit *commit)
    int git_commit_time_offset(const git_commit *commit)

    # Parent-related functions
    unsigned int git_commit_parentcount(const git_commit *commit)
    int git_commit_parent(git_commit **out, const git_commit *commit, unsigned int n)
    const git_oid *git_commit_parent_id(const git_commit *commit, unsigned int n)

    # Tree-related functions
    int git_commit_tree(git_tree **tree_out, const git_commit *commit)
    const git_oid *git_commit_tree_id(const git_commit *commit)

    int git_commit_create(
        git_oid *id,
        git_repository *repo,
        const char *update_ref,
        const git_signature *author,
        const git_signature *committer,
        const char *message_encoding,
        const char *message,
        const git_tree *tree,
        size_t parent_count,
        const git_commit **parents)

cdef class Commit:
    cdef:
        git_commit* _commit
        Repository _repo
        object __weakref__  # Enable weak references

    @staticmethod
    cdef Commit _from_c(git_commit *commit, Repository repo)
