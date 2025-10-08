classdef cSummaryTable < cMessageLogger
%cSummaryTable - Store the properties and values of each summary table.
%   Each cSummaryTable is stored in a dataset element using 'Name' as key
%   It is an internal class of cSummaryResults
%
%   cSummaryTable properties:
%     TableDefinition - Table Definition
%     Values          - Values of the table
%     Name            - Name of the summary table
%     Type            - Type of summary table (STATES/RESOURCES)
%     Node            - Type of row names of the table (see cType.NODE_TYPE)
%
%   cSummaryTable methods:
%     cSummaryTable - Create an instance of the class
%     setValues     - Set the values of the summary table for each state or resource
%
%   See also cSummaryResults
%
    properties(GetAccess=public,SetAccess=private)
        TableDefinition   % Table Definition
        Values            % Values of the table
        Name              % Name of the summary table
        Type              % Type of summary table (STATES/RESOURCES)
        Node              % Type of nodes (row names) of the table
    end

    methods
        function obj = cSummaryTable(dm,td)
        %cSummaryTable - Create an instance of the class
        %   Syntax:
        %     obj = cSummaryTable(dm,td)
        %   Input Arguments:
        %     dm - cDataModel object
        %     td - Table definition structure
        %   Output Arguments:
        %     obj - cSummaryTable object
        %
            % Determine the size of the table
            % Number of Columns
            if td.stable==cType.STATES
                NC=dm.NrOfStates;
            else
                NC=dm.NrOfSamples;
            end
            % Number of rows
            switch td.node
                case cType.NodeType.FLOW
                    NR=dm.NrOfFlows;
                case cType.NodeType.PROCESS
                    NR=dm.NrOfProcesses;
                case cType.NodeType.ENV
                    NR=dm.NrOfProcesses+1;
            end
            % Set the class properties
            obj.TableDefinition=td;
            obj.Values=zeros(NR,NC);
        end

        function res=get.Name(obj)
        % Get Name property
            res=obj.TableDefinition.key;
        end

        function res=get.Type(obj)
        % Get Type property
            res=obj.TableDefinition.stable;
        end

        function res=get.Node(obj)
        % Get Node property
            res=obj.TableDefinition.node;
        end

        function setValues(obj,idx,val)
        %setValues - Set the values of the table for each STATE/RESOURCE
        %   Syntax:
        %     obj.setValues(idx,val)
        %   Input Arguments:
        %     idx - Number of column (STATE/RESOURCE) to update
        %     val - Array with the values
        %
            obj.Values(:,idx)=val;
        end
    end

end