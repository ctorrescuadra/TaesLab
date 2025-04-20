function B=divideCol(A,x)
%divideCol - Divide each colums of matrix A, by the corresponding element of vector x.
%   Compute B(i,j)= A(i,j)/x(j)
% 	If x is not provided, the columns of the matrix are divided by its sum
%
%	Syntax
%		B=divideCol(A,x)
%  	
%	Input Arguments
%		A - Matrix to be scaled
%		x - scale vector (optional)
%  	
%	Output Arguments
%		B - Scaled Matrix 
%   
	if nargin==1
		x=sum(A,1);
	end
	[~,M]=size(A);
	if(M~=length(x))
		error('ERROR: divideCol. Matrix dimensions must agree: %d %d',M,length(x));
	end
	ind=find(x);
    x(ind)=1./x(ind);
    B=scaleCol(A,x);
end