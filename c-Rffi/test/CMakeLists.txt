cmake_minimum_required(VERSION 2.6)

#Configuration du projet
project(TestR2rb)
set(EXECUTABLE_OUTPUT_PATH ${CMAKE_BUILD_TYPE})

#Inclusion de la bibliothèque Hello
include_directories(../include)
link_directories(../lib/${CMAKE_BUILD_TYPE})

#Configuration de l'exécutable
file(
	GLOB_RECURSE
	source_files
	testR2rb.c
)
add_executable(
	testR2rb
	${source_files}
)

#Configuration de l'édition de liens
target_link_libraries(
	testR2rb
	R2rb
)