function res=ShowResults(arg,varargin)
% ShowResults is the console interface to show the results 
%   Depending on the options you could work with all the results or one specific table
%   If 'Table' option is not selected it works at results set level
%   If 'Index' option is selected, the tables to show could be selected via the Results Panel
%   or displayed on the console.
%   Results could be exported to diferent variable format with the option 'ExportAs'
%   and could be saved into a file in diferent formats with the option 'SaveAs'
%   If 'Table' option is selected the table could be shown in the console, web browser or GUI table
%   depending the 'View' option.
%   Individual tables could be also exported or save into file with options 'ExportAs', 'SaveAs'
%
% USAGE:
%   ShowResults(arg,options)
% INPUT:
%   arg - cResultSet object
%   options - an structure contains additional parameters
%    Table: Name of the table to show. 
%           If empty print on console all the results tables
%    View: Select the way to show the table
%     CONSOLE - show in console (default)
%     GUI - use uitable
%     HTML- use web browser
%    Index: (false/true) Use the Table Index panel to select the tables
%    ExportAs: Select the VarMode to output the ResultSet/Table
%     NONE - return the cTable object (default)
%     CELL - return the table as cell array
%     STRUCT - return the table as structured array
%     TABLE - return a matlab table
%    SaveAs: Save the ResultSet/Table in an external file. 
%            See SaveResults/SaveTable function
%   OUTPUT:
%       res - table object in the format specified in ExportAs
%  
% See also cResultInfo, cThermoeconomicModel
%
    log=cStatusLogger(cType.ERROR);
    % Check input
    checkModel=@(x) isa(x,'cResultSet');
    p = inputParser;
    p.addRequired('arg',checkModel);
    p.addParameter('Table','',@ischar);
    p.addParameter('View',cType.DEFAULT_TABLEVIEW,@cType.checkTableView);
    p.addParameter('Index',false,@islogical);
	p.addParameter('ExportAs',cType.DEFAULT_VARMODE,@cType.checkVarMode);
	p.addParameter('SaveAs','',@ischar);
    try
		p.parse(arg,varargin{:});
    catch err
        log.printError(err.message);
        log.printError('Usage: ViewTable(arg,options)');
        return
    end
    param=p.Results;
    % If no table is select work with the results set
    if isempty(param.Table)
        % Export the results
        if nargout>0
            option=cType.getVarMode(param.ExportAs);
            res=exportResults(arg,option);
        end
        % Save the Results
        if ~isempty(param.SaveAs)
            SaveResults(arg,param.SaveAs);
        end
        % Show the Results
        if param.Index
            option=cType.getTableView(param.View);
            tp=ResultsPanel(option);
            tp.setResults(arg);
        else
            printResults(arg);
        end
    else
    % If table is select work at table level
        tbl=getTable(arg,param.Table);
        if ~isValid(tbl)
            tbl.printLogger;
            return
        end
        % Export the table
        if nargout>0
            option=cType.getVarMode(param.ExportAs);
            res=exportTable(tbl,option);
        end
        % Save table 
        if ~isempty(param.SaveAs)
            SaveTable(tbl,param.SaveAs);
        end
        % View the table
        option=cType.getTableView(param.View);
        showTable(tbl,option);
    end
end