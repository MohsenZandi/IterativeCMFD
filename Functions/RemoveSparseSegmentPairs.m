function [selected_matches,seg_pairs] = RemoveSparseSegmentPairs(Match_Seg,min_match,num_segments)
segment_pairs=zeros(num_segments);
num_matches=size(Match_Seg,1);
for u=1:num_matches
    i=Match_Seg(u,1);
    j=Match_Seg(u,2);
    segment_pairs(i,j)=segment_pairs(i,j)+1;
end
%Removing Matches on the same segment == diagon of matrix must be zero
segment_pairs=abs(eye(num_segments)-1).*segment_pairs;
segment_pairs=segment_pairs>=min_match;
selected_matches=false(num_matches,1);
%Selecting Matches which are not in Dominant Segments
for u=1:num_matches
    selected_matches(u)=segment_pairs(Match_Seg(u,1),Match_Seg(u,2));
end
[i,j]=find(segment_pairs);
seg_pairs=[i,j];