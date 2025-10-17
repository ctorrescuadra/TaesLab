function B=scaleCol(A,x)
%scaleCol - Multiplies each column of matrix A by the corresponding element of vector x.
%   Compute B(i,j)=A(i,j)*x(j)
%
%   Syntax:
%     B = scaleCol(A, x)
%
%   Input Arguments:
%	  A - Matrix to be scaled
%	  x - scale vector
%
%   Output Arguments:
%	  B - Scaled Matrix 
%
%   Example:
%     A = [1, 2; 3, 4];
%     x = [0.5, 2];
%     B = scaleCol(A, x); %returns: B = [0.5, 4; 1.5, 8]

    % Check Input
    if nargin < 2 || ~ismatrix(A) || ~(isnumeric(A) || islogical(A))
        msg=buildMessage(mfilename, cMessages.InvalidArgument,cMessages.ShowHelp);
        error(msg);
    end
    if ~ismatrix(A) || ~(isnumeric(A) || islogical(A))
        msg=buildMessage(mfilename, cMessages.InvalidArgument,cMessages.ShowHelp);
        error(msg);
    end
    [~,M]=size(A);
    if ~isnumeric(x) || ~isvector(x) || (M~=length(x))
        msg=buildMessage(mfilename, cMessages.ScaleColsError);
        error(msg);
    end
    % Scale the matrix
    if issparse(A)
        B = A * spdiags(x(:), 0, M, M);
    else
        if iscolumn(x), x=x'; end
        B = x .* A;
    end
end