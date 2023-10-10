function B=divideCol(A,x)
% divideCol computes A*inv(diag(x)) = A/diag(x)
% 	Divide each colums of matrix A, by the corresponding element of vector x.
% 	If x is not provided, the columns of the matrix are scaled by its sum
%	USAGE:
%		B=divideCol(A,x)
%  	INPUT:
%		A - Matrix to be scaled
%		x - scale vector (optional)
%  	OUTPUT:
%		B - Scaled Matrix 
%   
	log=cStatus(cType.VALID);
	B=[];
	if nargin==1
		x=sum(A,1);
	end
	[~,M]=size(A);
	if(M~=length(x))
		log.printError('Matrix dimensions must agree: %d %d',M,length(x));
		return
	end
    x(x~=0)=1./x(x~=0);
    B=scaleCol(A,x);
end