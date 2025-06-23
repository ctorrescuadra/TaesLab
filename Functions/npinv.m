function [res,log]=npinv(A)
%npinv - calculate the inverse of the M-Matrix, I - A 
%   It use the Gauss-Jordan algorithm
% 	without pivoting and outer product approach
%	
%	Usage
%	  [res,log]=npinv(A)
%
%	Input Arguments
%     A - Non negative matrix
%
%	Output Arguments
%	  log - cMessageLogger with the calculation status
%     res - The inverse of the matrix I - A
%
    log=cMessageLogger(cType.VALID);
	sz=size(A); res=cType.EMPTY;
	% Check the matrix is square and non-negative
	if ~isnumeric(A) || sz(1)~=sz(2)
		log.messageLog(cType.ERROR,cMessages.NoSquareMatrix);
		return
	end
	if ~isNonNegativeMatrix(A)
		log.messageLog(cType.ERROR,cMessages.NegativeMatrix);
		return
	end
	% Compute the inverse matrix using Gauss-Jordan algorithm with outer product
	A=eye(sz)-A;
  	for k=1:sz(1)
    	dk=A(k,k);
		if abs(dk)<cType.EPS
			log.messageLog(cType.ERROR,cMessages.SingularMatrix);
			return
		end
      	pk=1/dk;
      	m=-pk*A(:,k); m(k)=pk;
        v=A(k,:); A(k,:)=0;
      	A=A+m*v;
	    A(:,k)=m;
  	end
	res=A;
end
