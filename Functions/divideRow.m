function B=divideRow(A,x)
% divideRow computes inv(diag(x))*A = diag(x)\A
% 	Divide each row of matrix A, by the corresponding element of vector x.
% 	If x is not provided, the columns of the matrix are scaled by its sum
%	USAGE:
%		B=divideRow(A,x)
%  	INPUT:
%		A - Matrix to be scaled
%		x - scale vector (optional)
%  	OUTPUT:
%		B - Scaled Matrix 
%
	if nargin==1
		x=sum(A,2);
	end
	[N,~]=size(A);
	if(N~=length(x))
		error('Matrix dimensions must agree: %d %d',N,length(x));
	end
    x(x~=0)=1./x(x~=0);
    B=scaleRow(A,x);
end