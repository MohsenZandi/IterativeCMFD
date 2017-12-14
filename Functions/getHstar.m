%With help of Amir Tahmasbi Code ( Zernike Moments): http://www.utdallas.edu/~a.tahmasbi/research.html
function result=getHstar(n,l,siz)

N = siz;
x = 1:N; y = x;
[X,Y] = meshgrid(x,y);
R = sqrt((2.*X-N-1).^2+(2.*Y-N-1).^2)/N;
Theta=atan2(2.*Y-N-1,2.*X-N-1);

mask=(R<=1);
result=omega(n)*mask.*cos(pi*n*R.^2).*exp(-1i*l*Theta);
end