function circle=getCircleMask(siz)
% circle=false(B,B);
N = siz;
x = 1:N; y = x;
[X,Y] = meshgrid(x,y);
R = sqrt((2.*X-N-1).^2+(2.*Y-N-1).^2)/N;
circle=(R<=1);
end