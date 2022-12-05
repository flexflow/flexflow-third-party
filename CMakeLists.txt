cmake_minimum_required(VERSION 3.10)
project(FlexFlow)

include(ExternalProject)

# Set policy CMP0074 to eliminate cmake warnings
cmake_policy(SET CMP0074 NEW)
cmake_policy(SET CMP0077 NEW)
if (CMAKE_VERSION VERSION_GREATER_EQUAL "3.24.0")
  # Fix DOWNLOAD_EXTRACT_TIMESTAMP warnings
  cmake_policy(SET CMP0135 NEW)
endif()
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
message(STATUS "BUILD_MARCH: ${BUILD_MARCH}")

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
if (FF_USE_GASNET)
  message(FATAL_ERROR "Precompilation of Legion with GASNET is not supported")
endif()

set(FF_GPU_BACKENDS cuda hip_cuda hip_rocm intel)
set(FF_GPU_BACKEND "cuda" CACHE STRING "Select GPU Backend ${FF_GPU_BACKENDS}")
set_property(CACHE FF_GPU_BACKEND PROPERTY STRINGS ${FF_GPU_BACKENDS})

# option for cuda arch
set(FF_CUDA_ARCH "" CACHE STRING "Target CUDA Arch")

# option for nccl
option(FF_USE_NCCL "Run FlexFlow with NCCL" OFF)

if (FF_GPU_BACKEND STREQUAL "hip_rocm" AND FF_USE_NCCL STREQUAL "ON")
  message(FATAL_ERROR "NCCL: ON for FF_GPU_BACKEND: hip_rocm. hip_rocm backend must have NCCL disabled.")
endif()

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

# Detect OS type and Linux version (if it applies)
set(LINUX_VERSION "")
if(${CMAKE_SYSTEM_NAME} MATCHES "Linux")
  find_program(LSB_RELEASE_EXEC lsb_release)
  if(LSB_RELEASE_EXEC)
    execute_process(COMMAND ${LSB_RELEASE_EXEC} -r --short 
                    OUTPUT_VARIABLE LINUX_VERSION 
                    OUTPUT_STRIP_TRAILING_WHITESPACE)
    message(STATUS "Linux Version: ${LINUX_VERSION}")
  endif()
endif()

# Detect CPU architecture
message(STATUS "CPU architecture: ${CMAKE_HOST_SYSTEM_PROCESSOR}")

if(FF_GPU_BACKEND STREQUAL "hip_cuda" OR FF_GPU_BACKEND STREQUAL "hip_rocm")
  set(ROCM_PATH "/opt/rocm" CACHE STRING "Default ROCM installation directory.")
endif()

# ZLIB
include(zlib)

# CUDA
if (FF_GPU_BACKEND STREQUAL "cuda" OR FF_GPU_BACKEND STREQUAL "hip_cuda")
  include(cuda)
endif()

# CUDNN
if (FF_GPU_BACKEND STREQUAL "cuda" OR FF_GPU_BACKEND STREQUAL "hip_cuda")
  include(cudnn)
endif()

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

# # json
# include(json)

# # variant
# include(variant)

# # optional
# include(optional)

if(FF_USE_PYTHON)
  list(APPEND FF_CC_FLAGS
    -DBINDINGS_AUGMENT_PYTHONPATH)
  list(APPEND FF_NVCC_FLAGS
    -DBINDINGS_AUGMENT_PYTHONPATH)
endif()

if (FF_GPU_BACKEND STREQUAL "cuda")
  list(APPEND FF_CC_FLAGS
    -DFF_USE_CUDA)
  list(APPEND FF_NVCC_FLAGS
    -DFF_USE_CUDA)
elseif (FF_GPU_BACKEND STREQUAL "hip_cuda")
  list(APPEND FF_CC_FLAGS
    -DFF_USE_HIP_CUDA)
  list(APPEND FF_HIPCC_FLAGS
    -DFF_USE_HIP_CUDA)
elseif (FF_GPU_BACKEND STREQUAL "hip_rocm")
  list(APPEND FF_CC_FLAGS
    -DFF_USE_HIP_ROCM)
  list(APPEND FF_HIPCC_FLAGS
    -DFF_USE_HIP_ROCM)
else()
endif()

# Start build FlexFlow
if (CMAKE_BUILD_TYPE STREQUAL "Debug")
  list(APPEND FF_CC_FLAGS
    -DFF_DEBUG)
  list(APPEND FF_NVCC_FLAGS
    -DFF_DEBUG)
endif()

