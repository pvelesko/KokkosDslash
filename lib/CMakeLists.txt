set( LIB_SRCS ./utils/print_utils.cpp
                     ../include/utils/print_utils.h 
                     ./utils/initialize.cpp 
                     ../include/utils/initialize.h
                     ../include/lattice/lattice_info.h
                     ./lattice/lattice_info.cpp 
                     ../include/lattice/nodeinfo.h
                     ./lattice/nodeinfo.cpp )
                     
if( MG_ARCH_PARSCALAR_ARCH )
   list(APPEND LIB_SRCS ./lattice/nodeinfo_qmp.cpp)
else()
   list(APPEND LIB_SRCS ./lattice/nodeinfo_single.cpp)
endif()
 

add_library( libmg ${LIB_SRCS} ) 
target_link_libraries( libmg  qdp)
target_link_libraries( libmg )

if (Kokkos_FOUND)
  message(STATUS "limb using Kokkos found at ${Kokkos_ROOT}")
  message(STATUS "Kokkos include ${Kokkos_INCLUDE}")
  message(STATUS "Kokkos lib ${Kokkos_LIB}")
else()
  message(FATAL_ERROR "limb missing Kokkos")
endif()

if (Kokkos_ENABLE_OPENMP)
  message(STATUS "OpenMP Enabled in Kokkos, adding OpenMP as a link target")
  if(OpenMP_CXX_FOUND)
    message(STATUS "OpenMP Found")
    target_link_libraries( libmg OpenMP::OpenMP_CXX)
  else()
    message(FATAL_ERROR "OpenMP Not Found")
  endif()
endif()

# Add include/ onto the include path
target_include_directories( libmg PUBLIC 
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/../include>
	$<INSTALL_INTERFACE:include>)

target_include_directories( libmg PUBLIC 
	$<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/../include>
	$<INSTALL_INTERFACE:include>)
	
	
target_include_directories(libmg PUBLIC "${Kokkos_INCLUDE}")
#target_include_directories(libmg PUBLIC "${Kokkos_SOURCE_DIR}/core/src")
#target_include_directories(libmg PUBLIC "${Kokkos_SOURCE_DIR}/containers/src")
#target_include_directories(libmg PUBLIC "${Kokkos_SOURCE_DIR}/algorithms/src")
#target_include_directories(libmg PUBLIC "${Kokkos_BINARY_DIR}")
	



# Link any dependent libraries
# target_link_libraries( libmg dependent_lib )

# Install the library and the targets 
# into the export for the targets
install(TARGETS libmg EXPORT MyProjectTargets
  ARCHIVE DESTINATION lib
  LIBRARY  DESTINATION lib
  RUNTIME DESTINATION bin
  INCLUDES DESTINATION include)


