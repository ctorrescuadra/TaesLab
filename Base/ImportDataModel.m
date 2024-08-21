function obj = ImportDataModel(filename)
%ImportDataModel- Create a cDataModel object from a previously saved MAT file.
%  	This function is equivalent to use ReadDataModel with a MAT file.
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
% 	See also cReadModel
%
    obj=cStatus();
	% Check input arguments
    if isOctave
        obj.printError('Read MAT files is not yet implemented for Octave');
		return
    end
    % Load and check the model
	obj=importMAT(filename);
	if ~isDataModel(obj)
		printLogger(obj);
	end
end