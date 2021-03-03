set(NCCL_NAME nccl)
if(NOT DEFINED CUDA_PATH)
  if(NOT DEFINED ENV{CUDA_ROOT})
      set(CUDA_PATH ${CUDA_TOOLKIT_ROOT_DIR} CACHE PATH "Path to which CUDA has been installed")
  else()
      set(CUDA_PATH $ENV{CUDA_ROOT} CACHE PATH "Path to which CUDA has been installed")
  endif()
endif()

find_package(CUDA REQUIRED)

message("CUDA_PATH: ${CUDA_PATH}")

set(NCCL_CUDA_ARCH "-gencode=arch=compute_${CUDA_ARCH},code=sm_${CUDA_ARCH}")
message("NCCL_CUDA_ARCH: ${NCCL_CUDA_ARCH}")

ExternalProject_Add(${NCCL_NAME}
 SOURCE_DIR ${PROJECT_SOURCE_DIR}/nccl
 PREFIX ${NCCL_NAME}
 INSTALL_DIR ${NCCL_NAME}/install
 CONFIGURE_COMMAND ""
 BUILD_COMMAND make src.build "NVCC_GENCODE=${NCCL_CUDA_ARCH}" "CUDA_HOME=${CUDA_PATH}"
 BUILD_IN_SOURCE 1
)