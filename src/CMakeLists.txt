# Reference:
# https://github.com/apache/arrow/blob/master/cpp/examples/parquet/parquet-arrow/CMakeLists.txt


cmake_minimum_required(VERSION 3.2.0)
project (hello)

include(ExternalProject)
include(FindPkgConfig)
include(GNUInstallDirs)

# This ensures that things like gnu++11 get passed correctly
set(CMAKE_CXX_STANDARD 11)

# We require a C++11 compliant compiler
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/../build/vcpkg/installed/x64-windows/share/parquet")

# find_package(Parquet REQUIRED)
find_library(PARQUET_LIB parquet)

find_library(ARROW_LIB arrow)

if(NOT PARQUET_LIB)
  message(FATAL_ERROR "parquet library not found")
endif()

if(NOT ARROW_LIB)
  message(FATAL_ERROR "Arrow library not found")
endif()

find_path(PARQUET_HEADERS "parquet/parquet_version.h")

if(NOT PARQUET_HEADERS)
  message(FATAL_ERROR "parquet headers not found")
endif()

# define source code for "hello"
add_executable(hello helloworld.cpp)

# link "parquet" into "hello"
target_link_libraries(hello ${PARQUET_LIB} ${ARROW_LIB})
target_include_directories(hello PUBLIC ${PARQUET_HEADERS})