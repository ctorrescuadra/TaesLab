function B=scaleRow(A,x)
%scaleRow - Multiplies each row of matrix A by the corresponding element of vector x.
%	Compute B(i,j)=x(i)*A(i,j)
%
%   Syntax
%     B = scaleRow(A, x)
%
%   Input Arguments:
%	  A - Matrix to be scaled
%	  x - scale vector
%
%   Output Arguments
%	  B - Scaled Matrix 
%
    N=size(A,1);
    if(N~=length(x))
        error('ERROR: scaleRow.  Matrix dimensions must agree: %d %d',length(x),N);
    end
    if issparse(A)
        B = spdiags(x(:), 0, N, N) * A;
    else
        if isrow(x), x=x'; end
        B = x .* A;
    end
end