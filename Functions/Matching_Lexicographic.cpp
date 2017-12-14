#include <mex.h>
#include <mat.h>
#include <opencv2\core\core.hpp>
#include <algorithm>
//#include <iostream>

using namespace cv;

Mat AffineList;
double* Orientations;
double angular_th;
double affine_th;
int pre_size;
double alpha;
double beta;
double distance_th;
int search_th;
char test_affine;
int start=0;

Mat mxArray2Mat(const mxArray* input){
	int M=mxGetM(input);
	int N=mxGetN(input);
	double* pr=mxGetPr(input);
	Mat mat(M,N,CV_64F);
	for (int i=0;i<N;i++)
		for (int j=0;j<M;j++)
			mat.at<double>(j,i)=pr[i*M+j];
	return mat;}

mxArray* Mat2mxArray(Mat input)
{
	mxArray* out=mxCreateDoubleMatrix(input.rows,input.cols,mxREAL);
	int M=mxGetM(out);
	int N=mxGetN(out);
	double* pr=mxGetPr(out);
	for (int i=0;i<N;i++)
		for (int j=0;j<M;j++)
			pr[i*M+j]=input.at<double>(j,i);
	return out;
}

Mat LogicalIndexing(Mat input,char* index){
	int sum=0;
	for (int i=0;i<input.rows;i++)
		sum=sum+index[i];
	Mat mat(sum,input.cols,input.type());
	int j=0;
	for (int i=0;i<input.rows;i++)
		if (index[i]==1)
			input.row(i).copyTo(mat.row(j++));

	return mat;
}

char isFar(Mat L1,Mat L2,double distance_Th)
{
	double dist=norm(L1-L2);
	return dist>distance_Th;
}

char isSimilar(Mat FV1,Mat FV2,double threshold){

	double dist=norm(FV1-FV2);
	return dist<=threshold;
}

double getAngularDifference(double phi1,double phi2){
	// -180 <=  phi1,phi2 <= 180
	double r1=abs(phi1-phi2);
	double r2=abs(min(phi1,phi2)+360-max(phi1,phi2));
	return min(r1,r2);
}

int getAffineIndex(Mat Location1,Mat Location2,double differene_phase)
{
	int num_affine=AffineList.rows/3;
	Location1=Location1.t();
	Location2=Location2.t();
	//Range constRange(1,1);
	Mat temp1=AffineList*Location1;
	Mat temp2=AffineList*Location2;
	Mat result(num_affine,1,CV_64F);
	for(int i=0;i<num_affine;i++)
	{
		Range range(i*3,i*3+3);//end of range is exclusive
		result.at<double>(i)=min(norm(temp1.rowRange(range)-Location2),norm(temp2.rowRange(range)-Location1));
	}
	double min;
	double max;
	int index;
	minMaxIdx(result,&min,&max,&index);
	if(min<affine_th && getAngularDifference(Orientations[index],differene_phase)<angular_th)
		return index+1;//+1 because matlab index start from 1
	else
		return -1;
}


Mat Matching(Mat FeatureMatrix,double* phases,int* Keypoint_Indices,Mat Full_Locations, double* Standard_Deviations)
{
	//Assume that the Feature Matrix is sorted
	const Mat temp=Mat(pre_size,4,CV_64F);
	Mat result=Mat(temp);
	int num=0;
	for(int i=0;i<FeatureMatrix.rows - search_th;i++)
	{   
		int i1=Keypoint_Indices[start+i];
		//int search_depth=std::min(FeatureMatrix.rows-i-1,search_th);
		for(int j=i+1;j<=i+ search_th;j++)
		{
			int i2=Keypoint_Indices[start+j];
			if (isFar(Full_Locations.row(i1-1),Full_Locations.row(i2-1),distance_th))
			{ 
				double threshold=alpha/2*(Standard_Deviations[i]+Standard_Deviations[j])+beta;
				if (isSimilar(FeatureMatrix.row(i),FeatureMatrix.row(j),threshold))
				{
					if(num>=result.rows)
							result.push_back(temp);//extend the matchlist
					double differene_phase=getAngularDifference(phases[i],phases[j]);
					//Affine Checking
					int affine_index=0;
					if(test_affine==1)
					{
						affine_index=getAffineIndex(Full_Locations.row(i1-1),Full_Locations.row(i2-1),differene_phase);
						if(affine_index==-1)//no appropriate Affine is found
							continue;
					}
					//Storing Result
					result.at<double>(num,0)=i1;
					result.at<double>(num,1)=i2;
					result.at<double>(num,2)=differene_phase;
					result.at<double>(num,3)=affine_index;
					num++;
				}
			}
		}
	}
	result.pop_back(result.rows-num);
	return result;
}

void mexFunction(int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[]){
	Mat FeatureMatrix=mxArray2Mat(prhs[0]);
	double* phases=mxGetPr(prhs[1]);
	Mat Full_Locations=mxArray2Mat(prhs[3]);
	int* Keypoint_Indices=(int*)mxGetPr(prhs[2]);	
	double* Standard_Deviations=mxGetPr(prhs[4]);
	alpha=mxGetScalar(prhs[5]);
	beta=mxGetScalar(prhs[6]);
	distance_th=mxGetScalar(prhs[7]);
	search_th=mxGetScalar(prhs[8]);
	pre_size=mxGetScalar(prhs[9]);
	AffineList=mxArray2Mat(prhs[10]);
	Orientations=mxGetPr(prhs[11]);
	affine_th=mxGetScalar(prhs[12]);
	angular_th=mxGetScalar(prhs[13]);
	test_affine=mxGetScalar(prhs[14]);
	start=mxGetScalar(prhs[15])-1;

	Mat MatchList=Matching(FeatureMatrix,phases,Keypoint_Indices,Full_Locations,Standard_Deviations);

	plhs[0]=Mat2mxArray(MatchList);

}