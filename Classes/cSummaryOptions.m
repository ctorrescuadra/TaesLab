classdef cSummaryOptions < cMessageLogger
%cSummaryOptions - Determine the summary options depending on the data model
% 
%   cSummaryOptions Constructor
%     obj = cSummaryOptions(NrOfStates,NrOfSamples)
%   cSummaryOptions Properties
%     Id    - Summary options Id (see cType.SummaryId)
%     Names - Available summary options names
%
%   cSummaryOptions Methods
%     checkId       - Check if the summary id is available
%     checkName     - Check if the option name is available
%     defaultOption - Get the default summary option
%     isEnabled     - Check if summary is enabled
%     isStates      - Check if there are summary States
%     isResources   - Check if there are summary Resources
%
%   See also cSummaryResults
%
    properties(Constant,Access=private)
        %Transition matrix
        tM=[1 0 0 0; 1 1 0 0; 1 0 1 0; 1 1 1 1];
    end

    properties(GetAccess=public,SetAccess=private)
        Id     % Summary option Id
        Names  % Available summary option names
    end
    
    methods
        function obj=cSummaryOptions(NrOfStates,NrOfSamples)
        %cSummaryOptions - Build an instance of the class
        %   Syntax:
        %     obj = cSummaryOptions(data)
        %   Input Paramaters
        %     NrOfStates - Number of States
        %     NrOfSamples - Number of Samples
        %
            fields=cType.SummaryOptions';
            N=length(fields);
            id=(NrOfStates>1) + 2*(NrOfSamples>1);
            index=cSummaryOptions.tM(id+1,:);
            obj.Names=fields(find(index,N));
            obj.Id=id;
        end

        function res=checkId(obj,option)
        %checkId - Check the summary id option
        %   Syntax:
        %     res = obj.checkId(option)
        %   Input Argument:
        %     option - Summary Id option to check
        %   Output Argument:
        %     true | false
        %
            res=false;
            if ~isInteger(option) || option<1
                return
            end
            tmp=bitand(obj.Id,option);
            res=eq(tmp,option) && option;
        end

        function res=checkName(obj,option)
        %checkName - Check the summary name option
        %   Syntax:
        %     res = obj.checkName(option)
        %   Input Argument:
        %     option - Summary name option to check
        %   Output Argument:
        %     true | false
        %
            res=false;
            if ~ischar(option)
                return
            end
            res=ismember(option,obj.Names);
        end

        function res=defaultOption(obj)
        %defaultOption - Get the default summary option name for the data model
        %   Syntax:
        %     res = obj.defaultOption
        %   Output Argument
        %     res - Default option name
            res=obj.Names{end};
        end

        function res=isEnable(obj)
        %isEnable - Check if model has summary enabled
        %   Syntax:
        %     res = obj.isEnable
        %   Output Arguments:
        %     res - true | false
            res=logical(obj.Id);
        end

        function res=isStates(obj)
        %isStates - Check if the model has states summary available
        %   Syntax:
        %     res = obj.isStates
        %   Output Arguments:
        %     res - true | false
            res=bitget(obj.Id,cType.STATES);
        end

        function res=isResources(obj)
        %isResources - Check if the model has resources summary available
        %   Syntax:
        %     res = obj.isResources
        %   Output Arguments:
        %     res - true | false   
            res=bitget(obj.Id,cType.RESOURCES);
        end
    end
end