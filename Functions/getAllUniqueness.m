function [Uniqueness_List,Full_Locations,Uniqueness_Map,Margin] = getAllUniqueness( grayimage ,B,Margin)
%get uniqueness of all the blocks
filter=fspecial('laplacian');
temp=imfilter(double(grayimage),filter);
temp=temp.^2;
mask=getCircleMask(B);
sum_filter=mask/sum(mask(:));
temp=imfilter(temp,sum_filter);
temp=sqrt(temp);
Uniqueness_Map=temp;
[M ,N]=size(grayimage);
Selection_Mask=true(M,N);
Selection_Mask(1:Margin,:)=0;
Selection_Mask(:,1:Margin)=0;
Selection_Mask(end-Margin:end,:)=0;
Selection_Mask(:,end-Margin:end)=0;
Uniqueness_List=Uniqueness_Map(Selection_Mask(:));
[y,x]=find(Selection_Mask);
Full_Locations=[x,y];