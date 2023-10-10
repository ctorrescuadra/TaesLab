function B=scaleRow(A,x)
% scaleRow computes B=diag(x)*A
%	Multiplies each row of matrix A, by the corresponding element of vector x.
%   INPUT:
%	    A - Matrix to be scaled
%	    x - scale vector
%   OUTPUT:
%	    B - Scaled Matrix 
%
    log=cStatus(cType.VALID);
    B=[];
    if nargin<2
        log.printError('Invalid arguments');
        return
    end
    [N,~]=size(A);
    if(N~=length(x))
        log.printError('Matrix dimensions must agree: %d %d',M,length(x));
        return
    end   
    if issparse(A)
        B=diag(sparse(x))*A;
    else
        B=diag(x)*A;
    end
end 