classdef cModelData < cStatusLogger
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
            obj.dm=struct();
            for i=cType.MandatoryData
                fld=cType.DataElements{i};
                if isfield(s,fld)
                    obj.dm.(fld)=s.(fld);
                    obj.(fld)=s.(fld);
                else
                    obj.messageLog(cType.ERROR,'Invalid model. %s is missing',fld);
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
            obj.status=cType.VALID;
        end

        function res=get.ProductiveStructure(obj)
        % get ProductiveStructure data
            if obj.isValid
                res=obj.dm.ProductiveStructure;
            else
                res=[];
            end
        end
    
        function res=get.ExergyStates(obj)
        % get ExergyStates data
            if obj.isValid
                res=obj.dm.ExergyStates;
            else
                res=[];
            end
        end
    
        function res=get.WasteDefinition(obj)
        % get WasteDefinition data
            if obj.isValid && obj.isWaste
                res=obj.dm.WasteDefinition;
            else
                res=[];
            end
        end
    
        function res=get.ResourcesCost(obj)
        % get ResourcesCost data
            if obj.isValid && obj.isResourceCost
                res=obj.dm.ResourcesCost;
            else
                res=[];
            end
        end    
    
        function res=get.Format(obj)
        % get Format data
            if obj.isValid
                res=obj.dm.Format;
            else
                res=[];
            end
        end

        function setWasteDefinition(obj,wd)
        % Set Waste Definition private value
            obj.dm.WasteDefinition=wd;
        end

        function res=isWaste(obj)
        %isWaste Indicate is optional waste element exists
            id=cType.DataId.WASTE;
            res = isfield(obj.dm,cType.DataElements{id});
        end

        function res=isResourceCost(obj)
        %isResources Indicate is optional resources cost element exists
            id=cType.DataId.RESOURCES;
            res = isfield(obj.dm,cType.DataElements{id});
        end

        function log=saveAsXML(obj,filename)
        % save data model as XML file
        %  Input:
        %   filename - name of the output file
        %  Output:
        %   log: cStatusLog class containing error messages ans status
            log=cStatusLogger(cType.VALID);
            if isOctave
                log.messageLog(cType.ERROR,'Save XML files is not yet implemented');
	            return
            end
            if ~cType.checkFileWrite(filename)
                log.messageLog(cType.ERROR,'Invalid file name %s',filename);
                return
            end
            try
			    writestruct(obj.dm,filename,'StructNodeName','root','AttributeSuffix','Id');
            catch err
                log.messageLog(cType.ERROR,err.message);
                log.messageLog(cType.ERROR,'File %s is NOT saved',filename);
                return
            end
		end

        function log=saveAsJSON(obj,filename)
        % save data model as XML file
        %  Input:
        %   filename - name of the output file
        %  Output:
        %   log: cStatusLog class containing error messages ans status
            log=cStatusLogger(cType.VALID);
            if ~cType.checkFileWrite(filename)
                log.messageLog(cType.ERROR,'Invalid file name %s',filename);
                return
            end
            try
		        text=jsonencode(obj.dm,'PrettyPrint',true);
		        fid=fopen(filename,'wt');
		        fwrite(fid,text);
		        fclose(fid);    
            catch err
                log.messageLog(cType.ERROR,err.message);
                log.messageLog(cType.ERROR,'File %s is NOT saved',filename);
                return
            end
        end
    end
end