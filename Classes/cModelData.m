classdef (Sealed) cModelData < cMessageLogger
%cModelData - Container class for the Data Model structure.
%   Contains the data model from read interface
%
%   cModelData properties:
%     ModelName           - Name of the model
%     ProductiveStructure - Productive Structure data
%     ExergyStates        - Exergy States data
%     WasteDefinition     - Waste Definition data
%     ResourcesCost       - Resources cost data
%     Format              - Format data
%   
%   cModelData methods:
%     cModelData        - Create an instance of this class
%     getStateNames     - Get a cell array with the state names
%     getSampleNames    - Get a cell array with the resource sample names
%     isWaste           - Check if data contains waste definition
%     isResource        - Check if data contains resource cost info
%     saveAsXML         - Save data as XML file
%     saveAsJSON        - Save data as JSON file
%
%   See also cThermoeconomicModel  
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
        %   Syntax:
        %     obj = cModelData(name,s)
        %   Input Arguments:
        %     name - Name of the model
        %     s - Structure containing the data model
        %   Output Arguments:
        %     obj - cModelData object
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
        %getStateNames - Get a cell array list with the names of the states
        %   Syntax:
        %     res = obj.getStateNames()
        %   Output Arguments:
        %     res = cell array with the state names
        %
            res={obj.dm.ExergyStates.States(:).stateId};
        end

        function res=getSampleNames(obj)
        %getSampleNames - Get a cell array list with the names of the resource samples
        %   Syntax:
        %     res = obj.getStateNames()
        %   Output Arguments:
        %     res = cell array with the sample names
        %
            res={obj.dm.ResourcesCost.Samples(:).sampleId};
        end
        function res=isWaste(obj)
        %isWaste - Indicate is optional waste element exists
        %   Syntax:
        %     res = obj.isWaste()
        %   Output Arguments:
        %     res - true|false check if WasteDefinition element exists
        %
            res=~isempty(obj.WasteDefinition);
        end

        function res=isResource(obj)
        %isResource - Indicate is optional resource cost element exists
        %   Syntax:
        %     res = obj.isResource()
        %   Output Arguments:
        %     res - true|false check if ResourcesCost element exists
        %
            res=~isempty(obj.ResourcesCost);
        end

        function log=saveAsXML(obj,filename)
        %saveAsXML - Save data model as XML file
        %   Input Arguments:
        %     filename - name of the output file
        %   Output Arguments:
        %     log: cMessageLogger class containing error messages ans status

            log=cMessageLogger();
            try
                writestruct(obj.dm,filename,'StructNodeName','root','AttributeSuffix','Id');
            catch err
                log.messageLog(cType.ERROR,err.message);
                log.messageLog(cType.ERROR,cMessages.FileNotSaved,filename);
            end
		end

        function log=saveAsJSON(obj,filename)
        %saveAsJSON - Save data model as JSON file
        %   Input Arguments:
        %     filename - name of the output file
        %   Output Arguments:
        %     log: cMessageLogger class containing error messages and status
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