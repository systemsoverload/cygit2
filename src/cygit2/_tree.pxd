from libc.stdint cimport uint32_t
from ._oid cimport git_oid, Oid
from ._repository cimport Repository

cdef extern from "git2.h":
    ctypedef struct git_tree:
        pass

    ctypedef struct git_tree_entry:
        uint32_t attr
        const char *filename
        git_oid id

    ctypedef enum git_filemode_t:
        GIT_FILEMODE_UNREADABLE
        GIT_FILEMODE_TREE
        GIT_FILEMODE_BLOB
        GIT_FILEMODE_BLOB_EXECUTABLE
        GIT_FILEMODE_LINK
        GIT_FILEMODE_COMMIT

    const git_tree_entry* git_tree_entry_byindex(const git_tree *tree, size_t idx)
    const git_tree_entry* git_tree_entry_byname(const git_tree *tree, const char *filename)
    void git_tree_entry_free(git_tree_entry *entry)
    const char* git_tree_entry_name(const git_tree_entry *entry)
    const git_oid* git_tree_entry_id(const git_tree_entry *entry)
    git_filemode_t git_tree_entry_filemode(const git_tree_entry *entry)
    git_filemode_t git_tree_entry_filemode_raw(const git_tree_entry *entry)
    size_t git_tree_entrycount(const git_tree *tree)
    void git_tree_free(git_tree *tree)

cdef class Tree:
    cdef:
        git_tree* _tree
        Repository _repo
        object __weakref__  # Enable weak references

    @staticmethod
    cdef Tree _from_c(git_tree *tree, Repository repo)

    cdef dict _entry_to_dict(self, const git_tree_entry *entry)
