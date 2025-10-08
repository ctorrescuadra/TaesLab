function B = zerotol(A,eps)
%ZEROTOL - Sets to zero the matrix values near to zero.
%   Set to zero all elements of a matrix which absolute value is small to 
%   a tolerance value eps. 
%   If argument eps is missing tolerance is taking as cType.EPS=1.0e-8
%
%	Syntax:
%     B = ZEROTOL(A)
%     B = ZEROTOL(A, eps)
%  	
%	Input Arguments:
%     A   - matrix 
%     eps - tolerance (optional, default is cType.EPS)
%  	
%	Output Arguments:
%	  B - modified matrix
%
%	Example:
%     A = [0.1, 0.2; 0.00001, 0.3];
%     B = ZEROTOL(A, 0.0001); %B = [0.1, 0.2; 0, 0.3]
%
%	See also logicalMatrix, scaleCol, scaleRow

	% Check Input
	if nargin < 1 || ~ismatrix(A) || ~isnumeric(A)
		error('ERROR: zerotol. First argument must be a numeric matrix');
	end
	if nargin==1 || isempty(eps) || ~isscalar(eps) || eps < 0
		eps=cType.EPS;
	end
	% Set to zero values near to zero
	B(abs(A)<eps)=0;
end