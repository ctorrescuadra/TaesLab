function B=scaleRow(A,x)
%scaleRow - computes B=diag(x)*A
%	Multiplies each row of matrix A, by the corresponding element of vector x.
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
    [sz,M]=size(x);
    N=size(A);
    if M>1,x=x';sz=M;end
    if(sz~=N)
        error('ERROR: scaleRow.  Matrix dimensions must agree: %d %d',sz,N);
    end
    B=x.*A;
end