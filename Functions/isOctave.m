function res=isOctave()
%isOctave - Identifies if the funcion has been executed in Matlab
%	
%	Syntax
%     res = isOctave;
%
%	Output Argument
%	  res - logical result
%		true | false
%
	[res,~]=license('checkout','octave');
end
