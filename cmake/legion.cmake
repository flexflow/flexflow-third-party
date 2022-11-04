if(FF_USE_EXTERNAL_LEGION)
	if(NOT "${LEGION_ROOT}" STREQUAL "")
    set(CMAKE_PREFIX_PATH ${CMAKE_PREFIX_PATH} ${LEGION_ROOT}/share/Legion/cmake)
	endif()
	find_package(Legion REQUIRED)
	get_target_property(LEGION_INCLUDE_DIRS Legion::RealmRuntime INTERFACE_INCLUDE_DIRECTORIES)
	string(REGEX REPLACE "/include" "" LEGION_ROOT_TMP ${LEGION_INCLUDE_DIRS})
	if("${LEGION_ROOT}" STREQUAL "")
		set(LEGION_ROOT ${LEGION_ROOT_TMP})
	else()
		if(NOT "${LEGION_ROOT}" STREQUAL ${LEGION_ROOT_TMP})
			message( FATAL_ERROR "LEGION_ROOT is not set correctly ${LEGION_ROOT} ${LEGION_ROOT_TMP}")
		endif()
	endif()
	message(STATUS "Use external Legion cmake found: ${LEGION_ROOT_TMP}")
	message(STATUS "Use external Legion: ${LEGION_ROOT}")
	set(LEGION_LIBRARY Legion::Legion)
else()
	if(FF_USE_PYTHON)
	  set(Legion_USE_Python ON CACHE BOOL "enable Legion_USE_Python")
	endif()
	if(FF_USE_GASNET)
	  set(Legion_EMBED_GASNet ON CACHE BOOL "Use embed GASNet")
	  set(Legion_EMBED_GASNet_VERSION "GASNet-2022.3.0" CACHE STRING "GASNet version")
	  set(Legion_NETWORKS "gasnetex" CACHE STRING "GASNet conduit")
	  set(GASNet_CONDUIT ${FF_GASNET_CONDUIT})
	endif()
	message(STATUS "GASNET ROOT: $ENV{GASNet_ROOT_DIR}")
	set(Legion_MAX_DIM ${FF_MAX_DIM} CACHE STRING "Maximum number of dimensions")
	#add_definitions(-DMAX_RETURN_SIZE=32768)
	#add_definitions(-DLEGION_MAX_RETURN_SIZE=32768)
	
	set(Legion_USE_CUDA ON CACHE BOOL "enable Legion_USE_CUDA")
	set(Legion_CUDA_ARCH ${FF_CUDA_ARCH} CACHE STRING "Legion CUDA ARCH")
	message(STATUS "Legion_CUDA_ARCH: ${Legion_CUDA_ARCH}")
	add_subdirectory(deps/legion)
	set(LEGION_LIBRARY Legion)
endif()

