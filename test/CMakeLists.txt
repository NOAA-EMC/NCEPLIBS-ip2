#list(APPEND CMAKE_CTEST_ARGUMENTS "--output-on-failure")

execute_process(COMMAND cmake -E create_symlink
  "${CMAKE_SOURCE_DIR}/test/data"
  "${CMAKE_CURRENT_BINARY_DIR}/data" # New name
  )

if(CMAKE_Fortran_COMPILER_ID MATCHES "^(Intel)$")
  set(CMAKE_Fortran_FLAGS "-r8 -g -traceback")
elseif(CMAKE_Fortran_COMPILER_ID MATCHES "^(GNU)$")
  set(CMAKE_Fortran_FLAGS "-fdefault-real-8 -fno-range-check -g -fbacktrace")
endif()

# Contains common routines used for testing such as reading and interpolating data
add_library(test_library input_data_mod.f90 interp_mod.f90)
target_compile_options(test_library PRIVATE "-fno-range-check" "-g" "-fbacktrace")
target_link_libraries(test_library PUBLIC ip2::ip2_d)

link_libraries(test_library)

add_executable(test_gdswzd test_gdswzd.c)
add_executable(test_lambert_bilinear test_lambert_bilinear.f90)
add_executable(test_gaussian_neighbor test_gaussian_neighbor.f90)
add_executable(test_latlon_bilinear test_latlon_bilinear.f90)
add_executable(test_mercator_bicubic test_mercator_bicubic.f90)
add_executable(test_polar-stereo_neighbor-budget test_polar-stereo_neighbor-budget.f90)
add_executable(test_rotatedB_spectral test_rotatedB_spectral.f90)
add_executable(test_rotatedE_budget test_rotatedE_budget.f90)

add_test(test_gdswzd test_gdswzd)
add_test(test_lambert_bilinear test_lambert_bilinear)
add_test(test_gaussian_neighbor test_gaussian_neighbor)
add_test(test_latlon_bilinear test_latlon_bilinear)
add_test(test_mercator_bicubic test_mercator_bicubic)
add_test(test_polar-stereo_neighbor-budget test_polar-stereo_neighbor-budget)
add_test(test_rotatedB_spectral test_rotatedB_spectral)
add_test(test_rotatedE_budget test_rotatedE_budget)
