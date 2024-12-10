cmake_minimum_required(VERSION 3.18)
project(cygit2)

# Find Python and add the include directories
find_package(Python COMPONENTS Interpreter Development REQUIRED)
include_directories(${Python_INCLUDE_DIRS})

# Find libgit2
find_package(PkgConfig REQUIRED)
pkg_check_modules(LIBGIT2 REQUIRED libgit2)
include_directories(${LIBGIT2_INCLUDE_DIRS})
link_directories(${LIBGIT2_LIBRARY_DIRS})

# Set Cython options
set(CYTHON_FLAGS "-3" CACHE STRING "Flags used by Cython")
set(CYTHONIZE_FLAGS "-3" "--inplace" CACHE STRING "Flags used by cythonize")

# Add Cython extension modules
add_custom_target(
    cythonize ALL
    COMMAND ${Python_EXECUTABLE} -m cython ${CYTHONIZE_FLAGS}
            src/cygit2/_repository.pyx
            src/cygit2/_reference.pyx
            src/cygit2/_index.pyx
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
)

# Define the extension modules
foreach(module _repository _reference _index)
    Python_add_library(${module} MODULE src/cygit2/${module}.c)
    target_link_libraries(${module} PRIVATE ${LIBGIT2_LIBRARIES})
    add_dependencies(${module} cythonize)
    install(TARGETS ${module} DESTINATION src/cygit2)
endforeach()
