cmake_minimum_required(VERSION 3.13)
project(KokkosDslash VERSION 0.1
                  DESCRIPTION "Kokkos Dslash"
                  LANGUAGES CXX)

cmake_policy(SET CMP0074 NEW)  

# Basic Includes
include(GNUInstallDirs)
include(CTest)
include(CMakePackageConfigHelpers)

set(CMAKE_CXX_STANDARD 14 CACHE STRING "C++ Standard to use 14+" FORCE)
message(STATUS "Set CMAKE_CXX_STANDARD ${CMAKE_CXX_STANDARD}")
set(CMAKE_CXX_EXTENSIONS CACHE BOOL OFF)


# Deal with default loglevel
# If code is built in release mode it will be INFO
# Otherwise  it will be build set to DEBUG
# Users can set it of course.
set( MG_DEFAULT_LOGLEVEL "DEBUG" CACHE STRING "Default LogLevel can be INFO, DEBUG, DEBUG2 DEBUG3")
set( MG_VECLEN_SP "4" CACHE STRING "Single Precision Vector Length (default is 4 for AVX2")
option(MG_FORTRANLIKE_COMPLEX "Fortran like complex ordering (r,i,r,i,...r,i) for vectors" OFF)

# Kokkos-Dslash specific options
option(MG_USE_AVX512 "Use AVX512 intrinsics" FALSE)
option(MG_USE_AVX2 "Use AVX512 intrinsics" TRUE)
option(MG_KOKKOS_USE_CUDA "Use CUDA" FALSE)
option(MG_KOKKOS_USE_FLAT_DISPATCH "Flat parallel for..." FALSE)
option(MG_KOKKOS_USE_TEAM_DISPATCH "Team based parallel for" FALSE)
option(MG_KOKKOS_USE_MDRANGE_DISPATCH "MDRange based parallel for" FALSE)
option(MG_KOKKOS_USE_NEIGHBOR_TABLE "Should we compute neighbor index or use a table" TRUE)

# Kokkos Backend Options
option(MG_USE_CUDA "Use Kokkos::CUDA execution space" OFF)
option(MG_USE_OPENMP "Use Kokkos::OpenMP execution space" OFF)
option(MG_USE_OPENMPTARGET "Use Kokkos::Experimental::OpenMPTarget execution space" OFF)
option(MG_USE_SYCL "Use Kokkos::Experimental::SYCL execution space" OFF)
option(MG_USE_HIP "Use Kokkos::HIP execution space" OFF)

if(MG_USE_CUDA)
  add_compile_options(-Wno-error)
endif()

# Kokkos Options
set (Kokkos_ROOT "" CACHE PATH "path to Kokkos install if you don't want to use the builtin submodule.")

if( MG_USE_AVX512 )
	message(STATUS "Using AVX512")
endif()

if( MG_USE_AVX2 )
	message(STATUS "Using AVX2")
endif()


find_package(Kokkos)
if(Kokkos_FOUND)
  message(STATUS "Kokkos was found... ${Kokkos_ROOT}")
else()
  message(STATUS "Kokkos was not found (Kokkos_ROOT was not set) Using Kokkos submodule.")
  message(STATUS "Make sure KokkosDlash was cloned with --recursive")

  add_subdirectory("${PROJECT_SOURCE_DIR}/extern/kokkos" "extern/kokkos")
  set(Kokkos_SOURCE STRING "${PROJECT_SOURCE_DIR}/extern/kokkos/core/src")
  set(Kokkos_FOUND TRUE)
  set(Kokkos_ROOT "extern/Kokkos")
  set(Kokkos_INCLUDE "${Kokkos_SOURCE}")
  set(Kokkos_LIB "${Kokkos_ROOT}/lib")
  message(STATUS "Kokkos found. Using Kokkos include ${Kokkos_INCLUDE}")
  message(STATUS "Kokkos found. Using Kokkos libs ${Kokkos_LIB}")
  include_directories("${Kokkos_INCLUDE}")

  #set(Kokkos_ROOT "${PROJECT_SOURCE_DIR}/extern/kokkos")
  #set(Kokkos_INCLUDE "${Kokkos_ROOT}/include")
  #set(Kokkos_LIB "${Kokkos_ROOT}/lib")
  
  #else()
  #  message(STATUS "Kokkos_ROOT was set to ${Kokkos_ROOT}")
  #  # Use Kokkos that's already installed on the system
  #  find_package(Kokkos REQUIRED PATHS "${Kokkos_ROOT}/lib/cmake/Kokkos")
  #  if (Kokkos_FOUND)
  #    set(Kokkos_INCLUDE "${Kokkos_ROOT}/include")
  #    set(Kokkos_LIB "${Kokkos_ROOT}/lib")
  #    message(STATUS "Kokkos found. Using Kokkos include ${Kokkos_INCLUDE}")
  #    message(STATUS "Kokkos found. Using Kokkos libs ${Kokkos_LIB}")
  #    include_directories("${Kokkos_INCLUDE}")
  #  else()
  #    message(FATAL_ERROR "Kokkos CMake config file not found at ${Kokkos_ROOT}/lib/cmake/Kokkos")
  #  endif()
