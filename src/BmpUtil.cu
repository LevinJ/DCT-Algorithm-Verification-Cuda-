/*
 * Copyright 1993-2014 NVIDIA Corporation.  All rights reserved.
 *
 * Please refer to the NVIDIA end user license agreement (EULA) associated
 * with this source code for terms and conditions that govern your use of
 * this software. Any use, reproduction, disclosure, or distribution of
 * this software and related documentation outside the terms of the EULA
 * is strictly prohibited.
 *
 */

/**
 **************************************************************************
 * \file BmpUtil.cpp
 * \brief Contains basic image operations implementation.
 *
 * This file contains implementation of basic bitmap loading, saving,
 * conversions to different representations and memory management routines.
 */

#include "Common.h"
#include "BmpUtil.h"
#include <opencv2/core/core.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <boost/regex.hpp>

using namespace cv;
using namespace std;
#if defined(WIN32) || defined(_WIN32) || defined(WIN64) || defined(_WIN64)
#pragma warning( disable : 4996 ) // disable deprecated warning 
#endif


/**
 **************************************************************************
 *  The routine clamps the input value to integer byte range [0, 255]
 *
 * \param x          [IN] - Input value
 *
 * \return Pointer to the created plane
 */
int clamp_0_255(int x)
{
	return (x < 0) ? 0 : ((x > 255) ? 255 : x);
}


/**
 **************************************************************************
 *  Float round to nearest value
 *
 * \param num            [IN] - Float value to round
 *
 * \return The closest to the input float integer value
 */
float round_f(float num)
{
	float NumAbs = fabs(num);
	int NumAbsI = (int)(NumAbs + 0.5f);
	float sign = num > 0 ? 1.0f : -1.0f;
	return sign * NumAbsI;
}


/**
 **************************************************************************
 *  Memory allocator, returns aligned format frame with 8bpp pixels.
 *
 * \param width          [IN] - Width of image buffer to be allocated
 * \param height         [IN] - Height of image buffer to be allocated
 * \param pStepBytes     [OUT] - Step between two sequential rows
 *
 * \return Pointer to the created plane
 */
byte *MallocPlaneByte(int width, int height, int *pStepBytes)
{
	byte *ptr;
	*pStepBytes = ((int)ceil(width/16.0f))*16;
	//#ifdef __ALLOW_ALIGNED_MEMORY_MANAGEMENT
	//  ptr = (byte *)_aligned_malloc(*pStepBytes * height, 16);
	//#else
	ptr = (byte *)malloc(*pStepBytes * height);
	//#endif
	return ptr;
}


/**
 **************************************************************************
 *  Memory allocator, returns aligned format frame with 16bpp float pixels.
 *
 * \param width          [IN] - Width of image buffer to be allocated
 * \param height         [IN] - Height of image buffer to be allocated
 * \param pStepBytes     [OUT] - Step between two sequential rows
 *
 * \return Pointer to the created plane
 */
short *MallocPlaneShort(int width, int height, int *pStepBytes)
{
	short *ptr;
	*pStepBytes = ((int)ceil((width*sizeof(short))/16.0f))*16;
	//#ifdef __ALLOW_ALIGNED_MEMORY_MANAGEMENT
	//  ptr = (float *)_aligned_malloc(*pStepBytes * height, 16);
	//#else
	ptr = (short *)malloc(*pStepBytes * height);
	//#endif
	*pStepBytes = *pStepBytes / sizeof(short);
	return ptr;
}


/**
 **************************************************************************
 *  Memory allocator, returns aligned format frame with 32bpp float pixels.
 *
 * \param width          [IN] - Width of image buffer to be allocated
 * \param height         [IN] - Height of image buffer to be allocated
 * \param pStepBytes     [OUT] - Step between two sequential rows
 *
 * \return Pointer to the created plane
 */
float *MallocPlaneFloat(int width, int height, int *pStepBytes)
{
	float *ptr;
	*pStepBytes = ((int)ceil((width*sizeof(float))/16.0f))*16;
	//#ifdef __ALLOW_ALIGNED_MEMORY_MANAGEMENT
	//  ptr = (float *)_aligned_malloc(*pStepBytes * height, 16);
	//#else
	ptr = (float *)malloc(*pStepBytes * height);
	//#endif
	*pStepBytes = *pStepBytes / sizeof(float);
	return ptr;
}


