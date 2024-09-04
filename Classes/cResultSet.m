classdef cResultSet < cMessageLogger
% cResultSet is the base class for result classes
%   cResultInfo, cDataModel and cThermoeconomicModel
% 
% cResultSet Properties:
%   classId - Result class Id
%     cType.ClassId.RESULT_INFO
%     cType.ClassId.DATA_MODEL
%     cTtpe.ClassId.RESULT_MODEL
% 
% cResultSet Methods:
%   getResultInfo  - Get the associated cResultInfo
%   ListOfTables   - Get the tables of the cResultInfo 
%   saveTable      - Save the results in a external file 
%   exportTable    - Export a table to another format
%   printResults   - Print results on console
%   showResults    - Show results in different interfaces
%   showGraph      - Show the graph associated to a table
%   getTable       - Get a table by name
%   getTableIndex  - Get the table index
%   showTableIndex - Show the table index in different interfaces 
%   saveResults    - Save all the result tables in a external file
%   exportResults  - Export all the result Tables to another format
%
% See also cResultInfo, cThermoeconomicModel, cDataModel
    properties(Access=public)
        classId  % Class Id (see cType.ClassId)
    end

    methods
        function obj = cResultSet(id)
        % cResultSet Construct an instance of this class
        %   Define the class identifier
            obj.classId=id;
        end

        function res=getResultInfo(obj)
        % getResultInfo - get cResultInfo object from cResultSet
        %   Default base method
        % Syntax:
        %   res=obj.getResultInfo
        % Output Arguments
        %   res - cResultInfo associated to the result set
        %
            res=obj;
        end
        
        %%%
        % Result Set functions.
        %%%
        function res=ListOfTables(obj)
        % Get the list of tables as cell array
        % Syntax:
        %   obj.ListOfTables
        % Output Arguments:
        %   res - cell array with the table names
            res=cType.EMPTY_CELL;
            tmp=getResultInfo(obj);
            if isValid(tmp)
                res=fieldnames(tmp.Tables);
            end
        end

        function log=saveTable(obj,tname,filename)
        % Save the table name in a file depending extension
        %   Valid extension depends of the result set
        % Syntax
        %   obj.saveTable(tname, filename)
        % Input Arguments
        %   tname - name of the table
        %   filename - name of the file with extension
        % Output Arguments
        %   log - cMessageLogger, with the status of the action and error
        %   messages
        %
            log=cMessageLogger();
            if nargin < 3
                log.messageLog(cType.ERROR,'Invalid input parameters');
                return
            end
            tbl=obj.getTable(tname);
            if isValid(tbl)
                log=saveTable(tbl,filename);
            else
                log.messageLog(cType.ERROR,'Table %s does NOT exists',tname);
            end
        end

        function res=exportTable(obj,tname,varargin)
        % exportTable export tname into the selected varmode/format
        % Syntax
        %   obj.exportTable(tname,options)
        % Input Arguments
        %  tname - name of the table
        %  options - optional parameters
        %    varmode - result type
        %      cType.VarMode.NONE: cTable object (default)
        %      cType.VarMode.CELL: cell array
        %      cType.VarMode.STRUCT: structured array
        %      cType.VarModel.TABLE: Matlab table
        %    fmt - Format values (false/true)
        %
            res=cMessageLogger();
            if nargin < 2
                res.messageLog(cType.ERROR,'Invalid number of arguments')
                return
            end
            tbl=obj.getTable(tname);
            if isValid(tbl)
                res=exportTable(tbl,varargin{:});
            else
                res.messageLog(cType.ERROR,'Table %s does NOT exists',tname);
            end
        end

        %%%
        %  Methods implemented in cResultInfo
        %%%
        function printResults(obj)
        % Print the result set
        %   See also cResultInfo/printResults
            res=getResultInfo(obj);
            printResults(res);
        end

        function showResults(obj,varargin)
        % Show the result set 
        %   See also cResultInfo/showResults
            res=getResultInfo(obj);
            showResults(res,varargin{:});
        end

        function showGraph(obj,varargin)
        % Show result set graphs
        %   See also cResultInfo/showGraph
            res=getResultInfo(obj);
            showGraph(res,varargin{:});
        end

        function tbl=getTable(obj,varargin)
        % Get the table info
        %   See also cResultInfo/getTable
            res=getResultInfo(obj);
            tbl=getTable(res,varargin{:});
        end

        function tbl=getTableIndex(obj,varargin)
        % Get the table index info
        % See also cResultInfo/getTableIndex
            res=getResultInfo(obj);
            tbl=getTableIndex(res,varargin{:});
        end

        function showTableIndex(obj,varargin)
        % Show the table index
        %   See also cResultInfo/getTableIndex
            res=getResultInfo(obj);
            showTableIndex(res,varargin{:});
        end

        function log=saveResults(obj,varargin)
        % Save the results set
        %   See also cResultInfo/saveResults
            res=getResultInfo(obj);
            log=saveResults(res,varargin{:});
        end

        function res=exportResults(obj,varargin)
        % Get the tables of a result set in diferent formats
        %   See also cResultInfo/exportTable
            tmp=getResultInfo(obj);
            res=exportResults(tmp,varargin{:});
        end
    end
end