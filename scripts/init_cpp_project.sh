#!/bin/bash

GTEST_VERSION=1.15.2

usage() {
    echo "Usage: $0 <project_name>"
    exit 1
}

if [ $# -ne 1 ]; then
    usage
fi

if [ -d "$1" ]; then
    echo "Error: Directory $1 already exists"
    exit 1
fi

# Project name
PROJECT_NAME=$1

# Create folder structure
echo "Creating project structure..."
mkdir -p $PROJECT_NAME/{app/src,lib/src,tests,cmake}

# Create CPM.cmake
echo "Downloading CPM.cmake..."
wget -q https://raw.githubusercontent.com/TheLartians/CPM.cmake/master/cmake/CPM.cmake -O $PROJECT_NAME/cmake/CPM.cmake

# Create top-level CMakeLists.txt
cat <<EOF > $PROJECT_NAME/CMakeLists.txt
cmake_minimum_required(VERSION 3.26)

include(cmake/CPM.cmake)

CPMAddPackage(
  NAME GTest
  GITHUB_REPOSITORY google/googletest
  VERSION $GTEST_VERSION
)

project ($PROJECT_NAME)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

enable_testing()

add_subdirectory(lib)
add_subdirectory(app)
add_subdirectory(tests)
EOF

# Create lib/CMakeLists.txt
cat <<EOF > $PROJECT_NAME/lib/CMakeLists.txt
add_library(lib)
target_sources(lib PRIVATE src/lib.ixx)
target_compile_features(lib PUBLIC cxx_std_23)
EOF

# Create app/CMakeLists.txt
cat <<EOF > $PROJECT_NAME/app/CMakeLists.txt
add_executable(app src/main.cpp)
target_link_libraries(app PRIVATE lib)
EOF

# Create tests/CMakeLists.txt
cat <<EOF > $PROJECT_NAME/tests/CMakeLists.txt
add_executable(test_$PROJECT_NAME test.cpp)
target_link_libraries(test_$PROJECT_NAME PRIVATE lib gtest gtest_main)
add_test(NAME Test COMMAND test_$PROJECT_NAME)
EOF

# Create Makefile
cat <<EOF > $PROJECT_NAME/Makefile
# Variables
BUILD_DIR := target
CMAKE_FLAGS := -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
BUILD_CMD := cmake --build \$(BUILD_DIR)
EXECUTABLE := \$(BUILD_DIR)/app/app

# Targets
configure:
	mkdir -p \$(BUILD_DIR)
	cmake -S . -B \$(BUILD_DIR) \$(CMAKE_FLAGS)

build:
	bear -- \$(BUILD_CMD)

restore:
	bear -- cmake \$(BUILD_DIR)

clean:
	rm -f compile_commands.json
	rm -rf \$(BUILD_DIR)

rebuild: clean configure build

all: rebuild

test:
	cd \$(BUILD_DIR) && ctest --output-on-failure

run:
	@echo "Running \$(EXECUTABLE)"
	\$(EXECUTABLE)
EOF

# Create minimal example source files
echo "Creating example source files..."
# lib/src/lib.ixx (Module Interface File)
cat <<EOF > $PROJECT_NAME/lib/src/lib.ixx
export module lib;

import <iostream>;

export void printHello() {
    std::cout << "Hello from the library!" << std::endl;
}
EOF

# app/src/main.cpp
cat <<EOF > $PROJECT_NAME/app/src/main.cpp
import lib;

int main() {
    printHello();
    return 0;
}
EOF

# tests/test.cpp
cat <<EOF > $PROJECT_NAME/tests/test.cpp
import lib;
#include <gtest/gtest.h>

TEST(LibraryTest, PrintHello) {
    testing::internal::CaptureStdout();
    printHello();
    std::string output = testing::internal::GetCapturedStdout();
    EXPECT_EQ(output, "Hello from the library!\\n");
}

int main(int argc, char **argv) {
    ::testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}
EOF

echo "C++23 Module-based project setup complete!"
