#include <opencv2/core/core.hpp>
#include <opencv2/highgui/highgui.hpp>
#include "boost/filesystem.hpp"   // includes all needed Boost.Filesystem declarations
#include <iostream>   // for std::cout
#include <boost/algorithm/string.hpp>
#include <boost/regex.hpp>


#include "boost/multi_array.hpp"
#include <cassert>
#include <iostream>
using namespace cv;
using namespace std;
using namespace boost;

int cudatest ();
int cvtest ();
int mainvectoadd();
int mainvectoadd2();
void testboost(){
	// Create a 3D array that is 3 x 4 x 2
	typedef boost::multi_array<double, 3> array_type;
	typedef array_type::index index;
	array_type A(boost::extents[3][4][2]);

	// Assign values to the elements
	int values = 0;
	for(index i = 0; i != 3; ++i)
		for(index j = 0; j != 4; ++j)
			for(index k = 0; k != 2; ++k)
				A[i][j][k] = values++;

	// Verify values
	int verify = 0;
	for(index i = 0; i != 3; ++i)
		for(index j = 0; j != 4; ++j)
			for(index k = 0; k != 2; ++k)
				assert(A[i][j][k] == verify++);
}
void
demo_plain();
void
demo_cudatemplates();
int validatedctres () ;
int dcttestmain(int argc, char **argv);
int displayimage(){
	Mat image;
	char *pSampleImageFpath = "./data/sample_0.png.png";
	image = imread(pSampleImageFpath, CV_LOAD_IMAGE_COLOR);

	if(! image.data )                              // Check for invalid input
	{
		cout <<  "Could not open or find the image" << std::endl ;
		return -1;
	}

	namedWindow( "Display window", WINDOW_AUTOSIZE );// Create a window for display.
	imshow( "Display window", image );                   // Show our image inside it.

	waitKey(0);                                          // Wait for a keystroke in the window
	return 0;
}
int testregexmain();
int main (int argc, char **argv) {
//	testregexmain();
	//testsplit()
	 dcttestmain(argc, argv);
	//validatedctres ();
	// dcttestmain(argc, argv);
	//cudatest ();
	//	mainvectoadd();
	//cvtest();
	//mainvectoadd2();
	//your_rgba_to_greyscale(0, 0,
	//                            0, 0, 0);
	//	 demo_plain();
	//	  demo_cudatemplates();



	//	Mat image;
	//		char *pSampleImageFpath = "/home/levin/projects/testUbuntDev/testboost/data/sample_0.png.png";
	//
	//		image =  imread(pSampleImageFpath, CV_LOAD_IMAGE_COLOR );
	//		//separate the mat into two parts,
	//		if(! image.data )                              // Check for invalid input
	//		{
	//			cout <<  "Could not open or find the image" << std::endl ;
	//			return -1;
	//		}
	//		namedWindow( "Display window", WINDOW_AUTOSIZE );// Create a window for display.
	//		imshow( "Display window", image );                   // Show our image inside it.
	//		waitKey(0);

	//displayimage();

	//displayimage(argc, argv);


	//	int ImgWidth, ImgHeight;
	//	//char *pSampleImageFpath = "./data/sample_0.png.png";
	return 0;
}


