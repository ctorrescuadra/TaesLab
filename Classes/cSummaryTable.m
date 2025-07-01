classdef cSummaryTable < cMessageLogger
%cSummaryTable - Store the properties and values of each summary table.
%   Each cSummaryTable is stores in a dataset element using 'Name' as key
%   It is an internal class of cSummaryResults
%
%   cSummaryTable Properties
%     Name   - Name of the summary table
%     Type   - Type of summary table (STATES/RESOURCES)
%     Node   - Type of nodes (row names) of the table
%     Values - Values of the table
%
%   cSummaryTable Methods
%     setValues - Set the values of the summary table for each state or resource
%
%   See also cSummaryResults
%
    properties(GetAccess=public,SetAccess=private)
        Name     % Name of the summary table
        Type     % Type of summary table (STATES/RESOURCES)
        Node     % Type of nodes (row names) of the table
        Values   % Values of the table
    end

    methods
        function obj = cSummaryTable(tp,size)
        %cSummaryTable - Create an instance of the class
        %   Syntax
        %     obj = cSummaryTable(tp,size)
        %   Input Argument:
        %     tp - table properties structure
        %     size - size of the table
            obj.Name=tp.key;
            obj.Type=tp.table;
            obj.Node=tp.node;
            obj.Values=zeros(size);
        end

        function setValues(obj,idx,val)
        %setValues - Set the values of the table for each STATE/RESOURCE
        %   Syntax
        %     obj.setValues(idx,val)
        %   Input Arguments
        %     idx - Number of column (STATE/RESOURCE) to update
        %     val - Array with the values
            obj.Values(:,idx)=val;
        end
    end
end