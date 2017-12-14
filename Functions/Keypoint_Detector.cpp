#include <opencv2\core\core.hpp>
#include <opencv2\highgui\highgui.hpp>
#include "mex.h"
using namespace cv;

double getDensity(Mat detection_map,Point point);
double getCapacity(double interestingness,double certainty_level);


Rect density_window;
Point offset;
Mat Density_Weights;
char* getKeypointLocations(double* Interestingness_List,double* Locations,int M,int N,int W2,int siz,double min_interestingness,Mat Capacity_Multipliers,Mat &map)
{
	//find locations of keypoints
	//assume that the list is sorted
	char* selected=new char[siz];
	unsigned int x,y=0;
	for(unsigned int i=0; i<siz; i++)
	{//mexPrintf("i=%d, ",i);
		if (Interestingness_List[i]>=min_interestingness)
		{
			x=Locations[2*i]-1;//-1 is nessecary because Locations start from 1 but Mat start from 0
			y=Locations[2*i+1]-1;
			double capacity=getCapacity(Interestingness_List[i],Capacity_Multipliers.at<double>(y,x));
			if (capacity<0)
				continue;

			Point c=Point(x,y);
			double density=getDensity(map,c);
			//mexPrintf("x=%d,y=%d\n",x,y);

			if (density<=capacity)
			{
				map.at<char>(y,x)=1;
				selected[i]=1;
			}
			else {
				selected[i]=0;
			}
		}
		else
		{
			selected[i] = 0;
		}
	}

	return selected;}


double getDensity(Mat detection_map,Point point)
{
	Rect roi=density_window+point-offset;
	Mat temp=Mat(detection_map(roi));
	temp.convertTo(temp,CV_64F);
	Mat mul_temp=Density_Weights.mul(temp);
	double density=cv::sum(mul_temp)[0];
	//mexPrintf("Density=%f\n",density);
	return density;
}

double getCapacity(double interestingness,double certainty_level)
{
	double capacity=interestingness*certainty_level;
	return capacity;
}


void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
	double* Interestingness_List;
	double* Locations;	
	Interestingness_List = mxGetPr(prhs[0]);
	int num_rows=mxGetM(prhs[0]);
	Locations=mxGetPr(prhs[1]);
	int M=mxGetScalar(prhs[2]);
	int N=mxGetScalar(prhs[3]);
	int W2=mxGetScalar(prhs[4]);
	double min_interestingness=mxGetScalar(prhs[5]);
	Density_Weights=Mat(W2,W2,CV_64F,mxGetPr(prhs[6]));
	Mat Capacity_Multipliers=Mat::zeros(M,N,CV_64F);
	double* temp_ptr=mxGetPr(prhs[7]);
	for(int i=0;i<N;i++){
		for (int j=0;j<M;j++)
		{Capacity_Multipliers.at<double>(j,i)=temp_ptr[i*M+j];
		}
	}
	//imshow("Capacity_Multipliers",Capacity_Multipliers);
	//waitKey(0);
	//Density_Weights.data=(uchar*);//////////
	density_window=Rect(0,0,W2,W2);
	offset=Point(W2/2,W2/2);
	//mexPrintAssertion("%f\n",Density_Weights.at<double>(13,13));
	//imshow("Kernel",Density_Weights);
	//waitKey(0);
	Mat selection_map=Mat::zeros(M,N,CV_8U);
	char *selected=getKeypointLocations(Interestingness_List,Locations,M,N,W2,num_rows,min_interestingness,Capacity_Multipliers,selection_map);

	//create output
	plhs[0]=mxCreateLogicalMatrix(num_rows,1);
	char* ptr=(char*)mxGetPr(plhs[0]);
	for(int i=0;i<num_rows;i++){
		ptr[i]=selected[i];
	}

	/* Important Note for Mat which has more than 1 dimension:
	Mat is Rowwise but mxArray is Columnwise,
	consequently the values of Mat should be copied to mxArray correctly*/
	plhs[1]=mxCreateLogicalMatrix(M,N);

	ptr=(char*)mxGetPr(plhs[1]);
	for(int i=0;i<N;i++){
		for (int j=0;j<M;j++)
		{
			ptr[i*M+j]=selection_map.at<char>(j,i);
		}
	}
}