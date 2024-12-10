from libc.stdint cimport uint32_t
from ._oid cimport git_oid, Oid
from ._repository cimport Repository

cdef extern from "git2.h":
    ctypedef struct git_index:
        pass

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
    cdef:
        git_index* _index
        Repository _repo

    @staticmethod
    cdef Index _from_c(git_index* index, Repository repo)

    cdef _entry_to_dict(self, const git_index_entry *entry)
