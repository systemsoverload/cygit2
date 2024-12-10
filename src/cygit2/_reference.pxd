from libcpp cimport bool
from libcpp.string cimport string
from libcpp.vector cimport vector

from ._repository cimport Repository

cdef extern from "git2.h":
    ctypedef struct git_reference:
        pass

    int git_reference_name(const git_reference *ref)
    void git_reference_free(git_reference *ref)
    # Add other git_reference related declarations

cdef extern from "reference.h" namespace "reference":
    cdef cppclass CppReference "reference::Reference":
        CppReference() except +

        # State accessors
        bint isValid() const
        string getType() const
        string getText() const

        # Modification methods
        void setText(const string& text)
        void setType(const string& type)

        # Container operations
        void addAttribute(const string& key, const string& value)
        string getAttribute(const string& key) const
        vector[string] getAttributeKeys() const

cdef class Reference:
    cdef:
        git_reference* _ref
        Repository _repo

    @staticmethod
    cdef Reference _from_c(git_reference* ref, Repository repo)
