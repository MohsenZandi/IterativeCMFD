function map = createMap(M,N,MatchList,Locations,siz)
c=mod(siz,2)==0;
mask=getCircleMask(siz);
num_matches=size(MatchList,1);
%Mark Each Match in Map (binary image)
map=false(M,N);
r=floor(siz/2);
if(~isempty(MatchList))
    for i=1:num_matches
        u=MatchList(i,1);
        v=MatchList(i,2);
        x1=Locations(u,1);
        y1=Locations(u,2);
        x2=Locations(v,1);
        y2=Locations(v,2);
        map(y1-r+c:y1+r,x1-r+c:x1+r)=mask|map(y1-r+c:y1+r,x1-r+c:x1+r);
        map(y2-r+c:y2+r,x2-r+c:x2+r)=mask|map(y2-r+c:y2+r,x2-r+c:x2+r);
    end
end
end