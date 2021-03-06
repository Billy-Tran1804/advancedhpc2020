#include <stdio.h>
#include <include/labwork.h>
#include <cuda_runtime_api.h>
#include <omp.h>

#define ACTIVE_THREADS 4

int main(int argc, char **argv) {
    printf("USTH ICT Master 2018, Advanced Programming for HPC.\n");
    if (argc < 2) {
        printf("Usage: labwork <lwNum> <inputImage>\n");
        printf("   lwNum        labwork number\n");
        printf("   inputImage   the input file name, in JPEG format\n");
        return 0;
    }

    int lwNum = atoi(argv[1]);
    std::string inputFilename;

    // pre-initialize CUDA to avoid incorrect profiling
    printf("Warming up...\n");
    char *temp;
    cudaMalloc(&temp, 1024);

    Labwork labwork;
    if (lwNum != 2 ) {
        inputFilename = std::string(argv[2]);
        labwork.loadInputImage(inputFilename);
    }

    printf("Starting labwork %d\n", lwNum);
    Timer timer;
    timer.start();
    switch (lwNum) {
        case 1:
            labwork.labwork1_CPU();
            labwork.saveOutputImage("labwork2-cpu-out.jpg");
            printf("labwork 1 CPU ellapsed %.1fms\n", lwNum, timer.getElapsedTimeInMilliSec());
            timer.start();
            labwork.labwork1_OpenMP();
            labwork.saveOutputImage("labwork2-openmp-out.jpg");
            break;
        case 2:
            labwork.labwork2_GPU();
            break;
        case 3:
            labwork.labwork3_GPU();
            labwork.saveOutputImage("labwork3-gpu-out.jpg");
            break;
        case 4:
            labwork.labwork4_GPU();
            labwork.saveOutputImage("labwork4-gpu-out.jpg");
            break;
        case 5:
            labwork.labwork5_CPU();
            labwork.saveOutputImage("labwork5-cpu-out.jpg");
            labwork.labwork5_GPU();
            labwork.saveOutputImage("labwork5-gpu-out.jpg");
            break;
        case 6:
            labwork.labwork6_GPU();
            labwork.saveOutputImage("labwork6-gpu-out.jpg");
            break;
        case 7:
            labwork.labwork7_GPU();
            printf("[ALGO ONLY] labwork %d ellapsed %.1fms\n", lwNum, timer.getElapsedTimeInMilliSec());
            labwork.saveOutputImage("labwork7-gpu-out.jpg");
            break;
        case 8:
            labwork.labwork8_GPU();
            printf("[ALGO ONLY] labwork %d ellapsed %.1fms\n", lwNum, timer.getElapsedTimeInMilliSec());
            labwork.saveOutputImage("labwork8-gpu-out.jpg");
            break;
        case 9:
            labwork.labwork9_GPU();
            printf("[ALGO ONLY] labwork %d ellapsed %.1fms\n", lwNum, timer.getElapsedTimeInMilliSec());
            labwork.saveOutputImage("labwork9-gpu-out.jpg");
            break;
        case 10:
            labwork.labwork10_GPU();
            printf("[ALGO ONLY] labwork %d ellapsed %.1fms\n", lwNum, timer.getElapsedTimeInMilliSec());
            labwork.saveOutputImage("labwork10-gpu-out.jpg");
            break;
    }
    printf("labwork %d ellapsed %.1fms\n", lwNum, timer.getElapsedTimeInMilliSec());
}

void Labwork::loadInputImage(std::string inputFileName) {
    inputImage = jpegLoader.load(inputFileName);
}

void Labwork::saveOutputImage(std::string outputFileName) {
    jpegLoader.save(outputFileName, outputImage, inputImage->width, inputImage->height, 90);
}

