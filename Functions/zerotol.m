function A=zerotol(A,eps)
% zerotol sets to zero values near to zero 
%	Set to zero all elements of a matrix which absolute value is small to 
% 	a tolerance value eps.
%  	INPUT:
%   	A - matrix to modify
%   	eps - tolerance
%  	OUTPUT:
%		A - modified matrix
	if nargin==1
		eps=cType.EPS;
	end 
	A(abs(A)<eps)=0;
end