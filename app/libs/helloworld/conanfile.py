from conan import ConanFile
from conan.tools.cmake import CMake, cmake_layout


class HelloWorldRecipe(ConanFile):
    name = "qtquicktemplate-helloworld"
    version = "0.2.0"

    settings = "os", "compiler", "build_type", "arch"
    generators = "CMakeDeps", "CMakeToolchain"

    def requirements(self):
        pass

    def layout(self):
        cmake_layout(self)

    def build(self):
        cmake = CMake(self)
        cmake.configure()
        cmake.build()
