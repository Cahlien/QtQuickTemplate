from conan import ConanFile
from conan.tools.cmake import CMake


class QtQuickTemplateRecipe(ConanFile):
    name = "qtquicktemplate"
    version = "0.1.0"

    settings = "os", "compiler", "build_type", "arch"
    generators = "CMakeDeps", "CMakeToolchain"

    def requirements(self):
        # Add your Conan dependencies here, e.g.:
        # self.requires("fmt/11.0.2")
        pass

    def layout(self):
        # Keep generator outputs in the explicit --output-folder location.
        # This makes local developer flows deterministic (e.g. build/conan/).
        self.folders.generators = "."

    def build(self):
        cmake = CMake(self)
        cmake.configure()
        cmake.build()
