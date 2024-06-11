classdef (Sealed) cModelData < cStatusLogger
    %cModelData container class of the Data Model structure
    %  cModelData methods:
    %    obj.isWaste
    %    obj.isResourcesCost
    %    log=saveAsXML(filename)
    %    log=saveAsJSON(filename)
    %
    properties(GetAccess=public,SetAccess=private)
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
        function obj = cModelData(s)
        %cModelData Construct an instance of this class
        %   store the data structure and check it
            obj=obj@cStatusLogger(cType.VALID);
            obj.dm=struct();
            for i=cType.MandatoryData
                fld=cType.DataElements{i};
                if isfield(s,fld)
                    obj.dm.(fld)=s.(fld);
                    obj.(fld)=s.(fld);
                else
                    obj.messageLog(cType.ERROR,'Invalid model. Field %s is missing',fld);
                    return
                end
            end
            for i=cType.OptionalData
                fld=cType.DataElements{i};
                if isfield(s,fld)
                    obj.dm.(fld)=s.(fld);
                    obj.(fld)=s.(fld);
                end
            end
        end

        function res=get.ProductiveStructure(obj)
        % get ProductiveStructure data
            res=[];
            if obj.isValid
                res=obj.dm.ProductiveStructure;
            end
        end
    
        function res=get.ExergyStates(obj)
        % get ExergyStates data
            res=[];
            if obj.isValid
                res=obj.dm.ExergyStates;
            end
        end

        function res=getExergyState(obj,idx)
            res=obj.dm.ExergyStates.States(idx);
        end
    
        function res=get.WasteDefinition(obj)
        % get WasteDefinition data
            res=[];
            if obj.isValid && obj.isWaste
                res=obj.dm.WasteDefinition;
            end
        end
    
        function res=get.ResourcesCost(obj)
        % get ResourcesCost data
            res=[];
            if obj.isValid && obj.isResourceCost
                res=obj.dm.ResourcesCost;
            end
        end    

        function res=getResourceSample(obj,idx)
        % get ResourcesCost data
            res=obj.dm.ResourcesCost.Samples(idx);
        end    
    
        function res=get.Format(obj)
        % get Format data
            res=[];
            if obj.isValid
                res=obj.dm.Format;
            end
        end

        function res=isWaste(obj)
        % isWaste Indicate is optional waste element exists
            id=cType.DataId.WASTE;
            res = isfield(obj.dm,cType.DataElements{id});
        end

        function res=isResourceCost(obj)
        % isResources Indicate is optional resources cost element exists
            id=cType.DataId.RESOURCES;
            res = isfield(obj.dm,cType.DataElements{id});
        end

        function log=saveAsXML(obj,filename)
        % save data model as XML file
        %  Input:
        %   filename - name of the output file
        %  Output:
        %   log: cStatusLog class containing error messages ans status
            log=exportXML(obj.dm,filename);
		end

        function log=saveAsJSON(obj,filename)
        % save data model as JSON file
        %  Input:
        %   filename - name of the output file
        %  Output:
        %   log: cStatusLog class containing error messages ans statu
            log=exportJSON(obj.dm,filename);
        end
    end
end