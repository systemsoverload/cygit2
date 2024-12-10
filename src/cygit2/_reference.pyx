# distutils: language = c++

from libcpp.string cimport string
from libcpp.vector cimport vector
from cython.operator cimport dereference as deref

# Import the declarations from .pxd
from _reference cimport Reference

# Python wrapper class
cdef class PyReference:
    # Hold the C++ instance that we're wrapping
    cdef Reference* _ref

    def __cinit__(self):
        self._ref = new Reference()

    def __dealloc__(self):
        if self._ref != NULL:
            del self._ref

    @property
    def is_valid(self):
        return self._ref.isValid()

    @property
    def type(self):
        return self._ref.getType().decode('utf-8')

    @type.setter
    def type(self, str value):
        self._ref.setType(value.encode('utf-8'))

    @property
    def text(self):
        return self._ref.getText().decode('utf-8')

    @text.setter
    def text(self, str value):
        self._ref.setText(value.encode('utf-8'))

    def parse(self, str input_text):
        """Parse a reference from input text."""
        return self._ref.parse(input_text.encode('utf-8'))

    def format(self):
        """Format the reference as a string."""
        return self._ref.format().decode('utf-8')

    def add_attribute(self, str key, str value):
        """Add an attribute to the reference."""
        self._ref.addAttribute(key.encode('utf-8'), value.encode('utf-8'))

    def get_attribute(self, str key):
        """Get an attribute value by key."""
        return self._ref.getAttribute(key.encode('utf-8')).decode('utf-8')

    def get_attribute_keys(self):
        """Get all attribute keys."""
        cdef vector[string] keys = self._ref.getAttributeKeys()
        return [key.decode('utf-8') for key in keys]

    def __str__(self):
        return self.format()

    def __repr__(self):
        return f"<Reference type='{self.type}' text='{self.text}'>"
