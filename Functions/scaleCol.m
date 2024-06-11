function B=scaleCol(A,x)
% scaleCol computes B=A*diag(x)
%	Multiplies each column of matrix A, by the corresponding element of vector x.
%   INPUT:
%	    A - Matrix to be scaled
%	    x - scale vector
%   OUTPUT:
%	    B - Scaled Matrix 
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