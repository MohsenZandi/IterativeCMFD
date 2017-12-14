function [map,UltimateResult,time]=DetectCopyMove(filename)
% As it is mentioned in License.txt, this code is only for non-commercial
% usages.
% if you use this implementation, please cite the following paper:
% M. Zandi, A. Mahmoudi-Aznaveh and A. Talebpour, "Iterative Copy-Move Forgery Detection Based on a New Interest Point Detector,"
% in IEEE Transactions on Information Forensics and Security, vol. 11, no. 11, pp. 2499-2512, Nov. 2016.

% Please run vl_setup.m first to add path vlfeat library
% run "matlabpool open" to gain more speed up by parallel toolbox!
%% initilization
RGBimage=imread(filename); %Reading Image
grayimage=rgb2gray(RGBimage); %convert RGB to gray
[M ,N]=size(grayimage);

KeypointParams.B=12+ceil(sqrt(M*N)/100); %Block Dimension = B x B
if mod(KeypointParams.B,2)~=0 %Make B even
    KeypointParams.B=KeypointParams.B+1;
end
KeypointParams.gamma=ones(M,N)/20*(1+0.00135*sqrt(M*N));% initial Certainty Level (gamma) for each pixel
KeypointParams.sigma=sqrt((KeypointParams.B)/6);

MatchingParams.alpha=KeypointParams.B^2/35;
MatchingParams.beta=1;
MatchingParams.T_search=100;
MatchingParams.T_distance=KeypointParams.B;
MatchingParams.init_matchlist_size=1000000;
MatchingParams.Num_Parallel_Unit=4;

FilteringParams.T_theta=3;
FilteringParams.T_s=0.03;
FilteringParams.T_g=3;
FilteringParams.T_inliers=3;
FilteringParams.REGIONSIZE=round(0.1*sqrt(M*N));
FilteringParams.REGULARIZER=1;

IterativeParams.lambda_c_gamma=50;
IterativeParams.lambda_f_gamma=0.1;
IterativeParams.lambda_alpha=1.01;
IterativeParams.lambda_beta=1.01;
IterativeParams.T_ex=KeypointParams.B;
IterativeParams.num_iter=4;

%Initial Variables
map=false(M,N);
Affine_Transforms=[];
Orientations=[];
MarkColor=[255,0,0];
tic;%Save Start Time
%% Proposed Method
Margin=floor(KeypointParams.B/2);
[Uniqueness_List,Full_Locations]=getAllUniqueness(grayimage,KeypointParams.B,Margin);%Uniqueness Calculation for All Blocks
%precomputing all block features (better way in Matlab)
[FeatureMatrix_Full,StandardDeviations_Full]=getFeatureMatrix(grayimage,KeypointParams.B,Margin);%Extract Features for Each Keypoint
%Sorting
[Uniqueness_List,index]=sortrows(Uniqueness_List,-1);%Sort in Descending Order
Full_Locations=Full_Locations(index,:);
FeatureMatrix_Full=FeatureMatrix_Full(index,:);
StandardDeviations_Full=StandardDeviations_Full(index);
%Iterative Detection
for iteration=1:IterativeParams.num_iter
    %Detect Keypoints and Extract Features
    Keypoint_Indices=getKeypointLocations(Uniqueness_List,Full_Locations,M,N,KeypointParams);
    FeatureMatrix=FeatureMatrix_Full(Keypoint_Indices,:);
    StandardDeviations=StandardDeviations_Full(Keypoint_Indices);
    %Matching (finding similar keypoints)
    MatchList=getMatches_parallel(FeatureMatrix,Keypoint_Indices,[Full_Locations,ones(size(Full_Locations,1),1)],StandardDeviations,iteration,Affine_Transforms,Orientations,MatchingParams);
    if isempty(MatchList) && iteration~=1
        continue;
    end
    %Filtering
    if iteration==1  %filtering in the next iterations will be done in the Matching Module
        [MatchList,Affine_Transforms,Orientations]=Filtering(MatchList,Full_Locations,RGBimage,FilteringParams);
    end
    %Update Prior Knowledge
    map_new=createMap(M,N,MatchList,Full_Locations,KeypointParams.B);
    map=map | map_new;
    KeypointParams.gamma=UpdateCapacity(map,IterativeParams.lambda_c_gamma,KeypointParams.B,IterativeParams.T_ex);
    MatchingParams.alpha=IterativeParams.lambda_alpha*MatchingParams.alpha;
    MatchingParams.beta=IterativeParams.lambda_beta*MatchingParams.beta;
end
UltimateResult=map2RGB(map,RGBimage,MarkColor);%Mark the map on the image
time=toc;%Calculate Elapsed Time