function res=isMatlab()
%isMatlab - Identifies if the funcion has been executed in MATLAB.
%	
%	Syntax
%     res = isMatlab;
%
%	Output Argument
%	  res - logical result
%		true | false
%
	[res,~]=license('checkout','matlab');
	res= res || isdeployed;
end