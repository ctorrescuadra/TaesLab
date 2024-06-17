function obj = ImportDataModel(filename)
% ImportDataModel- Create a cDataModel object from a previously saved MAT file.
%  	This function is equivalent to use <bold>ReadDataModel</bold> with a MAT file.
%
%	Syntax
% 	  obj=ImportDataModel(matfile)
%
%   Input Argument
% 	  matfile - Existing MAT file containing a cDataModel object
%       char array | string
%
%   Output Arguments
% 	  obj - cDataModel object
%
%   Example
%     <a href="matlab:open SaveDataModelDemo.mlx">Save Data Model Demo</a>
%
% See also cReadModel
%
    obj=cStatus();
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