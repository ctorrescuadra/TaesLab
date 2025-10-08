function [res,log]=inverseMatrixOperator(A)
%inverseMatrixOperator - Calculate the inverse of the M-Matrix, I-A.
%   Use matlab algorithms with error logs control
%   The matrix A must be a non-negative matrix.
%   If the matrix I-A is non-singular, the function returns its inverse,
%   and log.status=1.
%   If the matrix I-A is singular, the function returns an empty matrix,
%   and log.status=0 with the corresponding error message.
%   Use printLogger(log) to display the log messages.
%
%	Syntax:
%	  [res,log]=inverseMatrix(A)
%
%	Input Arguments:
%     A - Non negative matrix
%
%	Output Arguments:
%     res - The inverse of the matrix I - A
%	  log - cMessageLogger with the calculation status and logs
%
%   Example:
%     A = [0 0.2; 0.1 0];
%     [res,log] = inverseMatrixOperator(A); % returns    
%      %res = [1.0204 0.2041; 0.1020 1.0204]
%      %log.status = 1
%    
%     A = [0 1; 1 0];
%     [res,log] = inverseMatrixOperator(A) % returns
%      %res = []
%      %log.status = 0
%     printLogger(log) %returns
%      %ERROR: cMessageLogger. Matrix is singular to working precision.
%
%   See also isNonNegativeMatrix, cMessageLogger
%
    warning('off','MATLAB:singularMatrix');
    log=cMessageLogger();
    % Check Input
    if nargin~=1 || ~isNonNegativeMatrix(A)
        log.messageLog(cType.ERROR,cMessages.InvalidArgument,cMessages.ShowHelp);
        res=cType.EMPTY;
        return
    end
    % Compute the inverse and catch warning messages
    lastwarn(cType.EMPTY_CHAR,cType.EMPTY_CHAR);
	res=eye(size(A))/(eye(size(A))-A);
    [warmMess,warnId]=lastwarn();
    if ~isempty(warnId)
        log.messageLog(cType.ERROR,warmMess);
        res=cType.EMPTY;
    end
    warning('on','MATLAB:singularMatrix');
end
