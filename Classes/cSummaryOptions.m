classdef cSummaryOptions < cTaesLab
%cSummaryOptions - Encode the available summary options for a data model.
%   cSummaryOptions computes a 2-bit integer Id from the number of exergy
%   states and resource samples, then derives the set of valid option names.
%
%   The Id is built as:
%     Id = (NrOfStates > 1) + 2*(NrOfSamples > 1)
%
%   giving four possible values:
%     0 (00b) - neither  -> ['NONE']
%     1 (01b) - states   -> ['NONE', 'STATES']
%     2 (10b) - samples  -> ['NONE', 'RESOURCES']
%     3 (11b) - both     -> ['NONE', 'STATES', 'RESOURCES', 'ALL']
%
%   This bitmask is also used by checkId to validate arbitrary Id values
%   via bitwise AND.
%
%   cSummaryOptions Properties:
%     Id    - 2-bit integer encoding the available summary types (0–3)
%     Names - Cell array of available option name strings
%
%   cSummaryOptions Methods:
%     cSummaryOptions - Construct from state and sample counts
%     checkId         - Check whether a numeric summary Id is available
%     checkName       - Check whether an option name string is available
%     defaultOption   - Return the most complete available option name
%     isEnable        - Return true if any summary option is available
%     isStates        - Return true if state-summary is available
%     isResources     - Return true if resource-summary is available
%
%   See also cSummaryResults, cType.SummaryId
%
    properties(Constant,Access=private)
        % tM - Transition matrix encoding valid options for each Id value.
        %   Row (Id+1) contains a 1 in column j when cType.SummaryOptions{j}
        %   is a valid choice for that Id.  Columns map to:
        %     1=NONE, 2=STATES, 3=RESOURCES, 4=ALL
        tM=[1 0 0 0; 1 1 0 0; 1 0 1 0; 1 1 1 1];
    end

    properties(GetAccess=public,SetAccess=private)
        Id     % Summary option Id
        Names  % Available summary option names
    end
    
    methods
        function obj=cSummaryOptions(NrOfStates,NrOfSamples)
        %cSummaryOptions - Construct from state and sample counts
        %   Computes the 2-bit Id from the two boolean conditions
        %   (NrOfStates > 1) and (NrOfSamples > 1), uses the transition
        %   matrix tM to select the valid option names, and stores both.
        %
        %   Syntax:
        %     obj = cSummaryOptions(NrOfStates, NrOfSamples)
        %
        %   Input Arguments:
        %     NrOfStates  - Number of exergy states in the data model.
        %     NrOfSamples - Number of resource-cost samples in the data model.
        %
        %   Output Arguments:
        %     obj - cSummaryOptions object with Id and Names set.
        %
            fields=cType.SummaryOptions';
            N=length(fields);
            id=(NrOfStates>1) + 2*(NrOfSamples>1);
            index=cSummaryOptions.tM(id+1,:);
            obj.Names=fields(find(index,N));
            obj.Id=id;
        end

        function res=checkId(obj,option)
        %checkId - Check whether a numeric summary Id is available
        %   Uses bitwise AND to verify that all bits set in option are also
        %   set in obj.Id, confirming the requested combination of summary
        %   types is supported by this data model.
        %
        %   Syntax:
        %     res = obj.checkId(option)
        %
        %   Input Arguments:
        %     option - Numeric summary Id to validate (cType.SummaryId value).
        %
        %   Output Arguments:
        %     res    - Logical scalar: true if option is available, false otherwise.
        %
            res=false;
            if ~isInteger(option) || option<1
                return
            end
            tmp=bitand(obj.Id,option);
            res=eq(tmp,option) && option;
        end

        function res=checkName(obj,option)
        %checkName - Check whether an option name string is available
        %   Tests whether option appears in the Names cell array computed
        %   at construction time for this data model.
        %
        %   Syntax:
        %     res = obj.checkName(option)
        %
        %   Input Arguments:
        %     option - Option name string to validate (e.g. 'STATES').
        %
        %   Output Arguments:
        %     res    - Logical scalar: true if option is in Names, false otherwise.
        %
            res=false;
            if ~ischar(option)
                return
            end
            res=ismember(option,obj.Names);
        end

        function res=defaultOption(obj)
        %defaultOption - Return the most complete available option name
        %   Returns the last element of Names, which is the option that
        %   covers the most summary types for this data model (e.g. 'ALL'
        %   when both states and samples are available, 'STATES' when only
        %   states are available).
        %
        %   Syntax:
        %     res = obj.defaultOption()
        %
        %   Output Arguments:
        %     res - Option name string from Names (e.g. 'ALL', 'STATES',
        %           'RESOURCES', or 'NONE').
        %
            res=obj.Names{end};
        end

        function res=isEnable(obj)
        %isEnable - Return true if any summary option is available
        %   Equivalent to (obj.Id ~= 0): summary is disabled only when
        %   the data model has a single state and a single cost sample.
        %
        %   Syntax:
        %     res = obj.isEnable()
        %
        %   Output Arguments:
        %     res - Logical scalar: true when Id > 0.
        %
            res=logical(obj.Id);
        end

        function res=isStates(obj)
        %isStates - Return true if state-summary is available
        %   Tests bit 1 of Id (set when NrOfStates > 1 at construction).
        %
        %   Syntax:
        %     res = obj.isStates()
        %
        %   Output Arguments:
        %     res - Logical scalar: true when the data model has > 1 state.
        %
            res=bitget(obj.Id,cType.STATES);
        end

        function res=isResources(obj)
        %isResources - Return true if resource-summary is available
        %   Tests bit 2 of Id (set when NrOfSamples > 1 at construction).
        %
        %   Syntax:
        %     res = obj.isResources()
        %
        %   Output Arguments:
        %     res - Logical scalar: true when the data model has > 1 sample.
        %
            res=bitget(obj.Id,cType.RESOURCES);
        end
    end
end