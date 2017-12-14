function [Keypoint_Indices,Selection_Mask]=getKeypointLocations(Uniqueness,Locations,M,N,params)
%Gaussian Neighborhood Weight Function
r=floor(params.B/2);
[x,y]=meshgrid(-r:r,-r:r);
f=exp(-(x.^2+y.^2)/(2*(params.sigma^2)));
%Detecting Keypoints
[isSelected,Selection_Mask]=Keypoint_Detector(Uniqueness,Locations',M,N,size(f,1),-1,f,params.gamma);
Keypoint_Indices=uint32(find(isSelected));