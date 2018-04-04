make: encode.cu
	nvcc -arch=sm_30 -o encode encode.cu
	./encode