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
    [~,M]=size(A);
    if(M~=length(x))
        error('Matrix dimensions must agree: %d %d',M,length(x));
    end
    if issparse(A)
        B=A*diag(sparse(x));
    else
        B=A*diag(x);
    end
end