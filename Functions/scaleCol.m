function B=scaleCol(A,x)
% scaleCol - Compute B=A*diag(x)
%	Multiplies each column of matrix A, by the corresponding element of vector x.
%
%   Usage
%     B = scaleCol(A, x)
%
%   Input Arguments
%	  A - Matrix to be scaled
%	  x - scale vector
%
%   Output Arguments
%	  B - Scaled Matrix 
%
    M=size(A,2);
    if(M~=length(x))
        error('ERROR: scaleCol.  Matrix dimensions must agree: %d %d',length(x),M);
    end
    if issparse(A)
        B = A * spdiags(x(:), 0, M, M);
    else
        if iscolumn(x), x=x'; end
        B = x .* A;
    end
end