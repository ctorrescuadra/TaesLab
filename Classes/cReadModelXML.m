classdef (Sealed) cReadModelXML < cReadModelStruct
% cReadModelXML implements the cReadModel to read XML data model files
%   This class read a XML file containing the thermoeconomic model data
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
%
	methods
		function obj=cReadModelXML(cfgfile)
		% Constructor method
		%	cfgfile - xml file containig the model of the plant
		%
			%check arguments
            if isOctave 
		        obj.messageLog(cType.ERROR,'This function is not yet implemented');
                return
            end
			% Read configuration file
            try
		        s=readstruct(cfgfile,'AttributeSuffix','Id');
				f=jsonencode(s);
				sd=cModelData(jsondecode(f));
		    catch err
                obj.messageLog(cType.ERROR,err.message);
                obj.messageLog(cType.ERROR,'File %s cannot be read',cfgfile);
                return
            end
            % Get model filename
            [~,name]=fileparts(cfgfile);
            obj.ModelFile=strcat(pwd,filesep,name,cType.FileExt.XML);
            obj.ModelName=name;
            % Check and build Data Model
            obj.buildDataModel(sd);
            if obj.isValid
                obj.setModelProperties;
            end
        end
	end
end
