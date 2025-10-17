function B=scaleRow(A,x)
%scaleRow - Multiplies each row of matrix A by the corresponding element of vector x.
%	Compute B(i,j)=x(i)*A(i,j)
%
%   Syntax:
%     B = scaleRow(A, x)
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
%     x = [0.5; 2];
%     B = scaleRow(A, x); %B = [0.5, 1; 6, 8]

    % Check Input
    if nargin < 2
        msg=buildMessage(mfilename, cMessages.NarginError,cMessages.ShowHelp);
        error(msg); 
    end
    if ~ismatrix(A) || ~(isnumeric(A) || islogical(A))
        msg=buildMessage(mfilename, cMessages.InvalidArgument);
        error(msg);
    end   
    N=size(A,1);
    if ~isnumeric(x) || ~isvector(x) || (N~=length(x))
        msg=buildMessage(mfilename, cMessages.ScaleRowsError);
        error(msg);
    end
    % Scale the matrix
    if issparse(A)
        B = spdiags(x(:), 0, N, N) * A;
    else
        if isrow(x), x=x'; end
        B = x .* A;
    end
end