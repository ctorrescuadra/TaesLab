classdef cSummaryTable < cTaesLab
%cSummaryTable - Data container for one summary result table.
%   cSummaryTable is an internal helper class of cSummaryResults.  It
%   stores the definition metadata and a pre-allocated numeric matrix for
%   a single summary table (e.g. exergy values across states, or
%   generalised costs across resource samples).
%
%   Each instance is identified by its Name (taken from the table
%   definition key) and is stored as one entry in the cDataset inside
%   cSummaryResults.  The values matrix is filled column-by-column via
%   setValues as the model iterates over states or resource samples.
%
%   cSummaryTable Properties:
%     TableDefinition - Raw table definition struct (from printformat.json)
%     Values          - Numeric matrix (NrOfRows × NrOfColumns)
%     Name            - Table name string (= TableDefinition.key)
%     Type            - Summary type: cType.STATES or cType.RESOURCES
%     Node            - Row-name node type (cType.NodeType value)
%
%   cSummaryTable Methods:
%     cSummaryTable - Construct and pre-allocate the values matrix
%     setValues     - Fill one column of the values matrix
%
%   See also cSummaryResults, cSummaryOptions
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
        %cSummaryTable - Construct and pre-allocate the values matrix
        %   Determines the matrix dimensions from the data model and the
        %   table definition, then pre-allocates a zero matrix of the
        %   correct size (NrOfRows × NrOfColumns).  The matrix is filled
        %   later by cSummaryResults.setValues.
        %
        %   Number of columns is set by the summary type:
        %     td.stable == cType.STATES    -> dm.NrOfStates
        %     td.stable == cType.RESOURCES -> dm.NrOfSamples
        %
        %   Number of rows is set by the node type (td.node):
        %     cType.NodeType.FLOW    -> dm.NrOfFlows
        %     cType.NodeType.PROCESS -> dm.NrOfProcesses
        %     cType.NodeType.ENV     -> dm.NrOfProcesses + 1
        %
        %   Syntax:
        %     obj = cSummaryTable(dm, td)
        %
        %   Input Arguments:
        %     dm  - cDataModel object providing the dimension counters.
        %     td  - Table definition struct (from cFormatData.getSummaryTables)
        %           with fields: key, stable, node, and formatting fields.
        %
        %   Output Arguments:
        %     obj - cSummaryTable object with Values pre-allocated to zeros.
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
        %get.Name - Return the table name string from the definition key
            res=obj.TableDefinition.key;
        end

        function res=get.Type(obj)
        %get.Type - Return the summary type (cType.STATES or cType.RESOURCES)
            res=obj.TableDefinition.stable;
        end

        function res=get.Node(obj)
        %get.Node - Return the row-name node type (cType.NodeType value)
            res=obj.TableDefinition.node;
        end

        function setValues(obj,idx,val)
        %setValues - Fill one column of the values matrix
        %   Assigns val to column idx of the pre-allocated Values matrix.
        %   idx corresponds to the state index (Type = STATES) or the
        %   resource-sample index (Type = RESOURCES).
        %
        %   Syntax:
        %     obj.setValues(idx, val)
        %
        %   Input Arguments:
        %     idx - Positive integer column index (state or sample number).
        %     val - Numeric column vector with one entry per table row.
        %
            obj.Values(:,idx)=val;
        end
    end

end