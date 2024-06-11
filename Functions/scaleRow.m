function B=scaleRow(A,x)
% scaleRow computes B=diag(x)*A
%	Multiplies each row of matrix A, by the corresponding element of vector x.
%   INPUT:
%	    A - Matrix to be scaled
%	    x - scale vector
%   OUTPUT:
%	    B - Scaled Matrix 
%
    [N,~]=size(A);
    if(N~=length(x))
        error('Matrix dimensions must agree: %d %d',N,length(x));
    end   
    if issparse(A)
        B=diag(sparse(x))*A;
    else
        B=diag(x)*A;
    end
end 