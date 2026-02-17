from conan import ConanFile
from conan.tools.cmake import CMake, cmake_layout


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
        cmake_layout(self)

    def build(self):
        cmake = CMake(self)
        cmake.configure()
        cmake.build()
