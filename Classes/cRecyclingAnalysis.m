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
        outputId     % Output flows Id
        modelFP      % cModelFPR object
        wasteTable   % cReadWaste object
        resourceCost % cReadResource object
        directCost=true        % Direct cost are calculated
        generalCost=false      % General cost are calculated
        isResourceCost=false;  % Resource Cost available
    end

    methods
        function obj = cRecyclingAnalysis(fpm,rsc)
        % Create an instance of cRecyclingAnalysis
        %   Input:
        %       fpm - cModelFPR object
        %       rsc - (optional) cReadResources object     
        %
            obj=obj@cResultId(cType.ResultId.RECYCLING_ANALYSIS);
            % Check input parameters
            if ~isa(fpm,'cModelFPR') || ~fpm.isValid
                obj.addLogger(fpm);
                obj.messageLog(cType.ERROR,'Invalid FPR model');
                return
            end
            if nargin==2
                if  ~isa(rsc,'cReadResources') || ~rsc.isValid
                    rsc.printLogger;
                    obj.addLogger(rsc);
                    obj.messageLog(cType.ERROR,'Invalid Resources Cost data');
                    return
                end
                obj.isResourceCost=true;
                obj.generalCost=true;
                obj.resourceCost=rsc;
            end
            obj.ps=fpm.ps;
            % Get Output Flows Id
            obj.outputId=obj.ps.SystemOutput.flows;
            obj.OutputFlows={obj.ps.Flows(obj.outputId).key};
            % Assign object variables
            obj.modelFP=fpm;
            obj.wasteTable=fpm.WasteData;
            obj.status=cType.VALID;
        end

        function doAnalysis(obj,wkey)
        % Do the recycled analysis for waste wkey
            wId=obj.modelFP.WasteData.getWasteIndex(wkey);
            if isempty(wId)
                obj.messageLog(cType.ERROR,'Invalid waste key %s',wkey);
                return
            end
            obj.wasteFlow=wkey;
            x=(0:0.1:1)';
            yd=zeros(size(x,1),size(obj.outputId,2));
            yg=zeros(size(x,1),size(obj.outputId,2));
            sol=obj.modelFP;
            wrc=obj.wasteTable.RecycleRatio(wId); % Save original value
            for i=1:size(x,1)
                obj.wasteTable.setRecycleRatio(wId,x(i));
                sol.setWasteOperators;
                if obj.directCost
                    ucost=sol.getDirectProcessUnitCost;
                    fc=sol.getDirectFlowsCost(ucost);
                    yd(i,:)=fc.c(obj.outputId);
                end
                if obj.generalCost
                    ucost=sol.getGeneralProcessUnitCost(obj.resourceCost);
                    fc=sol.getGeneralFlowsCost(ucost,obj.resourceCost);
                    yg(i,:)=fc.c(obj.outputId);
                end
            end
            obj.dValues=[x,yd];
            obj.gValues=[x,yg];
            obj.wasteTable.setRecycleRatio(wId,wrc);
        end
    end
end