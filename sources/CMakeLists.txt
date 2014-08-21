cmake_minimum_required(VERSION 2.6)

#Configuration du projet
project(Rffi)

set(R_INCLUDE_DIR "default value" CACHE PATH "dir containing R.h")
set(R_LIB_DIR "default value" CACHE PATH "dir containing libR.{so|dll|dylib}")
set(LIBRARY_OUTPUT_PATH lib/${CMAKE_BUILD_TYPE})

#Inclusion des en-têtes publics
include_directories(${R_INCLUDE_DIR})
link_directories(${R_LIB_DIR})


#Configuration de la bibliothèque
file(
	GLOB_RECURSE
	source_files
	src/*
	include/*
)
add_library(
	Rffi
	SHARED
	${source_files}
)

target_link_libraries(
        Rffi
        R
)