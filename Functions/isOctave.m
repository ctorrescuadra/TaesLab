function res=isOctave()
% isOctave identifies if the funcion has been executed with Octave or is MATLAB running
%  	OUTPUT:
%		res - (true/false) 
	res=exist('OCTAVE_VERSION','builtin');
return
