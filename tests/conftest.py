import os
import shutil
import tempfile
from pathlib import Path

import pytest

from cygit2 import Repository


@pytest.fixture
def temp_dir():
    """Create a temporary directory for test repositories."""
    temp_path = tempfile.mkdtemp()
    yield temp_path
    shutil.rmtree(temp_path)


@pytest.fixture
def repo_path(temp_dir):
    """Create a path for a test repository."""
    return os.path.join(temp_dir, "test-repo")


@pytest.fixture
def empty_repo(repo_path):
    """Create an empty Git repository."""
    repo = Repository.init(repo_path)
    yield repo


@pytest.fixture
def repo_with_commit(empty_repo, repo_path):
    """Create a repository with a single commit."""
    # Create a test file
    test_file = os.path.join(repo_path, "test.txt")
    with open(test_file, "w") as f:
        f.write("Test content")

    # Add and commit the file
    index = empty_repo.index
    index.add("test.txt")

    # Create a test signature
    signature = empty_repo.default_signature()

    # Create the initial commit
    tree = index.write_tree()
    empty_repo.create_commit(
        "HEAD",  # reference name
        signature,  # author
        signature,  # committer
        "Initial commit",  # message
        tree,  # tree
        []  # parents
    )

    yield empty_repo


@pytest.fixture
def clone_path(temp_dir):
    """Create a path for a cloned repository."""
    return os.path.join(temp_dir, "cloned-repo")


@pytest.fixture
def bare_repo(repo_path):
    """Create a bare Git repository."""
    repo = Repository.init(repo_path, bare=True)
    yield repo


@pytest.fixture
def complex_repo(empty_repo, repo_path):
    """Create a repository with multiple commits, branches, and tags."""
    # Create initial commit
    test_file = os.path.join(repo_path, "test.txt")
    with open(test_file, "w") as f:
        f.write("Initial content")

    index = empty_repo.index
    index.add("test.txt")
    signature = empty_repo.default_signature()
    tree = index.write_tree()
    initial_commit = empty_repo.create_commit(
        "HEAD",
        signature,
        signature,
        "Initial commit",
        tree,
        []
    )

    # Create a feature branch
    feature_branch = empty_repo.create_branch("feature", initial_commit)
    empty_repo.checkout(feature_branch)

    # Make changes in feature branch
    with open(test_file, "w") as f:
        f.write("Feature branch content")

    index.add("test.txt")
    tree = index.write_tree()
    feature_commit = empty_repo.create_commit(
        "HEAD",
        signature,
        signature,
        "Feature commit",
        tree,
        [initial_commit]
    )

    # Create a tag
    empty_repo.create_tag(
        "v1.0",
        feature_commit,
        signature,
        "Version 1.0",
        False  # not lightweight
    )

    # Return to main branch
    main_branch = empty_repo.lookup_branch("main")
    empty_repo.checkout(main_branch)

    yield empty_repo
