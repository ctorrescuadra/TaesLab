function res=isMatlab()
% isMatlab identifies if the funcion has been executed with Matlab or Octave running 
% OUTPUT:
%	res - (true/false) if is Matlab environment or deployed application
%
	[res,~]=license('checkout','matlab');
	res= res || isdeployed;
end