function res=isMatlab()
% isMatlab identifies if the funcion has been executed with Matlab or Octave running
%  	OUTPUT:
%		res - (true/false) 
	res = false;
	LIC = license('inuse');
	for elem = 1:numel(LIC)
    	envStr = LIC(elem).feature;
    	if strcmpi(envStr,'matlab')
        	res = true;
        	break
    	end
	end
end