/**
 **************************************************************************
 *  Copies byte plane to float plane
 *
 * \param ImgSrc             [IN] - Source byte plane
 * \param StrideB            [IN] - Source plane stride
 * \param ImgDst             [OUT] - Destination float plane
 * \param StrideF            [IN] - Destination plane stride
 * \param Size               [IN] - Size of area to copy
 *
 * \return None
 */
void CopyByte2Float(byte *ImgSrc, int StrideB, float *ImgDst, int StrideF, ROI Size)
{
	for (int i=0; i<Size.height; i++)
	{
		for (int j=0; j<Size.width; j++)
		{
			ImgDst[i*StrideF+j] = (float)ImgSrc[i*StrideB+j];
		}
	}
}


/**
 **************************************************************************
 *  Copies float plane to byte plane (with clamp)
 *
 * \param ImgSrc             [IN] - Source float plane
 * \param StrideF            [IN] - Source plane stride
 * \param ImgDst             [OUT] - Destination byte plane
 * \param StrideB            [IN] - Destination plane stride
 * \param Size               [IN] - Size of area to copy
 *
 * \return None
 */
void CopyFloat2Byte(float *ImgSrc, int StrideF, byte *ImgDst, int StrideB, ROI Size)
{
	for (int i=0; i<Size.height; i++)
	{
		for (int j=0; j<Size.width; j++)
		{
			ImgDst[i*StrideB+j] = (byte)clamp_0_255((int)(round_f(ImgSrc[i*StrideF+j])));
		}
	}
}


/**
 **************************************************************************
 *  Memory deallocator, deletes aligned format frame.
 *
 * \param ptr            [IN] - Pointer to the plane
 *
 * \return None
 */
void FreePlane(void *ptr)
{
	//#ifdef __ALLOW_ALIGNED_MEMORY_MANAGEMENT
	//  if (ptr)
	//  {
	//      _aligned_free(ptr);
	//  }
	//#else
	if (ptr)
	{
		free(ptr);
	}

	//#endif
}


/**
 **************************************************************************
 *  Performs addition of given value to each pixel in the plane
 *
 * \param Value              [IN] - Value to add
 * \param ImgSrcDst          [IN/OUT] - Source float plane
 * \param StrideF            [IN] - Source plane stride
 * \param Size               [IN] - Size of area to copy
 *
 * \return None
 */
void AddFloatPlane(float Value, float *ImgSrcDst, int StrideF, ROI Size)
{
	for (int i=0; i<Size.height; i++)
	{
		for (int j=0; j<Size.width; j++)
		{
			ImgSrcDst[i*StrideF+j] += Value;
		}
	}
}


/**
 **************************************************************************
 *  Performs multiplication of given value with each pixel in the plane
 *
 * \param Value              [IN] - Value for multiplication
 * \param ImgSrcDst          [IN/OUT] - Source float plane
 * \param StrideF            [IN] - Source plane stride
 * \param Size               [IN] - Size of area to copy
 *
 * \return None
 */
void MulFloatPlane(float Value, float *ImgSrcDst, int StrideF, ROI Size)
{
	for (int i=0; i<Size.height; i++)
	{
		for (int j=0; j<Size.width; j++)
		{
			ImgSrcDst[i*StrideF+j] *= Value;
		}
	}
}


/**
 **************************************************************************
 *  This function performs acquisition of image dimensions
 *
 * \param FileName       [IN] - Image name to load
 * \param Width          [OUT] - Image width from file header
 * \param Height         [OUT] - Image height from file header
 *
 * \return Status code
 */
int PreLoadBmp(char *FileName, int *Width, int *Height)
{
	BMPFileHeader FileHeader;
	BMPInfoHeader InfoHeader;
	FILE *fh;

	if (!(fh = fopen(FileName, "rb")))
	{
		return 1; //invalid filename
	}

	fread(&FileHeader, sizeof(BMPFileHeader), 1, fh);

	if (FileHeader._bm_signature != 0x4D42)
	{
		return 2; //invalid file format
	}

	fread(&InfoHeader, sizeof(BMPInfoHeader), 1, fh);

	if (InfoHeader._bm_color_depth != 24)
	{
		return 3; //invalid color depth
	}

	if (InfoHeader._bm_compressed)
	{
		return 4; //invalid compression property
	}

	*Width  = InfoHeader._bm_image_width;
	*Height = InfoHeader._bm_image_height;

	fclose(fh);
	return 0;
}

