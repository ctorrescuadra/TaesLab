function obj = importMAT(matfile)
% importMAT creates a data model object from a previous saved MAT file
%   USAGE:
%       obj=importMAT(matfile)
%	INPUT:
%		matfile - Existing MAT file containing a cDataModel object
%  	OUTPUT:
%   	obj - cDataModel object
%
    obj=cStatusLogger;
	% Check input arguments
    if isOctave
        obj.messageLog(cType.ERROR,'Read MAT files is not yet implemented for Octave');
		return
    end
    % Load and check the model
	try
        S=load(matfile);
		f=fieldnames(S);
		var=S.(f{1});
	catch err
		obj.messageLog(cType.ERROR,err.message)
		obj.messageLog(cType.ERROR,'Error reading file %s',cfgfile);
		return
	end
	if isa(var,'cDataModel') && isValid(var)
        obj=var;
		obj.clearLogger;
	else
		obj.messageLog(cType.ERROR,'Invalid MAT model file %s',data_file);
	end
end