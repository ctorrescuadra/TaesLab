function B=divideRow(A,x)
%divideRow - Divide each row of matrix A, by the corresponding element of vector x.
% 	Compute B(i,j)=A(i,j)/x(i)
% 	If x is not provided, the columns of the matrix are scaled by its sum
%
%	Syntax
%		B=divideRow(A,x)
%  	
%	Input Arguments
%		A - Matrix to be scaled
%		x - scale vector (optional)
%  	
%	Output Arguments
%		B - Scaled Matrix 
%   
	if nargin==1
		x=sum(A,2);
	end
	[N,~]=size(A);
	if(N~=length(x))
		error('ERROR: divideRow. Matrix dimensions must agree: %d %d',N,length(x));
	end
	ind=find(x);
    x(ind)=1 ./ x(ind);
    B=scaleRow(A,x);
end