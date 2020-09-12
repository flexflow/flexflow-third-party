cmake_minimum_required(VERSION 3.10)
project(FlexFlow-ThirdParty)

include(ExternalProject) 

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CMAKE_CURRENT_SOURCE_DIR}/cmake)

set(ENABLE_LEGION_DEFAULT ON)
set(ENABLE_PROTOBUF_DEFAULT ON)

# third party libraries to build
option(ENABLE_LEGION "Build Legion" ${ENABLE_LEGION_DEFAULT})
option(ENABLE_PROTOBUF "Build Protobuf" ${ENABLE_PROTOBUF_DEFAULT})

#legion options
option(LEGION_USE_PYTHON "enable Python in Legion" ON)

#build the libraries
if(ENABLE_LEGION)
  include(cmake/legion.cmake)
endif()

if(ENABLE_PROTOBUF)
  include(cmake/protobuf.cmake)
endif()