from libc.stdint cimport int32_t, int64_t, uint32_t
from libc.string cimport const_char

cdef extern from "git2.h":
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
        const git_commit **parents
    )

    int git_commit_lookup(git_commit **commit, git_repository *repo, const git_oid *id)
    int git_reference_create(
        git_reference **out,
        git_repository *repo,
        const char *name,
        const git_oid *id,
        int force,
        const git_signature *signature,
        const char *log_message
    )
    int git_signature_default(git_signature **out, git_repository *repo)
    void git_signature_free(git_signature *sig)
    const git_oid *git_commit_id(const git_commit *commit)
    const char *git_commit_message_encoding(const git_commit *commit)
    const char *git_commit_summary(const git_commit *commit)
    int64_t git_commit_time(const git_commit *commit)
    int git_commit_time_offset(const git_commit *commit)
    unsigned int git_commit_parentcount(const git_commit *commit)
    int git_commit_parent(git_commit **out, const git_commit *commit, unsigned int n)
    const git_oid *git_commit_parent_id(const git_commit *commit, unsigned int n)
    const git_oid *git_commit_tree_id(const git_commit *commit)
    int git_commit_tree(git_tree **tree_out, const git_commit *commit)

    ctypedef struct git_repository:
        pass

    ctypedef struct git_commit:
        pass

    ctypedef struct git_tree:
        pass

    ctypedef struct git_tag:
        pass

    ctypedef struct git_blob:
        pass

    ctypedef struct git_index:
        pass

    ctypedef struct git_reference:
        pass

    ctypedef struct git_object:
        pass

    ctypedef struct git_signature:
        char* name
        char* email
        git_time when

    ctypedef struct git_time:
        int64_t time
        int32_t offset

    ctypedef struct git_oid:
        unsigned char[20] id

    ctypedef enum git_repository_init_flag_t:
        GIT_REPOSITORY_INIT_BARE
        GIT_REPOSITORY_INIT_NO_REINIT
        GIT_REPOSITORY_INIT_NO_DOTGIT_DIR
        GIT_REPOSITORY_INIT_MKDIR
        GIT_REPOSITORY_INIT_MKPATH
        GIT_REPOSITORY_INIT_EXTERNAL_TEMPLATE

    int git_libgit2_init()
    int git_libgit2_shutdown()
