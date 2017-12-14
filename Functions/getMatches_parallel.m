function MatchList=getMatches_parallel(FeatureMatrix,Keypoint_Indices,Full_Locations,StandardDeviations,iteration,AffineTransforms,Orientation,params)
%% Initialize
if ~isempty(AffineTransforms)
    AffineTransformsList=zeros(size(AffineTransforms,3)*3,3);
    for i=1:size(AffineTransforms,3)
        AffineTransformsList((i-1)*3+1:(i-1)*3+3,1:3)= AffineTransforms(:,:,i);
    end
else
    AffineTransformsList=[];
end
%% Lexicographic Sorting
[FeatureMatrix,index]=sortrows(FeatureMatrix);%Lexicographic Sorting
Keypoint_Indices=Keypoint_Indices(index);%Rearrange
StandardDeviations=StandardDeviations(index);%Rearrange
%% Parallel Matching
if size(FeatureMatrix,1)<2*params.T_search*params.Num_Parallel_Unit;
    params.Num_Parallel_Unit=1;
end
%Divide Data into Multiple Overlapped Parts for Parallel Matching
FeatureMatrix=[FeatureMatrix;...
    inf(params.T_search,size(FeatureMatrix,2))];
StandardDeviations=[StandardDeviations;
    zeros(params.T_search,1)];
Keypoint_Indices=[Keypoint_Indices;
    ones(params.T_search,1)];

[num_keypoints,FVsize]=size(FeatureMatrix);
num_part=params.Num_Parallel_Unit;
part_size=floor(num_keypoints/num_part);
residue_size=mod(num_keypoints,num_part);
overlap_size=params.T_search;
parts=[repmat(part_size,1,num_part-1),part_size+residue_size];
sub_FeatureMatrix=mat2cell(FeatureMatrix,parts);%Without Overlap
sub_StandardDeviations=mat2cell(StandardDeviations,parts);%Without Overlap
overlap_FeatureMatrix=[cellfun(@(x) x(1:min(overlap_size,size(x,1)),:),sub_FeatureMatrix(2:end),'UniformOutput',false); {[]} ];
overlap_StandardDeviations=[cellfun(@(x) x(1:min(overlap_size,size(x,1)),:),sub_StandardDeviations(2:end),'UniformOutput',false); {[]} ];
sub_FeatureMatrix=cellfun(@(x,y) [x;y],sub_FeatureMatrix,overlap_FeatureMatrix,'UniformOutput',false);
sub_StandardDeviations=cellfun(@(x,y) [x;y],sub_StandardDeviations,overlap_StandardDeviations,'UniformOutput',false);
%Start Matching Processes
MatchingResult=cell(params.Num_Parallel_Unit,1);
parfor p=1:params.Num_Parallel_Unit
    MatchingResult{p}=getMatches(sub_FeatureMatrix{p},Keypoint_Indices,Full_Locations,sub_StandardDeviations{p},iteration,...
                                                        AffineTransformsList,Orientation,(p-1)*(part_size)+1,params);
end
MatchList=cell2mat(MatchingResult);
end