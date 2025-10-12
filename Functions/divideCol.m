function B=divideCol(A,x)
%divideCol - Divide each colums of matrix A by the corresponding element of vector x.
%   Compute B(i,j)= A(i,j)/x(j)
% 	If x is not provided, the columns of the matrix are divided by its sum.
%
%	Syntax:
%		B=divideCol(A,x)
%  	
%	Input Arguments:
%		A - Matrix to be scaled
%		x - scale vector (optional)
%  	
%	Output Arguments:
%		B - Scaled Matrix 
%   
%	Examples:
%		A = [1 2; 3 4];	
%		x = [1; 2];
%		B = divideCol(A,x) % returns [1 1; 3 2]
%		B = divideCol(A) % returns [0.25 0.333; 0.75 0.667]
%
%   See also scaleCol, scaleRow, divideRow
	
	% Check Input
	if nargin < 1 
		error('ERROR: ,%s. %s', mfilename, cMessages.NarginError);
	end
	if ~ismatrix(A) || ~isnumeric(A)
		error('ERROR: %s. %s', mfilename, cMessages.InvalidArgument);
	end
	if nargin==1
		x=sum(A,1);
	end
	M=size(A,2);
	if ~isvector(x) || (M~=length(x))
		error('ERROR: %s. %s', mfilename, cMessages.ScaleColsError);
	end
	% Avoid division by zero
	x=zerotol(x);
	ind=find(x);
    x(ind)=1./x(ind);
	% Scale the matrix
    B=scaleCol(A,x);
end