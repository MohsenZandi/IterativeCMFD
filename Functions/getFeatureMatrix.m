function [FeatureMatrix,StandardDeviations]=getFeatureMatrix(grayimage,B,Margin)
PCT_params=[0    0;...%Table of N, L parameters
       0	1;...
       0	2;...
       1	0;...
       1	1;...
       1    2;...
       2    0;...
       2    1];
FVsize=size(PCT_params,1)+1;%+1 for phase
grayimage=double(grayimage);
FeatureImage=zeros([size(grayimage),FVsize]);
for k=1:FVsize-1
        hStar=getHstar(PCT_params(k,1),PCT_params(k,2),B);
        FeatureImage(:,:,k)=imfilter(grayimage,hStar);
end
%double_image=double(grayimage);
SDImage=stdfilt(grayimage,getCircleMask(B+1)); %Image Containing Standard Deviations (Approximately correct)
% SDImage=zeros(size(grayimage));%
% for i=Margin:size(SDImage,1)-Margin
%     for j=Margin:size(SDImage,2)-Margin
%         block=grayimage(i-B/2+1:i+B/2,j-B/2+1:j+B/2);
%         SDImage(i,j)=std(block(:),1);
%     end
% end
%remove borders
SDImage = SDImage(Margin+1:(end-Margin-1),Margin+1:(end-Margin-1)); 
FeatureImage = FeatureImage(Margin+1:(end-Margin-1),Margin+1:(end-Margin-1),:); 
%Reshape into a feature matrix
FeatureMatrix=reshape(FeatureImage,[size(FeatureImage,1)*size(FeatureImage,2),size(FeatureImage,3)]);
FeatureMatrix(:,end)=angle(FeatureMatrix(:,2))*180/pi;
FeatureMatrix(:,1:end-1)=abs(FeatureMatrix(:,1:end-1));
StandardDeviations=SDImage(:);