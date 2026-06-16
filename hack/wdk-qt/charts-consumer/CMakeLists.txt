cmake_minimum_required(VERSION 3.20)
project(charts_mdi CXX)

# Consumed against a local install prefix via CMAKE_PREFIX_PATH (set by
# test-charts-consume.bat). CONSUME_STATIC is passed when testing the static
# variant; a static GUI app must import the platform plugin and suppress the
# comsupp default-lib that WDK7 lacks (the plugin already bundles the symbol).
find_package(Qt5 5.6 REQUIRED COMPONENTS Charts Widgets)

add_executable(chartsmdi WIN32 main.cpp)
target_link_libraries(chartsmdi Qt5::Charts Qt5::Widgets)

if(CONSUME_STATIC)
    target_compile_definitions(chartsmdi PRIVATE NEED_STATIC_QPA)
    target_link_libraries(chartsmdi Qt5::QWindowsIntegrationPlugin)
    target_link_options(chartsmdi PRIVATE /NODEFAULTLIB:comsupp)
endif()
