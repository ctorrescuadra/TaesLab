classdef (Sealed) cRecyclingAnalysis < cResultId
% cRecyclingAnalysis analyze the potential cost saving of waste recycling
%   This class calculates the direct unit cost of output flows of the plant as function
%   of the recycling ratio of a waste.
%   Methods:
%       obj=cRecyclingAnalysis()
%       obj.doAnalysis
%       obj.plotValues
    properties(GetAccess=public,SetAccess=private)
        OutputFlows  % Output flows
        wasteFlow    % Actual waste flow key
        dValues      % Recycling Analysis Direct Cost values
        gValues      % Recycling Analysis Generalized Cost values
    end
    properties(Access=private)
        ps           % Productive structure
        modelFP      % cModelFPR object
        wasteTable   % cWasteData object
        resourceCost % cReadResource object
        directCost=true        % Direct cost are calculated
        generalCost=false      % General cost are calculated
        isResourceCost=false;  % Resource Cost available
    end

    methods
        function obj = cRecyclingAnalysis(fpm,rsd)
        % Create an instance of cRecyclingAnalysis
        %   Input:
        %       fpm - cModelFPR object
        %       rsc - (optional) cResourceData object     
        %
            obj=obj@cResultId(cType.ResultId.RECYCLING_ANALYSIS);
            % Check input parameters
            if ~isa(fpm,'cModelFPR') || ~fpm.isValid
                obj.addLogger(fpm);
                obj.messageLog(cType.ERROR,'Invalid FPR model');
                return
            end
            if nargin==2
                if  ~isa(rsd,'cResourceData') || ~rsd.isValid
                    rsd.printLogger;
                    obj.addLogger(rsd);
                    obj.messageLog(cType.ERROR,'Invalid Resources Cost data');
                    return
                end
                obj.isResourceCost=true;
                obj.generalCost=true;
                obj.resourceCost=getResourceCost(rsd,fpm);
            end
            obj.ps=fpm.ps;
            % Assign object variables
            obj.modelFP=fpm;
            obj.wasteTable=fpm.WasteData;
            obj.status=cType.VALID;
        end

        function doAnalysis(obj,wkey)
        % Do the recycled analysis for waste wkey
            wd=obj.modelFP.WasteData;
            wId=wd.getWasteIndex(wkey);
            if isempty(wId)
                obj.messageLog(cType.ERROR,'Invalid waste key %s',wkey);
                return
            end
            idx=wd.Flows(wId);
            % Get Output Flows Id
            tmp=obj.ps.SystemOutput.flows;
            outputId=[setdiff(tmp,idx),idx];
            obj.OutputFlows={obj.ps.Flows(outputId).key};
            % Save original values
            rwv=wd.Values;
            wrc=obj.wasteTable.RecycleRatio(wId); % Save original value
            % Generate the table
            x=(0:0.1:1)';
            yd=zeros(size(x,1),size(outputId,2));
            yg=zeros(size(x,1),size(outputId,2));
            sol=obj.modelFP;
            for i=1:size(x,1)
                obj.wasteTable.setRecycleRatio(wId,x(i));
                sol.setWasteOperators;
                if obj.directCost
                    ucost=sol.getDirectProcessUnitCost;
                    fc=sol.getDirectFlowsCost(ucost);
                    yd(i,:)=fc.c(outputId);
                end
                if obj.generalCost
                    ucost=sol.getGeneralProcessUnitCost(obj.resourceCost);
                    fc=sol.getGeneralFlowsCost(ucost,obj.resourceCost);
                    yg(i,:)=fc.c(outputId);
                end
            end
            % Set object variables
            obj.wasteFlow=wkey;
            obj.dValues=[x,yd];
            obj.gValues=[x,yg];
            % Restore original values
            wd.setRecycleRatio(wId,wrc);
            wd.updateValues(rwv);
        end
    end
end