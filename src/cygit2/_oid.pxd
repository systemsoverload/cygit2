from libc.string cimport const_char

cdef extern from "git2.h":
    ctypedef struct git_oid:
        unsigned char id[20]

    int git_oid_fromstr(git_oid *out, const char *str)
    char *git_oid_tostr_s(const git_oid *oid)
    void git_oid_fmt(char *str, const git_oid *oid)
    int git_oid_equal(const git_oid *a, const git_oid *b)
    int git_oid_cmp(const git_oid *a, const git_oid *b)
    void git_oid_cpy(git_oid *dst, const git_oid *src)
    const char *git_oid_tostr_s(const git_oid *oid)

cdef class Oid:
    cdef:
        git_oid _oid

    @staticmethod
    cdef Oid _from_c(const git_oid *oid)

cdef void hex_to_oid(const_char *hex, git_oid *oid) except *
