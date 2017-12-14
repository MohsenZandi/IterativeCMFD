function [new_Capacity_Multipliers]=UpdateCapacity2(map,mult,B,extension_siz)
Capacity_Multipliers=ones(size(map));
ero_map=imerode(map,getCircleMask(B+1));
dil_map=imdilate(map,getCircleMask(extension_siz));
dif_map=(dil_map-ero_map)>0;
new_Capacity_Multipliers=Capacity_Multipliers;
new_Capacity_Multipliers(dif_map)=Capacity_Multipliers(dif_map)*mult;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
new_Capacity_Multipliers(~dif_map)=-eps*Capacity_Multipliers(~dif_map);%new_Capacity_Multipliers(~map)/mult-eps;