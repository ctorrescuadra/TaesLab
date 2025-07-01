function res=isOctave()
%isOctave - Identifies if the funcion has been executed in Octave.
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
