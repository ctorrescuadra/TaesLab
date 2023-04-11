classdef (Sealed) cReadModelJSON < cReadModelStruct
% cReadModelXML implements the cReadModel to read JSON data model files
%   This class read a JSON file containing the thermoeconomic model data
%   and store it into a structure data
%   Methods:
%       obj=cReadModelJSON(cfgfile)
%   Methods inhereted fron cReadModelStruct
%		res=obj.buildDataModel(sd)
%		res=obj.getTableModel
%	Methods inhereted from cReadModel
%		res=obj.getStateName(id)
%		res=obj.getStateId(name)
%   	res=obj.existState()
%   	res=obj.getResourceSample(id)
%   	res=obj.getSampleId(sample)
%		res=obj.existSample(sample)
%	    res=obj.getWasteFlows;
%		res=obj.checkModel;
%   	log=obj.saveAsMAT(filename)
%   	log=obj.saveDataModel(filename)
%   	res=obj.readExergy(state)
%   	res=obj.readResources(sample)
%   	res=obj.readWaste
%   	res=obj.readFormat
%   See also cReadModel, cReadModelStruct
	methods
		function obj=cReadModelJSON(cfgfile)
		% Constructor method
		%	cfgfile - xml file containig the model of the plant
		%
			% Read configuration file
            try
				text=fileread(cfgfile);
				sd=cModelData(jsondecode(text));
		    catch err
                obj.messageLog(cType.ERROR,err.message);
                obj.messageLog(cType.ERROR,'File %s cannot be read',cfgfile);
                return
            end
            % Get model filename
            [~,name]=fileparts(cfgfile);
            obj.ModelFile=strcat(pwd,filesep,name,cType.FileExt.JSON);
            obj.ModelName=name;
            % Check and build Data Model
            obj.buildDataModel(sd);
            if obj.isValid
                obj.setModelProperties;
            end
        end
    end
end