# End-to-end test: consume the CI-published prebuilt Qt via FetchContent.
# Downloads qt-wdk7-shared-i386.7z from the floating v5.6.3 release, then
# find_package(Qt5) + AUTOMOC + build a small app.
cmake_minimum_required(VERSION 3.18)
project(fetchtest CXX)
cmake_policy(SET CMP0091 NEW)

set(QT5_PROVIDER prebuilt CACHE STRING "" FORCE)
set(QT5_LINK     shared   CACHE STRING "" FORCE)
set(QT5_ARCH     i386     CACHE STRING "" FORCE)
include(${CMAKE_CURRENT_LIST_DIR}/../../../cmake/qt5.cmake)
qt5_provide()

set(CMAKE_AUTOMOC ON)
find_package(Qt5 5.6 REQUIRED COMPONENTS Core)

add_executable(app ${CMAKE_CURRENT_LIST_DIR}/../cmake-consumer/main.cpp)
target_link_libraries(app Qt5::Core)