int PreLoadBmp2(char *FileName, int *Width, int *Height)
{
	Mat img =  imread(FileName, IMREAD_GRAYSCALE );
	*Width  = img.cols;
	*Height = img.rows;
	return 0;
}


/**
 **************************************************************************
 *  This function performs loading of bitmap luma
 *
 * \param FileName       [IN] - Image name to load
 * \param Stride         [IN] - Image stride
 * \param ImSize         [IN] - Image size
 * \param Img            [OUT] - Prepared buffer
 *
 * \return None
 */
void LoadBmpAsGray(char *FileName, int Stride, ROI ImSize, byte *Img)
{
	BMPFileHeader FileHeader;
	BMPInfoHeader InfoHeader;
	FILE *fh;
	fh = fopen(FileName, "rb");

	fread(&FileHeader, sizeof(BMPFileHeader), 1, fh);
	fread(&InfoHeader, sizeof(BMPInfoHeader), 1, fh);

	for (int i=ImSize.height-1; i>=0; i--)
	{
		for (int j=0; j<ImSize.width; j++)
		{
			int r=0, g=0, b=0;
			fread(&b, 1, 1, fh);
			fread(&g, 1, 1, fh);
			fread(&r, 1, 1, fh);
			int val = (313524*r + 615514*g + 119537*b + 524288) >> 20 ;
			Img[i*Stride+j] = (byte)clamp_0_255(val);
		}
	}

	fclose(fh);
	return;
}
int getvalueatxyposition(string text){
	const char* pattern ="^x=(.*),y=(.*), value = (.*)";
	boost::regex ip_regex(pattern);
	boost::sregex_iterator it(text.begin(), text.end(), ip_regex);
	boost::sregex_iterator end;
	for (; it != end; ++it) {
		string s=(*it)[3];
		return atoi(s.c_str());
	}
	printf("!!!errror in file!!!!\n");
	throw 21;
	return -1;
}
void LoadBmpAsGray4(const char *FileName, int Stride, ROI ImSize, byte *Img)
{
	std::ifstream textfile(FileName);
	if(!textfile){
		printf("can't locate the file %s \n", FileName);
		throw 20;
	}
	std::string str;
	for (int y= 0; y< ImSize.height; y++)
	{
		for(int x=0; x< ImSize.width; x++){
			getline(textfile, str);
			Img[y*Stride+x] = getvalueatxyposition(str);
		}

	}
	textfile.close();
}

void LoadBmpAsGray2(char *FileName, int Stride, ROI ImSize, byte *Img)
{

	Mat img =  imread(FileName, CV_LOAD_IMAGE_UNCHANGED );
	int strideMat = img.step[0];
	for (int y= 0; y< ImSize.height; y++)
	{
		const int16_t* prow = img.ptr<int16_t>(y);
		for (int x=0; x<ImSize.width; x++)
		{
			if(x==72 && y == 1352){
				printf("vow");
			}
			int16_t val = prow[x];
			val = (val>>8) | (val<<8);
			Img[y*Stride+x] = val;
			//     printf("%d,", val);
		}
		// printf(";;;\n");
	}


	return;
}

void LoadBmpAsGray3(char *FileName, int Stride, ROI ImSize, float *Img)
{

	Mat img =  imread(FileName, CV_LOAD_IMAGE_UNCHANGED );
	int strideMat = img.step[0];
	int min=0,max=0;
	for (int y=0; y< ImSize.height-1; y++)
	{
		const int16_t* prow = img.ptr<int16_t>(y);
		for (int x=0; x<ImSize.width; x++)
		{
			int16_t val = prow[x];
			val = (val>>8) | (val<<8);
			Img[y*Stride+x] = val;
			//            if(val!=0){
			//            	printf("x=%d,y=%d, dct value = %d \n", x,y,val);
			//            }
			if(val<min){
				min = val;
			}
			if(val>max){
				max = val;
			}
		}
	}
	printf("\ndoppia min=%d,max=%d\n", min, max);


	return;
}


/**
 **************************************************************************
 *  This function performs dumping of bitmap luma on HDD
 *
 * \param FileName       [OUT] - Image name to dump to
 * \param Img            [IN] - Image luma to dump
 * \param Stride         [IN] - Image stride
 * \param ImSize         [IN] - Image size
 *
 * \return None
 */
