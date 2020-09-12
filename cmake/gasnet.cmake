set(GASNET_NAME gasnet)
set(GASNET_URL ${PROJECT_SOURCE_DIR}/files)
set(GASNET_GZ  GASNet-1.32.0.tar)
set(GASNET_MD5 "1dd356195501ece76c2063e1e78914a0")

if(GASNet_CONDUIT STREQUAL "udp")
   set(CONF_OPTS --enable-udp --disable-mpi --disable-ibv)
elseif(GASNet_CONDUIT STREQUAL "mpi")
   set(CONF_OPTS --enable-mpi --disable-udp --disable-ibv)
elseif(GASNet_CONDUIT STREQUAL "ibv")
   set(CONF_OPTS --disable-mpi --disable-udp --enable-ibv)
elseif(GASNet_CONDUIT STREQUAL "psm")
   set(CONF_OPTS --disable-mpi --disable-udp --disable-ibv --enable-psm)
else() 
  message (ERROR "wrong Gasnet conduit specified")
endif ()

find_package(MPI REQUIRED)
 
message(STATUS "Building ${GASNET_NAME}")
ExternalProject_Add(${GASNET_NAME}
 URL ${GASNET_URL}/${GASNET_GZ}
 URL_MD5 ${GASNET_MD5}
 PREFIX ${GASNET_NAME}
 INSTALL_DIR ${GASNET_NAME}/install
 CONFIGURE_COMMAND <SOURCE_DIR>/configure --prefix=<INSTALL_DIR>  ${CONF_OPTS}  --enable-par --enable-mpi-compat  "CC=${CMAKE_C_COMPILER} -fPIC" "CXX=${CMAKE_CXX_COMPILER} -fPIC" "MPI_CC=${MPI_C_COMPILER} -fPIC"
 LOG_BUILD 1
)
ExternalProject_get_property(${GASNET_NAME} INSTALL_DIR)
install(DIRECTORY ${INSTALL_DIR}/ DESTINATION ${CMAKE_INSTALL_PREFIX} USE_SOURCE_PERMISSIONS)