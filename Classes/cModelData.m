classdef (Sealed) cModelData < cMessageLogger
%cModelData - Container class for the raw Data Model structure.
%   Stores the structured data read from a model file (JSON, XML, XLSX, or
%   CSV) before validation and processing by cDataModel. It acts as an
%   intermediate transfer object between the cReadModel interface and the
%   cDataModel data hub.
%
%   Three sections are mandatory: ProductiveStructure, ExergyStates, and
%   Format. Two sections are optional: WasteDefinition and ResourcesCost.
%   The object is invalid (isValid returns false) if any mandatory section
%   is missing or if the input is not a struct.
%
%   cModelData properties:
%     ModelName           - Name of the model (derived from the source file)
%     ProductiveStructure - Productive structure data (flows and processes)
%     ExergyStates        - Exergy states data (thermodynamic operating points)
%     WasteDefinition     - Waste definition data (optional)
%     ResourcesCost       - Resource cost sample data (optional)
%     Format              - Results format definition
%
%   cModelData methods:
%     cModelData        - Construct an instance of this class
%     getStateNames     - Get a cell array with the exergy state names
%     getSampleNames    - Get a cell array with the resource cost sample names
%     isWaste           - Check if the WasteDefinition section is present
%     isResource        - Check if the ResourcesCost section is present
%     saveAsXML         - Save the data model to an XML file
%     saveAsJSON        - Save the data model to a JSON file
%
%   See also cReadModel, cDataModel, cThermoeconomicModel
%
    properties(GetAccess=public,SetAccess=private)
        ModelName             % Model Name
        ProductiveStructure   % Productive Structure data
        ExergyStates          % Exergy States data
        WasteDefinition       % Waste Definition data
        ResourcesCost         % Resources cost data
        Format                % Format data
    end

    properties(Access=private)
        dm    % Structure containing the data model
    end

    methods
        function obj = cModelData(name,s)
        %cModelData - Construct an instance of this class
        %   Validates the input structure and populates all data model
        %   sections. The object status is set to false if a required
        %   section is missing or if s is not a struct.
        %
        %   Syntax:
        %     obj = cModelData(name, s)
        %
        %   Input Arguments:
        %     name - (char) Name of the model, typically derived from the
        %            source file name
        %     s    - (struct) Structure containing the raw data model with
        %            required fields: ProductiveStructure, ExergyStates,
        %            Format; and optional fields: WasteDefinition,
        %            ResourcesCost
        %
        %   Output Arguments:
        %     obj  - cModelData object; check isValid(obj) before use
        %
            if ~isstruct(s)
                obj.messageLog(cType.ERROR,cMessages.InvalidDataModelFile);
                return
            end
            obj.ModelName=name;
            %Productive Structure
            fld=cType.DataId.PRODUCTIVE_STRUCTURE;
            if isfield(s,fld) 
                obj.(fld)=s.(fld);
            else
                obj.messageLog(cType.ERROR,cMessages.ModelDataMissing,fld);
                return
            end
            %ExergyStates
            fld=cType.DataId.EXERGY;
            if isfield(s,fld) 
                obj.(fld)=s.(fld);
            else
                obj.messageLog(cType.ERROR,cMessages.ModelDataMissing,fld);
                return
            end
            %FormatData
            fld=cType.DataId.FORMAT;
            if isfield(s,fld) 
                obj.(fld)=s.(fld);
            else
                obj.messageLog(cType.ERROR,cMessages.ModelDataMissing,fld);
                return
            end
            %WasteDefinition
            fld=cType.DataId.WASTE;
            if isfield(s,fld)
                obj.(fld)=s.(fld);
            end
            %ResourceCost
            fld=cType.DataId.RESOURCES;
            if isfield(s,fld)
                obj.(fld)=s.(fld);
            end
            obj.dm=s;
        end

        function res=getStateNames(obj)
        %getStateNames - Get the names of all exergy states in the model
        %
        %   Syntax:
        %     res = obj.getStateNames()
        %
        %   Output Arguments:
        %     res - (1×N cell array of char) Names of all exergy states
        %           defined in the ExergyStates section
        %
        %   See also getSampleNames, isWaste, isResource
        %
            res={obj.dm.ExergyStates.States(:).stateId};
        end

        function res=getSampleNames(obj)
        %getSampleNames - Get the names of all resource cost samples in the model
        %
        %   Syntax:
        %     res = obj.getSampleNames()
        %
        %   Output Arguments:
        %     res - (1×N cell array of char) Names of all resource cost
        %           samples defined in the ResourcesCost section
        %
        %   See also getStateNames, isResource
        %
            res={obj.dm.ResourcesCost.Samples(:).sampleId};
        end
        function res=isWaste(obj)
        %isWaste - Indicate if the optional WasteDefinition section is present
        %
        %   Syntax:
        %     res = obj.isWaste()
        %
        %   Output Arguments:
        %     res - (logical) true if the WasteDefinition section was found
        %           in the source data; false otherwise
        %
        %   See also isResource
        %
            res=~isempty(obj.WasteDefinition);
        end

        function res=isResource(obj)
        %isResource - Indicate if the optional ResourcesCost section is present
        %
        %   Syntax:
        %     res = obj.isResource()
        %
        %   Output Arguments:
        %     res - (logical) true if the ResourcesCost section was found
        %           in the source data; false otherwise
        %
        %   See also isWaste, getSampleNames
        %
            res=~isempty(obj.ResourcesCost);
        end

        function log=saveAsXML(obj,filename)
        %saveAsXML - Save the data model to an XML file
        %   Serialises the internal data structure using writestruct.
        %
        %   Syntax:
        %     log = obj.saveAsXML(filename)
        %
        %   Input Arguments:
        %     filename - (char) Path and name of the output XML file
        %
        %   Output Arguments:
        %     log - cMessageLogger object; check isValid(log) to determine
        %           whether the file was saved successfully
        %
        %   See also saveAsJSON

            log=cMessageLogger();
            try
                writestruct(obj.dm,filename,'StructNodeName','root','AttributeSuffix','Id');
            catch err
                log.messageLog(cType.ERROR,err.message);
                log.messageLog(cType.ERROR,cMessages.FileNotSaved,filename);
            end
		end

        function log=saveAsJSON(obj,filename)
        %saveAsJSON - Save the data model to a JSON file
        %   Encodes the internal data structure with pretty-printed JSON
        %   and writes it to the specified file.
        %
        %   Syntax:
        %     log = obj.saveAsJSON(filename)
        %
        %   Input Arguments:
        %     filename - (char) Path and name of the output JSON file
        %
        %   Output Arguments:
        %     log - cMessageLogger object; check isValid(log) to determine
        %           whether the file was saved successfully
        %
        %   See also saveAsXML
        %
            log=cMessageLogger();
            try
                text=jsonencode(obj.dm,'PrettyPrint',true);
                fid=fopen(filename,'wt');
                fwrite(fid,text);
                fclose(fid);
            catch err
                log.messageLog(cType.ERROR,err.message);
                log.messageLog(cType.ERROR,cMessages.FileNotSaved,filename);
            end
        end
    end
end