void Labwork::labwork1_CPU() {
    int pixelCount = inputImage->width * inputImage->height;
    outputImage = static_cast<char *>(malloc(pixelCount * 3));
    for (int j = 0; j < 100; j++) {     // let's do it 100 times, otherwise it's too fast!
        for (int i = 0; i < pixelCount; i++) {
            outputImage[i * 3] = (char) (((int) inputImage->buffer[i * 3] + (int) inputImage->buffer[i * 3 + 1] +
                                          (int) inputImage->buffer[i * 3 + 2]) / 3);
            outputImage[i * 3 + 1] = outputImage[i * 3];
            outputImage[i * 3 + 2] = outputImage[i * 3];
        }
    }
}

void Labwork::labwork1_OpenMP() {
    int pixelCount = inputImage->width * inputImage->height;
    outputImage = static_cast<char *>(malloc(pixelCount * 3));
    // do something here
    omp_set_num_threads(threads);
    for (int j = 0; j < 100; j++) {     // let's do it 100 times, otherwise it's too fast!
        # pragma omp parallel for
        for (int i = 0; i < pixelCount; i++) {
            outputImage[i * 3] = (char) (((int) inputImage->buffer[i * 3] + (int) inputImage->buffer[i * 3 + 1] +
                                          (int) inputImage->buffer[i * 3 + 2]) / 3);
            outputImage[i * 3 + 1] = outputImage[i * 3];
            outputImage[i * 3 + 2] = outputImage[i * 3];
        }
    }
}

int getSPcores(cudaDeviceProp devProp) {
    int cores = 0;
    int mp = devProp.multiProcessorCount;
    switch (devProp.major) {
        case 2: // Fermi
            if (devProp.minor == 1) cores = mp * 48;
            else cores = mp * 32;
            break;
        case 3: // Kepler
            cores = mp * 192;
            break;
        case 5: // Maxwell
            cores = mp * 128;
            break;
        case 6: // Pascal
            if (devProp.minor == 1) cores = mp * 128;
            else if (devProp.minor == 0) cores = mp * 64;
            else printf("Unknown device type\n");
            break;
        default:
            printf("Unknown device type\n");
            break;
    }
    return cores;
}

void Labwork::labwork2_GPU() {
    int nDevices = 0;
    // get all devices
    cudaGetDeviceCount(&nDevices);
    printf("Number total of GPU : %d\n\n", nDevices);
    for (int i = 0; i < nDevices; i++){
        // get informations from individual device
        cudaDeviceProp prop;
        cudaGetDeviceProperties(&prop, i);
        // something more here
        printf("GPU name is %d\n", prop.name);
	printf("GPU clock is %d\n", prop.clockRate);
	printf("GPU cores is %d\n", getSPcores(prop));
	printf("  Multiprocessors:         %d\n", prop.multiProcessorCount);
        printf("  Warp size:               %d\n", prop.warpSize);
        printf("  Memory Clock rate (KHz): %d\n", prop.memoryClockRate);
        printf("  Memory Bus width (bits): %d\n", prop.memoryBusWidth); 
    }

}

__global__ void grayscale(uchar3 *input, uchar3 *output) {
	int tid = threadIdx.x + blockIdx.x * blockDim.x;
	output[tid].x = (input[tid].x + input[tid].y +input[tid].z) / 3;
	output[tid].z = output[tid].y = output[tid].x;
	}

void Labwork::labwork3_GPU() {
     // Calculate number of pixels
    int pixelCount = inputImage->width * inputImage->height;
 
    // Allocate CUDA memory
    uchar3 *devInput;
    uchar3 *devOutput;
    cudaMalloc(&devInput, pixelCount *sizeof(uchar3));
    cudaMalloc(&devOutput, pixelCount *sizeof(uchar3));

    // Copy InputImage from CPU (host) to GPU (device)
    cudaMemcpy(devInput, inputImage->buffer, pixelCount * sizeof(uchar3),cudaMemcpyHostToDevice);

    // Processing : launch the kernel
    int blockSize = 1024;
    int numBlock = pixelCount / blockSize;  
    grayscale<<<numBlock, blockSize>>>(devInput, devOutput);

    // Copy CUDA Memory from GPU to CPU
    // allocate memory for the output on the host
    outputImage = static_cast<char *>(malloc(pixelCount * sizeof(uchar3)));  
    cudaMemcpy(outputImage, devOutput, pixelCount * sizeof(uchar3),cudaMemcpyDeviceToHost);   

    // Cleaning
    cudaFree(devInput);
    cudaFree(devOutput);
}

