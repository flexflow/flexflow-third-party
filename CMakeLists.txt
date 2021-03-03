cmake_minimum_required(VERSION 3.10)
project(FlexFlow-ThirdParty)

include(CMakeDependentOption)
include(ExternalProject) 

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CMAKE_CURRENT_SOURCE_DIR}/cmake)

set(ENABLE_LEGION_DEFAULT ON)
set(ENABLE_GASNET_DEFAULT ON)
set(ENABLE_NCCL_DEFAULT ON)

# third party libraries to build
option(ENABLE_LEGION "Build Legion" ${ENABLE_LEGION_DEFAULT})
option(ENABLE_NCCL "Build nccl" ${ENABLE_NCCL_DEFAULT})

#legion options
option(LEGION_USE_PYTHON "enable Python in Legion" ON)
cmake_dependent_option(ENABLE_GASNET "Build gasnet" ${ENABLE_GASNET_DEFAULT}
                       "ENABLE_LEGION" OFF)
set(GASNet_CONDUITS udp mpi ibv psm)
set(GASNet_CONDUIT "mpi" CACHE STRING "Select Gasnet conduit ${GASNet_CONDUITS}")
set(CUDA_ARCH "" CACHE STRING "Target CUDA Arch")
set(MAX_DIM "4" CACHE STRING "Max DIM")
set(PYTHON_VERSION "" CACHE STRING "Python Version")
set_property(CACHE GASNet_CONDUIT PROPERTY STRINGS ${GASNet_CONDUITS})

#build the libraries
if(ENABLE_GASNET)
  include(cmake/gasnet.cmake)
endif()

if(ENABLE_LEGION)
  include(cmake/legion.cmake)
endif()

if(ENABLE_NCCL)
  include(cmake/nccl.cmake)
endif()
