# DCT-Algorithm-Verification-Cuda-
A small tool that is used to verify that the DCT8X8 algorithm is correctly implemented in pedestrian detection project .
 

Cuda development toolkit from Nvidia is shipped with a DCT8X8 algorithm code sample. This project uses this implementation as a benchmark implementation.  This work flow of verification is as below:


1. Store our DCT transformation input into a text file “sample_0.png.txt”
2. Store our DCT transformation output into a text file “sample_0.png_dct.txt”
3. Modify the Cuda development toolkit DCT implementation accordingly so that it can take input data from text file “sample_0.png.txt”, and output its DCT transformation result into text file “std_dctvalues_transformed.txt”
4. Verify that our DCT is correclty implemented by comparing the two output file “sample_0.png_dct.txt”” and “std_dctvalues_transformed.txt”.