function A = zerotol(A,tol)
%ZEROTOL - Sets to zero the matrix values near to zero.
%   Set to zero all elements of a matrix which absolute value is small to 
%   a tolerance value tol. 
%   If argument tol is missing tolerance is taking as cType.EPS=1.0e-8
%
%	Syntax:
%     B = ZEROTOL(A)
%     B = ZEROTOL(A, tol)
%  	
%	Input Arguments:
%     A   - matrix 
%     tol - tolerance (optional, default is cType.EPS)
%  	
%	Output Arguments:
%	  A - modified matrix
%
%	Example:
%     A = [0.1, 0.2; 0.00001, 0.3];
%     A = ZEROTOL(A, 0.0001); %A = [0.1, 0.2; 0, 0.3]
%
%	See also logicalMatrix, scaleCol, scaleRow

	% Check Input
	if nargin < 1 || ~ismatrix(A) || ~isnumeric(A)
		msg=buildMessage(mfilename, cMessages.InvalidArgument,cMessages.ShowHelp);
		error(msg);
	end
	if nargin==1 || isempty(tol) || ~isscalar(tol) || tol < 0
		tol=cType.EPS;
	end
	reltol=tolerance(A,tol);
	% Set to zero values near to zero
	A(abs(A) <= reltol) = 0;
end