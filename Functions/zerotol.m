function A=zerotol(A,eps)
%zerotol - Sets to zero values near to zero 
%	Set to zero all elements of a matrix which absolute value is small to 
% 	a tolerance value eps. If eps is missing tolerance is taking as cType.EPS (1.0e-8)
%
%	Syntax
%     B = zerotol(A, eps)
%  	
%	Input Arguments
%     A - matrix 
%     eps - tolerance
%  	
%	Output Arguments
%	  B - modified matrix
%
	if nargin==1
		eps=cType.EPS;
	end 
	A(abs(A)<eps)=0;
end