void DumpBmpAsGray(char *FileName, byte *Img, int Stride, ROI ImSize)
{
	FILE *fp = NULL;
	fp = fopen(FileName, "wb");

	if (fp == NULL)
	{
		return;
	}

	BMPFileHeader FileHeader;
	BMPInfoHeader InfoHeader;

	//init headers
	FileHeader._bm_signature = 0x4D42;
	FileHeader._bm_file_size = 54 + 3 * ImSize.width * ImSize.height;
	FileHeader._bm_reserved = 0;
	FileHeader._bm_bitmap_data = 0x36;
	InfoHeader._bm_bitmap_size = 0;
	InfoHeader._bm_color_depth = 24;
	InfoHeader._bm_compressed = 0;
	InfoHeader._bm_hor_resolution = 0;
	InfoHeader._bm_image_height = ImSize.height;
	InfoHeader._bm_image_width = ImSize.width;
	InfoHeader._bm_info_header_size = 40;
	InfoHeader._bm_num_colors_used = 0;
	InfoHeader._bm_num_important_colors = 0;
	InfoHeader._bm_num_of_planes = 1;
	InfoHeader._bm_ver_resolution = 0;

	fwrite(&FileHeader, sizeof(BMPFileHeader), 1, fp);
	fwrite(&InfoHeader, sizeof(BMPInfoHeader), 1, fp);

	for (int i = ImSize.height - 1; i>=0; i--)
	{
		for (int j=0; j<ImSize.width; j++)
		{
			fwrite(&(Img[i*Stride+j]), 1, 1, fp);
			fwrite(&(Img[i*Stride+j]), 1, 1, fp);
			fwrite(&(Img[i*Stride+j]), 1, 1, fp);
		}
	}

	fclose(fp);
}


/**
 **************************************************************************
 *  This function performs dumping of 8x8 block from float plane
 *
 * \param PlaneF         [IN] - Image plane
 * \param StrideF        [IN] - Image stride
 * \param Fname          [OUT] - File name to dump to
 *
 * \return None
 */
void DumpBlockF(float *PlaneF, int StrideF, char *Fname)
{
	FILE *fp = fopen(Fname, "wb");

	for (int i=0; i<8; i++)
	{
		for (int j=0; j<8; j++)
		{
			fprintf(fp, "%.*f  ", 14, PlaneF[i*StrideF+j]);
		}

		fprintf(fp, "\n");
	}

	fclose(fp);
}


/**
 **************************************************************************
 *  This function performs dumping of 8x8 block from byte plane
 *
 * \param Plane          [IN] - Image plane
 * \param Stride         [IN] - Image stride
 * \param Fname          [OUT] - File name to dump to
 *
 * \return None
 */
void DumpBlock(byte *Plane, int Stride, char *Fname)
{
	FILE *fp = fopen(Fname, "wb");

	for (int i=0; i<8; i++)
	{
		for (int j=0; j<8; j++)
		{
			fprintf(fp, "%.3d  ", Plane[i*Stride+j]);
		}

		fprintf(fp, "\n");
	}

	fclose(fp);
}


/**
 **************************************************************************
 *  This function performs evaluation of Mean Square Error between two images
 *
 * \param Img1           [IN] - Image 1
 * \param Img2           [IN] - Image 2
 * \param Stride         [IN] - Image stride
 * \param Size           [IN] - Image size
 *
 * \return Mean Square Error between images
 */
float CalculateMSE(byte *Img1, byte *Img2, int Stride, ROI Size)
{
	uint32 Acc = 0;

	for (int i=0; i<Size.height; i++)
	{
		for (int j=0; j<Size.width; j++)
		{
			int TmpDiff = Img1[i*Stride+j] - Img2[i*Stride+j];
			TmpDiff *= TmpDiff;
			Acc += TmpDiff;
		}
	}

	return ((float)Acc) / (Size.height * Size.width);
}


/**
 **************************************************************************
 *  This function performs evaluation of Peak Signal to Noise Ratio between
 *  two images
 *
 * \param Img1           [IN] - Image 1
 * \param Img2           [IN] - Image 2
 * \param Stride         [IN] - Image stride
 * \param Size           [IN] - Image size
 *
 * \return Peak Signal to Noise Ratio between images
 */
float CalculatePSNR(byte *Img1, byte *Img2, int Stride, ROI Size)
{
	float MSE = CalculateMSE(Img1, Img2, Stride, Size);
	return 10 * log10(255*255 / MSE);
}