__global__ void grayscaleVer2D(uchar3* input, uchar3* output, int imageWidth, int imageHeight){
    int tidx = threadIdx.x + blockIdx.x * blockDim.x;
    int tidy = threadIdx.y + blockIdx.y * blockDim.y;
    if(tidx >= imageWidth || tidy >= imageHeight) return;
    int tid = tidx + tidy * imageWidth;
    output[tid].x = (input[tid].x + input[tid].y + input[tid].z) / 3;
    output[tid].z = output[tid].y = output[tid].x;
}

void Labwork::labwork4_GPU() {
	// Calculate number of pixels
    int pixelCount = inputImage->width * inputImage->height;

    // // Allocate CUDA memory
    uchar3 *devInput;
    uchar3 *devOutput;
    cudaMalloc(&devInput, pixelCount *sizeof(uchar3));
    cudaMalloc(&devOutput, pixelCount *sizeof(uchar3));

    // // Copy InputImage from CPU (host) to GPU (device)
    cudaMemcpy(devInput, inputImage->buffer, pixelCount * sizeof(uchar3),cudaMemcpyHostToDevice);

    // // Processing : launch the kernel
    // // int blockSize = 1024;
    // // int numBlock = pixelCount / blockSize;  
    // // grayscale<<<numBlock, blockSize>>>(devInput, devOutput);
    dim3 blockSize = dim3(32, 32);
    // //dim3 gridSize = dim3(8, 8);
    dim3 gridSize = dim3((inputImage->width + blockSize.x -1) / blockSize.x, (inputImage->height + blockSize.y -1) / blockSize.y);
    grayscaleVer2D<<<gridSize, blockSize>>>(devInput, devOutput, inputImage->width, inputImage->height);

    // // Copy CUDA Memory from GPU to CPU
    // // allocate memory for the output on the host
    outputImage = static_cast<char *>(malloc(pixelCount * sizeof(uchar3)));  
    cudaMemcpy(outputImage, devOutput, pixelCount * sizeof(uchar3),cudaMemcpyDeviceToHost);   

    // // Cleaning
    cudaFree(devInput);
    cudaFree(devOutput);	
	
}

void Labwork::labwork5_CPU() {
        int w = inputImage->width;
	int h = inputImage->height;                                                                                                                                            
	//convert input image into grayscale
        labwork1_CPU;
        char *grayImage = outputImage;
        int pixelCount = w * h;
        outputImage = static_cast<unsigned char *>(malloc(pixelCount * 3));
        memset(outputImage, 0, pixelCount * 3);
        //let go basic
        int filter[] = {0, 0, 1, 2, 1, 0, 0,
                    0, 3, 13, 22, 13, 3, 0,
                    1, 13, 59, 97, 59, 13, 1,
                    2, 22, 97, 159, 97, 22, 2,
                    1, 13, 59, 97, 59, 13, 1,
                    0, 3, 13, 22, 13, 3, 0,
                    0, 0, 1, 2, 1, 0, 0};
        //let's go
        for(int rows = 3; rows < h - 3; rows++) {
             for (int col = 3; col < w - 3; col++){                                                                                                                                     
		     int sum = 0; // sum is for normalization 
			for(int j=-3; j <= 3; j++){                                                                                                                                                 
			     for(int i=-3; i <= 3; i++) {                                                                                                                    
                        sum += grayImage[((rows + j) * w + col + i) * 3] * filter[(j + 3)* 7 + i + 3];
                        }
                }                                                                                                                                                                       
		     sum /= 1003;                                                                                                                                                          
		     outputImage[(rows * w + col) * 3] = sum; 
		     outputImage[(rows * w + col) * 3 + 1] = sum; 
		     outputImage[(rows * w + col) * 3 + 2] = sum; 
	     }
	}
	
}

