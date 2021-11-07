cmake_minimum_required(VERSION 3.20)
project(pam_bt C)

set(CMAKE_C_STANDARD 99)
#set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

set(CMAKE_LIBRARY_PATH ${CMAKE_LIBRARY_PATH} /Users/ryanfitzgerald/Desktop/libpam-so-files/security)
link_directories(/Users/ryanfitzgerald/Desktop/libpam-so-files/security)
include_directories(/Users/ryanfitzgerald/Desktop/libpam-so-files/security)

find_library(Pam pam
        PATHS /Users/ryanfitzgerald/Desktop/libpam-so-files/security)

include_directories(
        ${PAM_INCLUDE_DIR}
        ${CMAKE_BINARY_DIR}
        ${CMAKE_CURRENT_BINARY_DIR}
)

add_library(pam_bt SHARED library.c)

target_link_libraries(pam_bt Pam)
