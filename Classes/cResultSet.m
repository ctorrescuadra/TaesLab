classdef cResultSet < cStatusLogger
% cResultSet is the base class for result classes
%   It implements the cResultInfo methods
%   object of the class derived from it.
% Methods:
%   res=obj.getResultInfo
%   obj.printResults
%   obj.showResults(name,options)
%   res=obj.getTable(name,options)
%   res=obj.getTableIndex(options)
%   obj.showTableIndex(options)
%   obj.showGraph(name,options)
%   obj.saveResults(filename)
%   obj.saveTable(name,filename)
%   res=obj.exportTable(name,options)
%   res=obj.exportResults(options)
%
% See also cResultInfo, cThermoeconomicModel, cDataModel
    properties(Access=public)
        classId  % Class Id (see cType.ClassId)
    end

    methods
        function obj = cResultSet(id)
        % cResultSet Construct an instance of this class
        %   Define the class identifier
            obj=obj@cStatusLogger(cType.VALID);
            obj.classId=id;
        end
        %%%
        % Result Set functions.
        %%%
        function printResults(obj)
        % Print the result set
        % See also cResultInfo/printResults
            res=getResultInfo(obj);
            printResults(res);
        end

        function showResults(obj,varargin)
        % Show the result set 
        % See also cResultInfo/showResults
            res=getResultInfo(obj);
            showResults(res,varargin{:});
        end

        function res=ListOfTables(obj)
        % Get the list of tables as cell array
            tmp=getResultInfo(obj);
            res=fieldnames(tmp.Tables);
        end

        function tbl=getTable(obj,varargin)
        % Get the table info
        % See also cResultInfo/getTable
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
        % See also cResultInfo/getTableIndex
            res=getResultInfo(obj);
            showTableIndex(res,varargin{:});
        end

        function log=saveResults(obj,varargin)
        % Save the results set
        % See also cResultInfo/saveResults
            res=getResultInfo(obj);
            log=saveResults(res,varargin{:});
        end

        function log=saveTable(obj,varargin)
        % Save a table of the result set
        % See also cResultInfo/saveTable
            res=getResultInfo(obj);
            log=saveTable(res,varargin{:});
        end

        function tbl=exportTable(obj,varargin)
        % Get a tables of the result set in diferent formats
        % See also cResultInfo/exportTable
            res=getResultInfo(obj);
            tbl=exportTable(res,varargin{:});
        end

        function tbl=exportResults(obj,varargin)
        % Get the tables of a result set in diferent formats
        % See also cResultInfo/exportTable
            res=getResultInfo(obj);
            tbl=exportResults(res,varargin{:});
        end
    end
end