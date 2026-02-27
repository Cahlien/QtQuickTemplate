import os
from conan import Workspace, ConanFile
from conan.tools.files import save
from conan.tools.cmake import CMakeDeps, CMakeToolchain, cmake_layout

class QtQuickProjectFile(ConanFile):
    settings = "os", "compiler", "build_type", "arch"

    def generate(self):
        CMakeDeps(self).generate()
        CMakeToolchain(self).generate()

    def layout(self):
        cmake_layout(self)


class Ws(Workspace):
    def root_conanfile(self):
        return QtQuickProjectFile

    def packages(self):
        result = []
        for f in os.listdir(self.folder):
            p = os.path.join(self.folder, f)
            if os.path.isdir(p) and os.path.isfile(os.path.join(p, "conanfile.py")):
                result.append({"path": f})
        return result

    def build_order(self, order):
        super().build_order(order)
        package_list = " ".join([f'{it["ref"].name}:{it["folder"]}' for level in order for it in level])
        save(self, "build/conanws_build_order.cmake", f"set(CONAN_WS_BUILD_ORDER {package_list})")