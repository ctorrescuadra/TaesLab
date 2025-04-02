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
    [N,sz]=size(x);
    M=size(A,2);
    if N>1,x=x';sz=N;end
    if(sz~=M)
        error('ERROR: scaleCol.  Matrix dimensions must agree: %d %d',sz,M);
    end
    B=x.*A;
end