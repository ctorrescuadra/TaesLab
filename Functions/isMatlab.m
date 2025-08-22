function res=isMatlab()
%isMatlab - Identifies if the funcion has been executed in MATLAB.
%   This function is used to check if the code is running in MATLAB or Octave.
%	
%	Syntax
%     res = isMatlab;
%
%	Output Argument
%	  res - logical result
%		true | false
%
%	Example
%     res = isMatlab; %return true if executed in MATLAB
%
%	See also isOctave, isdeployed
%
	[res,~]=license('checkout','matlab');
	res= res || isdeployed;
end