function [res,log]=inverseMatrixOperator(A)
%npinv - Calculate the inverse of the M-Matrix, I-A.
%   Use matlab algorithms with error logs control
%	
%	Usage
%	  [res,log]=inverseMatrix(A)
%
%	Input Arguments
%     A - Non negative matrix
%
%	Output Arguments
%     res - The inverse of the matrix I - A
%	  log - cMessageLogger with the calculation status and logs
%
    warning('off','MATLAB:singularMatrix');
    log=cMessageLogger();
	sz=size(A); res=cType.EMPTY;
    lastwarn(cType.EMPTY_CHAR,cType.EMPTY_CHAR);
	% Check the matrix is square and non-negative
    if ~isnumeric(A) || sz(1)~=sz(2)
		log.messageLog(cType.ERROR,cMessages.NoSquareMatrix);
		return
    end
    if ~isNonNegativeMatrix(A)
		log.messageLog(cType.ERROR,cMessages.NegativeMatrix);
		return
    end
    % Compute the inverse and catch warning messages
	res=eye(size(A))/(eye(size(A))-A);
    [warmMess,warnId]=lastwarn();
    if ~isempty(warnId)
        log.messageLog(cType.ERROR,warmMess);
        res=cType.EMPTY;
    end
    warning('on','MATLAB:singularMatrix');
end
