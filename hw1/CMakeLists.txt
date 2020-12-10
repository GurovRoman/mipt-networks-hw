cmake_minimum_required(VERSION 3.17)
project(networks1)

set(CMAKE_CXX_STANDARD 17)

add_executable(networks1 main.cpp)

find_package(Threads REQUIRED)
target_link_libraries(networks1 PRIVATE Threads::Threads)