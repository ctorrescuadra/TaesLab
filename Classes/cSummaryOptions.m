classdef cSummaryOptions < cMessageLogger
% cSummaryOptions determine the summary options depending on the data model
% 
% cSummaryOptions Properties
%  Id    - Summary options Id (see cType.SummaryId)
%  Names - Available summary options names
%
% cSummaryOptions Methods
%  checkId       - Check if the summary id is available
%  checkName     - Check if the option name is available
%  defaultOption - Get the default summary option
%  isEnabled     - Check if summary is enabled
%  isStates      - Check if there are summary States
%  isResources   - Check if there are summary Resources
%
% See also cSummaryResults
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
        function obj=cSummaryOptions(data)
        % Build an instance of the class
        % Syntax:
        %   obj = cSummaryOptions(data)
        % Input Paramaters
        %   data - cDataModel
        %
            fields=cType.SummaryOptions';
            N=length(fields);
            id=(data.NrOfStates>1) + 2*(data.NrOfSamples>1);
            index=cSummaryOptions.tM(id+1,:);
            obj.Names=fields(find(index,N));
            obj.Id=id;
        end

        function res=checkId(obj,option)
        % Check the summary id option
        % Syntax:
        %   res = obj.checkId(option)
        % Input Argument:
        %   option - Summary Id option to check
        % Output Argument:
        %   true | false
        %
            res=false;
            if ~isInteger(option) || option<1
                return
            end
            tmp=bitand(obj.Id,option);
            res=eq(tmp,option) && option;
        end

        function res=checkName(obj,option)
        % Check the summary name option
        % Syntax:
        %   res = obj.checkName(option)
        % Input Argument:
        %   option - Summary name option to check
        % Output Argument:
        %   true | false
        %
            res=false;
            if ~char(option)
                return
            end
            res=ismember(option,obj.Names);
        end

        function res=defaultOption(obj)
        % Get the default summary option name for the data model
        % Syntax:
        %   res = obj.defaultOption
        % Output Argument
        %   res - Default option name
            res=obj.Names{obj.Id+1};
        end

        function res=isEnable(obj)
        % Check if model has summary enabled
            res=logical(obj.Id);
        end

        function res=isStates(obj)
        % Check if the model has states summary available
            res=bitget(obj.Id,cType.STATES);
        end

        function res=isResources(obj)
        % Check if the model has resources summary available    
            res=bitget(obj.Id,cType.RESOURCES);
        end
    end
end