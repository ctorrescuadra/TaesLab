classdef (Sealed) cModelData < cMessageLogger
%cModelData - is a container class of the Data Model structure
%   Contains the data model from read interface
%
%   cModelData constructor:
%     obj = cModelData(name, s)
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
%     getStateNames     - Get a cell array with the state names
%     getSampleNames    - Get a cell array with the resource sample names
%     isWaste           - Check if data contains waste definition
%     isResourceCost    - Check if data contains resource cost info
%     saveAsXML         - Save data as XML file
%     saveAsJSON        - Save data as JSON file
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
        %     name - Name of the data model
        %     s - struct containing the data
        % 
            obj.dm=struct();
            obj.ModelName=name;
            for i=cType.MandatoryData
                fld=cType.DataElements{i};
                if isfield(s,fld)
                    obj.dm.(fld)=s.(fld);
                else
                    obj.messageLog(cType.ERROR,cMessages.ModelDataMissing,fld);
                    return
                end
            end
            for i=cType.OptionalData
                fld=cType.DataElements{i};
                if isfield(s,fld)
                    obj.dm.(fld)=s.(fld);
                end
            end
        end

        function res=get.ProductiveStructure(obj)
        % Get ProductiveStructure data
            res=cType.EMPTY;
            if obj.status
                res=obj.dm.ProductiveStructure;
            end
        end
    
        function res=get.ExergyStates(obj)
        % Get ExergyStates data
            res=cType.EMPTY;
            if obj.status
                res=obj.dm.ExergyStates;
            end
        end

        function res=get.WasteDefinition(obj)
        % Get WasteDefinition data
            res=cType.EMPTY;
            if obj.status && obj.isWaste
                res=obj.dm.WasteDefinition;
            end
        end
    
        function res=get.ResourcesCost(obj)
        % Get ResourcesCost data
            res=cType.EMPTY;
            if obj.status && obj.isResourceCost
                res=obj.dm.ResourcesCost;
            end
        end    
    
        function res=get.Format(obj)
        % Get Format data
            res=cType.EMPTY;
            if obj.status
                res=obj.dm.Format;
            end
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
            id=cType.DataId.WASTE;
            res = isfield(obj.dm,cType.DataElements{id});
        end

        function res=isResourceCost(obj)
        %isResources - Indicate is optional resources cost element exists
            id=cType.DataId.RESOURCES;
            res = isfield(obj.dm,cType.DataElements{id});
        end

        function log=saveAsXML(obj,filename)
        %saveAsXML - save data model as XML file
        %   Input Arguments:
        %     filename - name of the output file
        %   Output Arguments:
        %     log: cStatusLog class containing error messages ans status
            log=cMessageLogger();
            try
                writestruct(obj.dm,filename,'StructNodeName','root','AttributeSuffix','Id');
            catch err
                log.messageLog(cType.ERROR,err.message);
                log.messageLog(cType.ERROR,cMessages.FileNotSaved,filename);
            end
		end

        function log=saveAsJSON(obj,filename)
        %saveAsJSON - save data model as JSON file
        %   Input Arguments:
        %     filename - name of the output file
        %   Output Arguments:
        %     log: cStatusLog class containing error messages and status
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