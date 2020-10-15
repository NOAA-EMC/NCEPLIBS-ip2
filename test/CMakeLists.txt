#list(APPEND CMAKE_CTEST_ARGUMENTS "--output-on-failure")

execute_process(COMMAND cmake -E create_symlink
    "${CMAKE_SOURCE_DIR}/tests/data"
    "${CMAKE_CURRENT_BINARY_DIR}/data" # New name
    )

 
add_pfunit_ctest (ip2_test
  TEST_SOURCES test_mod.pf
  LINK_LIBRARIES ip2::ip2_d sp::sp_d
)