message(STATUS "FlexFlow MAX_DIM: ${FF_MAX_DIM}")

list(APPEND FF_CC_FLAGS
  -DMAX_TENSOR_DIM=${FF_MAX_DIM})

if(FF_USE_AVX2)
  list(APPEND FF_CC_FLAGS
    -DFF_USE_AVX2
    -mavx2)
endif()

list(APPEND FF_NVCC_FLAGS
  -Wno-deprecated-gpu-targets
  -DMAX_TENSOR_DIM=${FF_MAX_DIM})

list(APPEND FF_LD_FLAGS
  -lrt
  -ldl
  -rdynamic)

# Set FF FLAGS
add_compile_options(${FF_CC_FLAGS})
set(CUDA_NVCC_FLAGS ${CUDA_NVCC_FLAGS} ${FF_NVCC_FLAGS} -UNDEBUG)
link_libraries(${FF_LD_FLAGS})

# compile flexflow lib
if (FF_GPU_BACKEND STREQUAL "cuda")
  if(BUILD_SHARED_LIBS)
    cuda_add_library(flexflow SHARED placeholder.cpp)
  else()
    cuda_add_library(flexflow STATIC placeholder.cpp)
  endif()
elseif(FF_GPU_BACKEND STREQUAL "hip_cuda" OR FF_GPU_BACKEND STREQUAL "hip_rocm")
  if(BUILD_SHARED_LIBS)
    add_library(flexflow SHARED placeholder.cpp)
  else()
    add_library(flexflow STATIC placeholder.cpp)
  endif()

  list(APPEND CMAKE_PREFIX_PATH ${ROCM_PATH}/hip ${ROCM_PATH})

  find_package(hip REQUIRED)

  if (FF_GPU_BACKEND STREQUAL "hip_cuda")
    # The targets defined by the hip cmake config only target amd devices.
    # For targeting nvidia devices, we'll make our own interface target,
    # hip_device_nvidia, that includes the rocm and hip headers. 
    add_library(hip_device_nvidia INTERFACE)

    if (NOT FF_CUDA_ARCH STREQUAL "")
      target_compile_options(hip_device_nvidia INTERFACE -arch=compute_${FF_CUDA_ARCH})
    endif()

    target_include_directories(hip_device_nvidia SYSTEM INTERFACE ${HIP_INCLUDE_DIRS} ${ROCM_PATH}/include)
    target_include_directories(hip_device_nvidia INTERFACE ${HIP_INCLUDE_DIRS} ${ROCM_PATH}/include)

    # Linking cuda: 
    # We do not explicitly link cuda. hipcc when targeting nvidia will 
    # use nvcc under the hood. nvcc when used for linking will handle 
    # linking cuda dependencies
    target_link_libraries(flexflow hip_device_nvidia)
  elseif(FF_GPU_BACKEND STREQUAL "hip_rocm")
    find_package(hipblas REQUIRED)
    find_package(miopen REQUIRED)
    # find_package(rocrand REQUIRED)
    find_library(HIP_RAND_LIBRARY hiprand REQUIRED)

    # The hip cmake config module defines three targets, 
    # hip::amdhip64, hip::host, and hip::device.
    #
    # hip::host and hip::device are interface targets. hip::amdhip64 is an 
    # imported target for libamdhip.
    #
    # You do not directly link to hip::amdhip64. hip::host links to hip::amdhip64
    # and hip::device links to hip::host. Link to hip::host to just use hip without 
    # compiling any GPU code. Link to hip::device to compile the GPU device code.
    #
    # Docs (outdated):
    # https://rocmdocs.amd.com/en/latest/Installation_Guide/Using-CMake-with-AMD-ROCm.html
    target_link_libraries(flexflow hip::device roc::hipblas MIOpen ${HIP_RAND_LIBRARY})
  endif()
else()
  message(FATAL_ERROR "Unsupported FF_GPU_BACKEND for cmake: ${FF_GPU_BACKEND}")
endif()

target_include_directories(flexflow PUBLIC ${FLEXFLOW_INCLUDE_DIRS})
#target_link_libraries(flexflow ${LEGION_LIBRARY} nlohmann_json::nlohmann_json mpark_variant optional)
target_link_libraries(flexflow ${LEGION_LIBRARY})

if(FF_USE_NCCL)
  add_dependencies(flexflow ${NCCL_NAME})
endif()


# installation
set(INCLUDE_DEST "include")
set(LIB_DEST "lib")
install(TARGETS flexflow DESTINATION ${LIB_DEST})
