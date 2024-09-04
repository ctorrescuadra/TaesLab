classdef (Abstract) cReadModel < cMessageLogger
% cReadModel - Abstract class to implemenent the model reader classes
%   These classes generate the data model.
%
% cReadModel Properties:
%   ModelFile    - File name of the model
%   ModelName    - Name of the model
%   ModelData    - cModelData object
%   isTableModel - Indicates if is a table model 
%
% cReadModel Methods:
%   getDataModel - Get the cDataModel object of the plant  
%
% See also cReadModelStruct, cReadModelTable
%   
	properties(GetAccess=public,SetAccess=protected)
        ModelFile            % File name of the model
        ModelName            % Name of the model
        ModelData            % cModelData object
        isTableModel         % Indicates if is a table model
	end

	methods	
		function res=get.isTableModel(obj)
		% Check if is a cReadModelTable
            res=isa(obj,'cReadModelTable');          
		end

		function res=getDataModel(obj)
		% get the data model object
			res=cDataModel(obj);
		end
	end
    methods(Access=protected)
		function setModelProperties(obj,cfgfile)
		% Set the name of the data model file
			[~,name,ext]=fileparts(cfgfile);
            obj.ModelFile=strcat(pwd,filesep,name,ext);
			obj.ModelName=name;
		end	
    end
end