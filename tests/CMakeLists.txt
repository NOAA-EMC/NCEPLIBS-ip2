#list(APPEND CMAKE_CTEST_ARGUMENTS "--output-on-failure")

file(COPY data/ DESTINATION data)

add_pfunit_ctest (ip2_test
  TEST_SOURCES test_mod.pf
  LINK_LIBRARIES ip2::ip2_d sp::sp_d
)
