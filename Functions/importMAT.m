function obj = importMAT(cfgfile)
% importMAT creates a data model object from a previous saved MAT file
%	INPUT:
%		cfgfile - Existing MAT file containing a cRadModel object
%  	OUTPUT:
%   	obj - cReadModel object
%
    obj=cStatusLogger;
	% Check input arguments
    if isOctave
        obj.messageLog(cType.ERROR,'Read MAT files is not yet implemented for Octave');
		return
    end
    % Load and check the model
	try
        S=load(cfgfile);
		f=fieldnames(S);
		var=S.(f{1});
	catch err
		obj.messageLog(cType.ERROR,err.message)
		obj.messageLog(cType.ERROR,'Error reading file %s',cfgfile);
		return
	end
	if isa(var,'cStatusLogger') && isValid(var)
        obj=var;
		obj.clearLogger;
	else
		obj.messageLog(cType.ERROR,'Invalid MAT model file %s',data_file);
	end
end