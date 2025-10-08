function res=isOctave()
%isOctave - Identifies if the funcion has been executed in Octave.
%	
%	Syntax:
%     res = isOctave;
%
%	Output Arguments:
%	  res - logical result
%		true | false
%
%	Example:
%     res = isOctave; %return true if executed in Octave
%
%	See also isMatlab, isdeployed
%
	[res,~]=license('checkout','octave');
end
