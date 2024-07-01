function B=divideCol(A,x)
%divideCol - Compute A*inv(diag(x)) = A/diag(x)
%	Divide each colums of matrix A, by the corresponding element of vector x.
% 	If x is not provided, the columns of the matrix are scaled by its sum
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
		error('Matrix dimensions must agree: %d %d',M,length(x));
	end
    x(x~=0)=1./x(x~=0);
    B=scaleCol(A,x);
end