cmake_minimum_required(VERSION 3.10)
project(FlexFlow)

include(ExternalProject)

# Set policy CMP0074 to eliminate cmake warnings
cmake_policy(SET CMP0074 NEW)
cmake_policy(SET CMP0077 NEW)
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CMAKE_CURRENT_LIST_DIR}/cmake)
set(FLEXFLOW_ROOT ${CMAKE_CURRENT_LIST_DIR})
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -UNDEBUG")

# Set a default build type if none was specified
set(default_build_type "Debug")
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
  message(STATUS "Setting build type to '${default_build_type}' as none was specified.")
  set(CMAKE_BUILD_TYPE "${default_build_type}" CACHE
      STRING "Choose the type of build." FORCE)
endif()

# do not disable assertions even if in release mode
set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -UNDEBUG")

if(${CMAKE_SYSTEM_NAME} MATCHES "Linux")
  set(LIBEXT ".so")
endif()

# only used for pypi
option(FF_BUILD_FROM_PYPI "Build from pypi" OFF)

# build shared or static flexflow lib
option(BUILD_SHARED_LIBS "Build shared libraries instead of static ones" ON)

# option for using Python
option(FF_USE_PYTHON "Enable Python" ON)

# option for using Python
option(FF_USE_GASNET "Run FlexFlow with GASNet" OFF)
set(FF_GASNET_CONDUITS aries udp mpi ibv ucx)
set(FF_GASNET_CONDUIT "mpi" CACHE STRING "Select GASNet conduit ${FF_GASNET_CONDUITS}")
set_property(CACHE FF_GASNET_CONDUIT PROPERTY STRINGS ${FF_GASNET_CONDUITS})

set(FF_GPU_BACKENDS cuda hip_cuda hip_rocm intel)
set(FF_GPU_BACKEND "cuda" CACHE STRING "Select GPU Backend ${FF_GPU_BACKENDS}")
set_property(CACHE FF_GPU_BACKEND PROPERTY STRINGS ${FF_GPU_BACKENDS})

# option for cuda arch
set(FF_CUDA_ARCH "" CACHE STRING "Target CUDA Arch")

# option for nccl
option(FF_USE_NCCL "Run FlexFlow with NCCL" OFF)

# option for Legion
option(FF_BUILD_LEGION "Build Legion" OFF)

# option for avx2
option(FF_USE_AVX2 "Run FlexFlow with AVX2" OFF)

# option for max dim
set(FF_MAX_DIM "4" CACHE STRING "Maximum dimention of tensors")

# option for legion
option(FF_USE_EXTERNAL_LEGION "Use pre-installed Legion" OFF)

set(FLEXFLOW_EXT_LIBRARIES "")
set(FLEXFLOW_INCLUDE_DIRS "")

# get FLAGS from ENV
set(CC_FLAGS $ENV{CC_FLAGS})
set(NVCC_FLAGS $ENV{NVCC_FLAGS})
set(LD_FLAGS $ENV{LD_FLAGS})

# Set global FLAGS
list(APPEND CC_FLAGS
  -std=c++11)

list(APPEND NVCC_FLAGS
  -std=c++11)

add_compile_options(${CC_FLAGS})
set(CUDA_NVCC_FLAGS ${CUDA_NVCC_FLAGS} ${NVCC_FLAGS})
link_libraries(${LD_FLAGS})

# ZLIB
include(zlib)

# CUDA
include(cuda)

# CUDNN
include(cudnn)

# NCCL
if(FF_USE_NCCL)
  include(nccl)
  list(APPEND FF_CC_FLAGS
    -DFF_USE_NCCL)
  list(APPEND FF_NVCC_FLAGS
    -DFF_USE_NCCL)
endif()

# Legion
if(FF_BUILD_LEGION)
  include(legion)
endif()

# json
include(json)

# variant
include(variant)

# optional
include(optional)

# # Python
# if(FF_USE_PYTHON)
#   add_subdirectory(deps/pybind11)
# endif()

# compile flexflow lib
if(BUILD_SHARED_LIBS)
  cuda_add_library(flexflow SHARED)
else()
  cuda_add_library(flexflow STATIC)
endif()

target_include_directories(flexflow PUBLIC ${FLEXFLOW_INCLUDE_DIRS})
target_link_libraries(flexflow ${LEGION_LIBRARY} nlohmann_json::nlohmann_json mpark_variant optional)

if(FF_USE_NCCL)
  add_dependencies(flexflow ${NCCL_NAME})
endif()


# installation
set(INCLUDE_DEST "include")
set(LIB_DEST "lib")
install(TARGETS flexflow DESTINATION ${LIB_DEST})
