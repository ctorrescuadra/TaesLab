function obj = ImportDataModel(filename)
% ImportDataModel creates a cDataModel object from a previously saved MAT file.
%  USAGE:
% 	obj=ImportDataModel(matfile)
%  INPUT:
% 	filename - Existing MAT file containing a cDataModel object
%  OUTPUT:
% 	obj - cDataModel object
%
% See also cDataModel
%
    obj=cStatusLogger();
	% Check input arguments
    if isOctave
        obj.printError('Read MAT files is not yet implemented for Octave');
		return
    end
    % Load and check the model
	try
        S=load(filename);
		f=fieldnames(S);
		var=S.(f{1});
	catch err
		obj.printError(err.message)
		obj.printError('Error reading file %s',filename);
		return
	end
	if isa(var,'cDataModel') && isValid(var)
        obj=var;
		obj.clearLogger;
	else
		obj.printError('Invalid MAT model file %s',filename);
	end
end