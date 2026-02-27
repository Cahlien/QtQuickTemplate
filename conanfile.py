from conan import ConanFile


class QtQuickTemplateWorkspaceRecipe(ConanFile):
    """Workspace version-authority recipe.

    This file is the single-version-rule authority for all third-party
    dependency versions used across the monorepo.  Individual project
    conanfiles (e.g. app/conanfile.py) declare *which* packages they
    need; the canonical version of each package is recorded here so that
    all products in the workspace resolve to the same version.

    Workflow
    --------
    1. Add a dependency in a project conanfile, e.g. app/conanfile.py:
           self.requires("fmt/11.0.2")
    2. Record the same version as a comment below under "Canonical
       dependency versions" so the authoritative list is in one place.
    3. Reinstall workspace dependencies (resolves and rebuilds as needed):
           ./tools/uv run conan workspace install --build=missing
    4. Commit conanfile.py, the project's conanfile.py, and conan.lock.

    When a version must be bumped, update it here and in every project
    conanfile that declares the same package, then regenerate the lockfile.
    """

    name = "qtquicktemplate-workspace"
    version = "0.1.0"

    settings = "os", "compiler", "build_type", "arch"
    generators = "CMakeConfigDeps"

    def requirements(self):
        # Canonical dependency versions for the entire monorepo.
        # Mirror every self.requires() that appears in any project's
        # conanfile.py so that the authoritative version list is visible
        # here in one place.

        self.requires("anyrpc/1.0.2")
