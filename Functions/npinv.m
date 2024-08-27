function [A,det]=npinv(A)
%npinv - calculate the inverse of a M-Matrix, using the Gauss-Jordan algorithm
% 	without pivoting and outer product approach
%	
%	Usage
%		[X,det]=npinv(A)
%
%	Input Arguments
%		A - M-Matrix
%
%	Output Arguments
%		B - The inverse of the original matrix A
%		det - determinant of the original matrix A
%
	det=1;
	log=cMessageLogger();
  	% Check parameters
    sz=size(A);
  	if sz(1)~=sz(2)
      	log.printError('The input matrix must be square');
      	return
    end
	% Gauss-Jordan algorithm with outer product 
  	for k=1:sz(1)
    	dk=A(k,k);
    	if abs(dk)<cType.EPS
            det=0;
      		log.printError('The matrix is singular');
      		return
        else
            det=det*dk;
      		pk=1/dk;
    	end
      	m=-pk*A(:,k); m(k)=pk;
        v=A(k,:); A(k,:)=0;
      	A=A+m*v;
	    A(:,k)=m;
  	end
end
