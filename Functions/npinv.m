function [A,det]=npinv(A)
% NPINV calculate the inverse of a M-Matrix, using the Gauss-Jordan algorithm
% without pivoting and outer product approach
%	USAGE:
%		[X,det]=npinv(A)
%	INPUT:
%		A - M-Matrix
%	OUTPUT:
%		A - The inverse of the original matrix A
%		det - determinant of the original matrix A
%
  det=1;
  sz=size(G);
  % Check parameters
  if sz(1)~=sz(2)
      log.printError('The input matrix must be square');
      return
  end
  N=sz(1);
  for k=1:N
    dk=A(k,k);
    if abs(dk)<cType.EPS
      log.printError('The matrix is singular');
      det=0;
      return
    else
      pk=1/dk;
		  det=det*dk;
    end
      u=-pk*A(:,k); u(k)=pk;
      v=A(k,:); A(k,:)=0;
      A=A+u*v;
	    A(:,k)=u;
  end
end