endif()

# Find OpenMP for backward compatibiliy
if ( Kokkos_ENABLE_OPENMP )
  message(STATUS "Kokkos is using OpenMP and so am I")
  find_package(OpenMP REQUIRED)
  if (OPENMP_FOUND)
    set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${OpenMP_CXX_FLAGS}")
  endif()
  find_package(Threads REQUIRED)
  if (THREADS_FOUND)
    set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${Threads_CXX_FLAGS}")
endif()
endif()


if ( Kokkos_ENABLE_SYCL )
  message(STATUS "Kokkos SYCL backend is enabled")
  message(STATUS "${CMAKE_CXX_COMPILER_ID}")
  if (CMAKE_CXX_COMPILER_ID MATCHES "IntelLLVM") 
    add_compile_options(-fsycl -fsycl-unnamed-lambda)
  else()
    message(FATAL_ERROR "Intel OneAPI icpx compiler must be used for Kokkos SYCL backend")
  endif()
endif()


if (Kokkos_ENABLE_OPENMPTARGET)
   message(STATUS "Kokkos is using OpenMPTarget and so am I")
   set(MG_USE_OPENMPTARGET ON)
endif()

# Find QDP++  for tests
list(APPEND CMAKE_MODULE_PATH "${QDPXX_DIR}")
find_package(QDPXX)
if( QDPXX_FOUND ) 
  set( HAVE_QDPXX "1")
  if( QDPXX_PARALLEL_ARCH STREQUAL "parscalar" )
     set(MG_PARSCALAR_ARCH TRUE)
  endif()
endif() 

configure_file(${CMAKE_CURRENT_SOURCE_DIR}/include/kokkos_dslash_config.h.cmake.in
  ${CMAKE_CURRENT_BINARY_DIR}/include/kokkos_dslash_config.h)
  
# Add the Googletest directory and mark its targets etc as advanced
add_subdirectory("${PROJECT_SOURCE_DIR}/extern/googletest" "extern/googletest")
mark_as_advanced(
    BUILD_GMOCK BUILD_GTEST BUILD_SHARED_LIBS
    gmock_build_tests gtest_build_samples gtest_build_tests
    gtest_disable_pthreads gtest_force_shared_crt gtest_hide_internal_symbols
)


add_subdirectory(lib)
#Make tests here
add_subdirectory(test)


# Install the headers
install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/include DESTINATION ${CMAKE_INSTALL_PREFIX})

# Install the generated headers
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/include/sycl_dslash_config.h DESTINATION ${CMAKE_INSTALL_PREFIX}/include/)

# Set some variables to export to the config file if not already set
#set(KokkosDslash_INCLUDE_DIR ${CMAKE_INSTALL_PREFIX}/include)

# Make the config file
#configure_package_config_file(SyCLDslashConfig.cmake.in SyCLDslashConfig.cmake INSTALL_DESTINATION lib/cmake/SyCLDslash PATH_VARS SyCLDslash_INCLUDE_DIR)

# Make the version file
#write_basic_package_version_file(
#    SyCLDslashVersion.cmake
#    VERSION ${PACKAGE_VERSION}
#    COMPATIBILITY AnyNewerVersion
#    )

#install(FILES ${CMAKE_CURRENT_BINARY_DIR}/SyCLDslashVersion.cmake ${CMAKE_CURRENT_BINARY_DIR}/SyCLDslashConfig.cmake DESTINATION lib/cmake/SyCLDslash)


#install(EXPORT SyCLDslashTargets NAMESPACE SyCLDslash:: DESTINATION lib/cmake/SyCLDslash )

# Export stuff
# This remains a mystery
#export(PACKAGE SyCLDslash)