// write a blur filter for shared memory
__global__ void blur(uchar3* input, uchar3* output, int* filter, int imageWidth, int imageHeight){
    int tidx = threadIdx.x + blockIdx.x * blockDim.x;
    int tidy = threadIdx.y + blockIdx.y * blockDim.y;
    if(tidx >= imageWidth || tidy >= imageHeight) return;
    int tid = tidx + tidy * imageWidth;

    __shared__ int s[49];
    int localtid = threadIdx.x + threadIdx.y * blockDim.x;
    if (localtid < 49){
        s[localtid] = filter[localtid];
    }
    __syncthreads();

    int sum = 0; // sum is for normalization
    int constant = 0;
    for(int j=-3; j < 3; j++){
        for(int i=-3; i < 3; i++){
            int rows = tidx + i;
            int columns = tidy + j;
            if( rows < 0 || rows >= imageWidth || columns < 0 || columns >= imageHeight) continue;
            int tid = rows + columns * imageWidth;
            unsigned char pixelValue = (input[tid].x + input[tid].y +input[tid].z) / 3;
            int coefficient = s[(j+3)*7+i+3];
            sum += pixelValue*coefficient;
            constant += coefficient;
        }
    }
    sum /= constant;
    output[tid].z = output[tid].y = output[tid].x = sum;
}

void Labwork::labwork5_GPU(bool shared) {
    int filter[] = {0,0,1,2,1,0,0,
                        0,3,13,22,13,3,0,
                        1,13,59,97,59,13,1,
                        2,22,97,159,97,22,2,
                        1,13,59,97,59,13,1,
                        0,3,13,22,13,3,0,
                        0,0,1,2,1,0,0};
    int *share;
    // Calculate number of pixels
    int pixelCount = inputImage->width * inputImage->height;
    
    dim3 blockSize = dim3(32, 32);
    dim3 gridSize = dim3((inputImage->width + blockSize.x -1) / blockSize.x, (inputImage->height + blockSize.y -1) / blockSize.y);

    // Allocate CUDA memory
    uchar3 *devInput;
    uchar3 *devOutput;
    cudaMalloc(&devInput, pixelCount *sizeof(uchar3));
    cudaMalloc(&devOutput, pixelCount *sizeof(uchar3));
    cudaMalloc(&share, sizeof(filter));
    // allocate memory for the output on the host
    outputImage = static_cast<char *>(malloc(pixelCount * sizeof(uchar3)));  

    // Copy InputImage from CPU (host) to GPU (device)
    cudaMemcpy(devInput, inputImage->buffer, pixelCount * sizeof(uchar3),cudaMemcpyHostToDevice);

    // Copy Kernel into shared memory
    cudaMemcpy(share, filter, sizeof(filter), cudaMemcpyHostToDevice);

    blur<<<gridSize, blockSize>>>(devInput, devOutput, share, inputImage->width, inputImage->height);

    // Copy CUDA Memory from GPU to CPU
    cudaMemcpy(outputImage, devOutput, pixelCount * sizeof(uchar3),cudaMemcpyDeviceToHost);   

    // // Cleaning
    cudaFree(devInput);
    cudaFree(devOutput);
    cudaFree(share);
}

__global__ void binarization(uchar3* input, uchar3* output, int imageWidth, int imageHeight, int thresholdValue){
    int tidx = threadIdx.x + blockIdx.x * blockDim.x;
    int tidy = threadIdx.y + blockIdx.y * blockDim.y;
    if(tidx >= imageWidth || tidy >= imageHeight) return;
    int tid = tidx + tidy * imageWidth;
    
    unsigned char binary = (input[tid].x + input[tid].y + input[tid].z) / 3;
    if (binary > thresholdValue){
        binary = 255;
    } else {
        binary = 0;
    }
    output[tid].z = output[tid].y = output[tid].x = binary;
}

