# CMake generated Testfile for 
# Source directory: /home/firefly/HASHFin/ngcc_bench-main
# Build directory: /home/firefly/HASHFin/ngcc_bench-main/build
# 
# This file includes the relevant testing commands required for 
# testing this directory and lists subdirectories to be tested as well.
add_test(ngcc_cli_regression "/home/firefly/HASHFin/ngcc_bench-main/build/ngcc_cli_regression_test" "/home/firefly/HASHFin/ngcc_bench-main/build/ngcc_bench" "/home/firefly/HASHFin/ngcc_bench-main/build/tests/mock/libmock_ngcc.so" "/home/firefly/HASHFin/ngcc_bench-main/build/tests/mock/libmock_hash_only.so")
set_tests_properties(ngcc_cli_regression PROPERTIES  _BACKTRACE_TRIPLES "/home/firefly/HASHFin/ngcc_bench-main/CMakeLists.txt;175;add_test;/home/firefly/HASHFin/ngcc_bench-main/CMakeLists.txt;0;")
add_test(ngcc_mock_mlkem "/home/firefly/HASHFin/ngcc_bench-main/build/ngcc_mock_mlkem_test" "/home/firefly/HASHFin/ngcc_bench-main/build/ngcc_bench" "/home/firefly/HASHFin/ngcc_bench-main/build/tests/mock/libmock_mlkem.so")
set_tests_properties(ngcc_mock_mlkem PROPERTIES  _BACKTRACE_TRIPLES "/home/firefly/HASHFin/ngcc_bench-main/CMakeLists.txt;182;add_test;/home/firefly/HASHFin/ngcc_bench-main/CMakeLists.txt;0;")
add_test(ngcc_mock_mldsa "/home/firefly/HASHFin/ngcc_bench-main/build/ngcc_mock_mldsa_test" "/home/firefly/HASHFin/ngcc_bench-main/build/ngcc_bench" "/home/firefly/HASHFin/ngcc_bench-main/build/tests/mock/libmock_mldsa.so")
set_tests_properties(ngcc_mock_mldsa PROPERTIES  _BACKTRACE_TRIPLES "/home/firefly/HASHFin/ngcc_bench-main/CMakeLists.txt;188;add_test;/home/firefly/HASHFin/ngcc_bench-main/CMakeLists.txt;0;")
add_test(ngcc_mock_mlkex "/home/firefly/HASHFin/ngcc_bench-main/build/ngcc_mock_mlkex_test" "/home/firefly/HASHFin/ngcc_bench-main/build/ngcc_bench" "/home/firefly/HASHFin/ngcc_bench-main/build/tests/mock/libmock_mlkex.so")
set_tests_properties(ngcc_mock_mlkex PROPERTIES  _BACKTRACE_TRIPLES "/home/firefly/HASHFin/ngcc_bench-main/CMakeLists.txt;194;add_test;/home/firefly/HASHFin/ngcc_bench-main/CMakeLists.txt;0;")
add_test(ngcc_unit_tests "/home/firefly/HASHFin/ngcc_bench-main/build/ngcc_unit_tests")
set_tests_properties(ngcc_unit_tests PROPERTIES  _BACKTRACE_TRIPLES "/home/firefly/HASHFin/ngcc_bench-main/CMakeLists.txt;213;add_test;/home/firefly/HASHFin/ngcc_bench-main/CMakeLists.txt;0;")
