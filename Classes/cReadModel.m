classdef (Abstract) cReadModel < cMessageLogger
%cReadModel - Abstract class to implemenent the model reader classes.
%   It implements the common properties and methods of the model reader
%   Derived classes: cReadModelStruct and cReadModelTable.
%
%   cReadModel properties:
%     ModelFile    - File name of the model
%     ModelName    - Name of the model
%     ModelData    - cModelData object
%
%   cReadModel methods:
%     getDataModel - Get the cDataModel object of the plant  
%
%   See also cReadModelStruct, cReadModelTable
%   
	properties(GetAccess=public,SetAccess=protected)
        ModelFile		% File name of the model
        ModelName       % Name of the model
        ModelData       % cModelData object
	end

	methods	
		function res=getDataModel(obj)
		%getDataModel - Get the data model object
		%   Syntax:
		%     res = obj.getDataModel()
		%   Output Arguments:
		%     res - cDataModel object
		%
			res=cDataModel(obj.ModelData);
		end
	end
    methods(Access=protected)
		function setModelProperties(obj,cfgfile)
		%setModelProperties - Set the name of the data model
		%   Syntax:
		%     obj.setModelProperties(cfgfile)
		%   Input Arguments:
		%     cfgfile - File name of the model
		%
			if ~ischar(cfgfile) || ~isfile(cfgfile)
				obj.messageLog(cType.ERROR,cMessages.FileNotFound, cfgfile);
				return
			end
			[folder,name,ext]=fileparts(cfgfile);
			if isempty(folder)
				folder=pwd;
			end
            obj.ModelFile=strcat(folder,filesep,name,ext);
			obj.ModelName=name;
		end	
    end
end