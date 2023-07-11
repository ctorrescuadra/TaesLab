classdef (Abstract) cReadModel < cStatusLogger
% cReadModel Abstract class to implemenent the model reader classes
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
		% Check if it is a cReadModelTable
            res=isa(obj,'cReadModelTable');          
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