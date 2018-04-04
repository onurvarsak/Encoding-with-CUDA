#include <sys/time.h>
#include <stdlib.h>
#include <stdio.h>
#include <cuda.h>
#include <time.h>

/* using gpu find decode */
__global__ void gpu_find(char** encode, char** decode){
	int index = blockIdx.x * 25 + threadIdx.x;
	if((*encode)[index] == ',')
		(*decode)[index + 1] = (*encode)[index + 1];
}

/* reading encode.txt fike */
void read_file(FILE* file, char** encode){
	char ch;
	int size = 0;
	while((ch = fgetc(file)) != EOF){
		if(ch == '\n' || ch == '\r\n' || ch == '\r')
			continue;
		(*encode)[size++] = ch;
	}
}

/* using cpu find decode */
void cpu_find(char** encode, char** decode, int encode_size){
	int i = 0;
	int decode_size = 0;
	for(i = 0; i < encode_size; i++)
		if((*encode)[i] == ',')
			(*decode)[decode_size++] = (*encode)[i + 1];
}

/* write decode to decode.txt file */
void write_file(FILE* write, char** decode, int decode_size){
	int i = 0;
	for(i = 0; i < decode_size; i++)
		fprintf(write, "%c", (*decode)[i]);
}

int main(int argc, char *argv[]) {
	struct timeval cpu_stop, cpu_start, gpu_stop, gpu_start;
	float cpu_elapsed, gpu_elapsed;
	
	FILE *read	= fopen("encodedfile.txt", "r");
	FILE *write = fopen("decode.txt", "w");
	
	int encode_size = 15360 * 100;
	int decode_size = 15360 * 4;
	
	/* CPU start */ 
	
	char* cpu_encode = (char *)malloc(sizeof(char) * encode_size);
	char* cpu_decode = (char *)malloc(sizeof(char) * decode_size);
	char* gpu_out 	 = (char *)malloc(sizeof(char) * encode_size);
	
	read_file(read, &cpu_encode);
	gettimeofday(&cpu_start, NULL);
	cpu_find(&cpu_encode, &cpu_decode, encode_size);
	gettimeofday(&cpu_stop, NULL);
	
	/* CPU end */
	
	
	
	/* GPU start */
	
	char* gpu_encode;
	char* gpu_decode;
	
	cudaDeviceReset();
	
	cudaMalloc((void **)&gpu_encode, (sizeof(char) * encode_size));
	cudaMalloc((void **)&gpu_decode, (sizeof(char) * encode_size));
	cudaMemcpy(gpu_encode, cpu_encode,(sizeof(char) * encode_size), cudaMemcpyHostToDevice);
	gettimeofday(&gpu_start, NULL);
	gpu_find<<<15360 * 4, 25>>>(&gpu_encode, &gpu_decode);
	gettimeofday(&gpu_stop, NULL);
	cudaMemcpy(gpu_out, gpu_decode, (sizeof(char) * encode_size), cudaMemcpyDeviceToHost);
	
	/* GPU end */ 
	
	cpu_elapsed = (cpu_stop.tv_sec- cpu_start.tv_sec) * 1000.0f + (cpu_stop.tv_usec - cpu_start.tv_usec) / 1000.0f;
	gpu_elapsed = (gpu_stop.tv_sec- gpu_start.tv_sec) * 1000.0f + (gpu_stop.tv_usec - gpu_start.tv_usec) / 1000.0f;
	
	printf("CPU Code executed in %f milliseconds.\n", cpu_elapsed);
	printf("GPU Code executed in %f milliseconds.\n", gpu_elapsed);
	write_file(write, &cpu_decode, decode_size);
	
}