__global__ void brightness(uchar3* input, uchar3* output, int imageWidth, int imageHeight, int brightnessValue){
    int tidx = threadIdx.x + blockIdx.x * blockDim.x;
    int tidy = threadIdx.y + blockIdx.y * blockDim.y;
    if(tidx >= imageWidth || tidy >= imageHeight) return;
    int tid = tidx + tidy * imageWidth;
    
    unsigned char binary = (input[tid].x + input[tid].y + input[tid].z) / 3;
    // unsigned char increase = binary + brightnessValue;
    // if (increase > 255){
    //     increase = 255;
    // } else {
    //     increase = 0;
    // }
    binary += brightnessValue;
    output[tid].z = output[tid].y = output[tid].x = binary;

}

__global__ void blending(uchar3* input0, uchar3* input1, uchar3* output, int imageWidth, int imageHeight, float weightValue){
    int tidx = threadIdx.x + blockIdx.x * blockDim.x;
    int tidy = threadIdx.y + blockIdx.y * blockDim.y;
    if(tidx >= imageWidth || tidy >= imageHeight) return;
    int tid = tidx + tidy * imageWidth;

    // unsigned char binary = (input0[tid].x + input0[tid].y + input0[tid].z) / 3;
    // unsigned char binary2 = (input1[tid].x + input1[tid].y + input1[tid].z) / 3;
    // binary = weightValue*binary + (1-weightValue)*binary2;
    float binary = (input0[tid].x + input0[tid].y + input0[tid].z) / 3;
    float binary1 = (input1[tid].x + input1[tid].y + input1[tid].z) / 3;
    float totalbinary = (binary * weightValue) + binary1 * (1 - weightValue);

    output[tid].z = output[tid].y = output[tid].x = totalbinary; 
}


void Labwork::labwork6_GPU() {

    //6A - BINARIZATION
    int threshold;
    printf("Enter the threshold value: ");
    scanf("%d", &threshold);
    

    //6B - BRIGHTNESS CONTROLL
    int bright;
    printf("Enter the threshold value: ");
    scanf("%d", &bright);
    

    // 6C - BLENDING
    char buffer[3];
    printf("Enter the weight: ", buffer);
    scanf("%s", buffer);
    int weightValue = atoi(buffer);
    
    // Calculate number of pixels
    int pixelCount = inputImage->width * inputImage->height;

    // Allocate CUDA memory
    uchar3 *devInput;
    uchar3 *devOutput;
    cudaMalloc(&devInput, pixelCount *sizeof(uchar3));
    cudaMalloc(&devOutput, pixelCount *sizeof(uchar3));

    // Copy InputImage from CPU (host) to GPU (device)
    cudaMemcpy(devInput, inputImage->buffer, pixelCount * sizeof(uchar3),cudaMemcpyHostToDevice);

    dim3 blockSize = dim3(32, 32);
    // //dim3 gridSize = dim3(8, 8);
    dim3 gridSize = dim3((inputImage->width + blockSize.x -1) / blockSize.x, (inputImage->height + blockSize.y -1) / blockSize.y);

    // 6A - BINARIZATION
    binarization<<<gridSize, blockSize>>>(devInput, devOutput, inputImage->width, inputImage->height, threshold);
    // 6B - BRIGHTNESS CONTROLL
    brightness<<<gridSize, blockSize>>>(devInput, devOutput, inputImage->width, inputImage->height, bright);
    // 6C - BLENDING
    blending<<<gridSize, blockSize>>>(devInput, devInput, devOutput, inputImage->width, inputImage->height, weightValue);

    // Copy CUDA Memory from GPU to CPU
    // allocate memory for the output on the host
    outputImage = static_cast<char *>(malloc(pixelCount * sizeof(uchar3)));  
    cudaMemcpy(outputImage, devOutput, pixelCount * sizeof(uchar3),cudaMemcpyDeviceToHost);   

    // Cleaning
    cudaFree(devInput);
    cudaFree(devOutput);
}

void Labwork::labwork7_GPU() {
}

void Labwork::labwork8_GPU() {
}

void Labwork::labwork9_GPU() {

}

void Labwork::labwork10_GPU(){
}


























