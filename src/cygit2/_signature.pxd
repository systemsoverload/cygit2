from libc.time cimport time_t
from ._repository cimport git_repository

cdef extern from "git2.h":
    ctypedef struct git_repository

    ctypedef struct git_time:
        time_t time
        int offset
        char sign

    ctypedef time_t git_time_t

    ctypedef struct git_signature:
        char *name
        char *email
        git_time when

    int git_signature_new(git_signature **out, const char *name,
                         const char *email, git_time_t time, int offset)
    int git_signature_default(git_signature **out, git_repository *repo)
    void git_signature_free(git_signature *sig)

cdef class Signature:
    cdef:
        git_signature* _sig
        bint _owned

    @staticmethod
    cdef Signature _from_c(const git_signature *sig)

    cdef _set_from_c(self, const git_signature *sig)
