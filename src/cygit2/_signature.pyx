from cpython.ref cimport PyObject
from libc.stdlib cimport malloc, free
from libc.string cimport strcpy, strlen
from datetime import datetime, timezone, timedelta
from .errors import GitError

cdef class Signature:
    """Represents a Git signature (author or committer)."""

    def __cinit__(self):
        """Initialize a new signature object."""
        self._sig = NULL
        self._owned = True

    def __dealloc__(self):
        """Clean up the signature object."""
        if self._owned and self._sig != NULL:
            git_signature_free(self._sig)
            self._sig = NULL

    @staticmethod
    cdef Signature _from_c(const git_signature *sig):
        """Create a new Signature object from a git_signature pointer."""
        if sig == NULL:
            return None

        cdef Signature obj = Signature.__new__(Signature)
        cdef git_signature *new_sig = NULL
        cdef int err

        # Create a new signature with the same values
        err = git_signature_new(
            &new_sig,
            sig.name,
            sig.email,
            sig.when.time,
            sig.when.offset
        )

        if err < 0:
            raise GitError(err)

        obj._sig = new_sig
        obj._owned = True
        return obj

    @classmethod
    def new(cls, str name, str email, time=None, int offset=0):
        """Create a new signature with the given name and email."""
        cdef Signature sig = cls()
        cdef git_signature *new_sig = NULL
        cdef bytes name_bytes = name.encode('utf-8')
        cdef bytes email_bytes = email.encode('utf-8')
        cdef int err

        if time is None:
            time = datetime.now(timezone.utc)

        if isinstance(time, datetime):
            timestamp = int(time.timestamp())
            if time.tzinfo is not None:
                offset = int(time.utcoffset().total_seconds() / 60)
        else:
            timestamp = int(time)

        err = git_signature_new(
            &new_sig,
            name_bytes,
            email_bytes,
            timestamp,
            offset
        )

        if err < 0:
            raise GitError(err)

        sig._sig = new_sig
        sig._owned = True
        return sig

    @property
    def name(self):
        """Get the name from the signature."""
        if self._sig == NULL or self._sig.name == NULL:
            return None
        return self._sig.name.decode('utf-8')

    @property
    def email(self):
        """Get the email from the signature."""
        if self._sig == NULL or self._sig.email == NULL:
            return None
        return self._sig.email.decode('utf-8')

    def get_time(self):
        """Get the time as a datetime object."""
        if self._sig == NULL:
            return None

        timestamp = self._sig.when.time
        offset_minutes = self._sig.when.offset
        tz = timezone(timedelta(minutes=offset_minutes))
        return datetime.fromtimestamp(timestamp, tz)

    @property
    def time(self):
        """Get the timestamp."""
        if self._sig == NULL:
            return None
        return self._sig.when.time

    @property
    def offset(self):
        """Get the timezone offset in minutes."""
        if self._sig == NULL:
            return None
        return self._sig.when.offset

    def __str__(self):
        if self._sig == NULL:
            return "Invalid Signature"
        return f"{self.name} <{self.email}>"

    def __repr__(self):
        if self._sig == NULL:
            return "Signature(invalid)"
        time_str = self.get_time().isoformat()
        return f'Signature("{self.name}", "{self.email}", "{time_str}")'
