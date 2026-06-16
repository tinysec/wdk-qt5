cmake_minimum_required(VERSION 3.16)
project(qtchartstest CXX)
cmake_policy(SET CMP0091 NEW)

find_package(Qt5 5.6 REQUIRED COMPONENTS Charts)

add_executable(chartsapp main.cpp)
target_link_libraries(chartsapp Qt5::Charts)
