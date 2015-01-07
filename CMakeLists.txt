cmake_minimum_required(VERSION 2.8)
project( dct_data_verification )


find_package( OpenCV REQUIRED )

find_package(Boost REQUIRED  
   COMPONENTS program_options filesystem system thread regex
)

find_package(CUDA REQUIRED )

include_directories(
#"/home/levin/projects/pedestrian/doppia/libs/cudatemplates/include"
"/usr/local/cuda-6.5/samples/common/inc"
#"/home/levin/projects/pedestrian/doppia/libs/cudatemplates/include/cudatemplates/auto"
)

# build cuda library                                                                                                                                                                                             
file(GLOB SrcCuda
  "./src/*.cu"
)
CUDA_ADD_LIBRARY(cuda_stuff_library ${SrcCuda})
target_link_libraries(cuda_stuff_library
   ${CUDA_LIBRARIES}
)


#build executable
add_executable( dct_data_verification ./src/main.cpp)
target_link_libraries( dct_data_verification ${OpenCV_LIBS}  cuda_stuff_library ${Boost_LIBRARIES} )


#show relevant messages
message("SrcCuda: ${SrcCuda}")
#message("Boost_LIBRARY_DIRS: ${Boost_LIBRARY_DIRS}")
#message("Boost_INCLUDE_DIRS: ${Boost_INCLUDE_DIRS}")
message("Boost_LIBRARIES: ${Boost_LIBRARIES}")
#message("opencv library linked ${OpenCV_LIBS}")


