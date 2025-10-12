function B=divideRow(A,x)
%divideRow - Divide each row of matrix A by the corresponding element of vector x.
% 	Compute B(i,j)=A(i,j)/x(i)
% 	If x is not provided, the columns of the matrix are scaled by its sum
%
%	Syntax:
%		B=divideRow(A,x)
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
%		B = divideRow(A,x) % returns [1 2; 1.5 2]
%		B = divideRow(A) % returns [0.3333 0.6667; 0.4286 0.5714]
%
%   See also scaleCol, scaleRow, divideCol
  
	% Check Input
	if nargin < 1 || ~ismatrix(A) || ~isnumeric(A)
		error('ERROR: %s. %s', mfilename, cMessages.NarginError);
	end
	if ~ismatrix(A) || ~isnumeric(A)
		error('ERROR: %s. %s', mfilename, cMessages.InvalidArgument);
	end
	if nargin==1
		x=sum(A,2);
	end
	[N,~]=size(A);
	if ~isvector(x) || (N~=length(x))
		error('ERROR: %s. %s', mfilename, cMessages.ScaleRowsError);
	end
	% Avoid division by zero
	x=zerotol(x);
	ind=find(x);
    x(ind)=1 ./ x(ind);
	% Scale the matrix
    B=scaleRow(A,x);
end