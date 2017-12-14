function [MatchList_new,AffineTransforms,Orientations]=Filtering(MatchList,Locations,RGBimage,params)
%%Segmentation
segmentation_map=vl_slic(im2single(RGBimage),params.REGIONSIZE,params.REGULARIZER);
segmentation_map=segmentation_map+1;%+1 is for starting the segments indices from 1 instead of 0
num_segments=max(segmentation_map(:));
%% Coarse Removal
Match_Loc=[Locations(MatchList(:,1),:),Locations(MatchList(:,2),:)];
Match_Seg=getMatchSegments(Match_Loc,segmentation_map);
%Regularize Matches
MatchList_new=MatchList;
index=Match_Seg(:,1)>Match_Seg(:,2);
MatchList_new(index,:)=MatchList(index,[2,1,3,4]);
Match_Loc(index,:)=Match_Loc(index,[3,4,1,2]);
Match_Seg(index,:)=Match_Seg(index,[2,1]);
%Remove Segment Pairs which have low number of Matches
[selected_matches,segment_pairs]=RemoveSparseSegmentPairs(Match_Seg,3,num_segments);
Match_Loc=Match_Loc(selected_matches,:);
Match_Seg=Match_Seg(selected_matches,:);
MatchList_new=MatchList_new(selected_matches,:);
%Init Variables
num_pair_seg=size(segment_pairs,1);
AffineTransforms=zeros(3,3,num_pair_seg*181);
Orientations=zeros(num_pair_seg*181,1);
num=0;%counter
num_matches=size(MatchList_new,1);
selected=false(num_matches,1);
%% Remove based on Affine and theta
gte = vision.GeometricTransformEstimator('NumRandomSamplings',100);%Affine Estimator object
for theta=0:180 %For each alpha
    %Find Affine Between each Match of Segments using their matches
    i1=find(abs(MatchList_new(:,3)-theta)<params.T_theta);
    if isempty(i1)
        continue;
    end
    [i2,seg_pairs]=RemoveSparseSegmentPairs(Match_Seg(i1,:),3,num_segments);
    num_pair_seg=size(seg_pairs,1);
    i3=i1(i2);
    alpha_Match_Loc=Match_Loc(i3,:);
    alpha_Match_Seg=Match_Seg(i3,:);
    for pairs=1:num_pair_seg
        i4=find(alpha_Match_Seg(:,1)==seg_pairs(pairs,1) & alpha_Match_Seg(:,2)==seg_pairs(pairs,2));
        loc1=alpha_Match_Loc(i4,1:2);
        loc2=alpha_Match_Loc(i4,3:4);
        affine=step(gte,loc1,loc2);%Estimate the affine transform
        affine=[affine,[0;0;1]]';
        %Validate the Estimated Affine
        M=affine(1:2,1:2);
        [u,sig,v]=svd(M);
        S=u*sig*u';
        R=u*v';
        thteaR=acos(max(min(R(1,1),1),-1))*180/pi;
        if(rcond(S)<=1e-10)
            continue;
        end
        sinv=inv(S);
        if norm(eye(2)-sinv(1,1).*S,'fro')>=params.T_s || difference_angular(thteaR,theta)>=params.T_theta
            continue;
        end
        %Concatenate Locations with 1
        num_tempmatches=size(Match_Loc(i3,:),1);
        alpha_loc1=[alpha_Match_Loc(:,1:2),ones(num_tempmatches,1)]';
        alpha_loc2=[alpha_Match_Loc(:,3:4),ones(num_tempmatches,1)]';
        %Generalization Test of the Estimated Affine
        index=i3(NormRow(affine*alpha_loc1-alpha_loc2,1)<=params.T_g | NormRow(affine*alpha_loc2-alpha_loc1,1)<=params.T_g);
        
        if length(index)>=params.T_inliers %If the affine has enough number of matches
            num=num+1;
            selected(index)=1;
            MatchList_new(index,4)=num;
            %Add the affine to affine transformations
            AffineTransforms(:,:,num)=affine;
            Orientations(num)=thteaR;
        end
        
    end
end
%%Trim Results
AffineTransforms=AffineTransforms(:,:,1:num);
Orientations=Orientations(1:num);
MatchList_new=MatchList_new(selected,:);
