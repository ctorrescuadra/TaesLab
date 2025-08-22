function res=logicalMatrix(A,eps)
%logicalMatrix - Convert a real matrix to logical with zero tolerance.
%	Set to zero all elements of a matrix which absolute value is small to eps
% 	and converts to logical.
%   If eps is missing, tolerance is taking as cType.EPS (1.0e-8)
%
%	Syntax
%     B = logicalMatrix(A, eps)
%  	
%	Input Arguments
%     A - matrix 
%     eps - tolerance
%  	
%	Output Arguments
%	  res - logical matrix
%
%	Example
%     A = [0.1, 0.2; 0.00001, 0.3];
%     res = logicalMatrix(A, 0.0001); %res = [1, 1; 0, 1]
%
%	See also zerotol, logical
%
	if nargin < 1 || ~ismatrix(A) || ~isnumeric(A)
		error('ERROR: logicalMatrix. First argument must be a numeric matrix');
	end
	% Check if eps is provided and valid
	if nargin==1 || isempty(eps) || ~isscalar(eps) || eps < 0
		eps=cType.EPS;
	end 
    res=logical(zerotol(A,eps));
end