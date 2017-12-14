function Match_Seg = getMatchSegments( Match_Loc,segmentation_map )
%Get the Pair Segments of Pair Matches
num_matches=size(Match_Loc,1);
Match_Seg=zeros(num_matches,2);
for u=1:num_matches
    i=segmentation_map(Match_Loc(u,2),Match_Loc(u,1));
    j=segmentation_map(Match_Loc(u,4),Match_Loc(u,3));
    Match_Seg(u,:)=[i,j];
end