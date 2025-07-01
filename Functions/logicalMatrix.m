function res=logicalMatrix(A,eps)
%logicalMatrix - Convert a real matrix to logical with zero tolerance.
%	Set to zero all elements of a matrix which absolute value is small to eps
% 	and converts to logical
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
	if nargin==1
		eps=cType.EPS;
	end 
    res=logical(zerotol(A,eps));
end