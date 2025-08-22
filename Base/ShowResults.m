function ShowResults(arg,varargin)
%ShowResults - Show the results tables in different formats.
%   This is the console interface for displaying results. 
%   Depending on the options, you can work with all results or with a specific table.
%   If the 'Table' option is not selected, it works at the result set level.
%   If the 'Table' option is selected, the table can be displayed in the console, web browser, or GUI table,
%   depending on the 'View' option.
%   If the 'Panel' option is selected, tables can be selected through the Results Panel.
%   Individual results or tables can be saved to a file in different formats using the “Save as” option.
%   Use the 'tindex' table to display the table index of the result set.
%
%   Syntax:
%     ShowResults(arg,Name,Value)
%   
%   Input Arguments:
%     arg - cResultSet object
%
%   Name-Value Arguments: 
%     Table: Name of the table to show. If empty, print on console all the results tables
%       char array
%     View: Select the way to show the table
%       'CONSOLE' - show in console (default)
%       'HTML' - use web browser
%       'GUI' - use uitable
%     Panel: Use ResultsPanel
%       true | false (default)
%     SaveAs:  Name of the file (with extension) to save the result tables
%       char array | string 
%
%   Example
%     <a href="matlab:open ShowResultsDemo.mlx">Show Results Demo</a>
%
%   See also cResultSet
%
    log=cMessageLogger();

    if nargin<1 || ~isObject(arg,'cResultSet')
        log.printError(cMessages.ResultSetRequired)
        log.printError(cMessages.ShowHelp);
        return
    end
    % Check input
    p = inputParser;
    p.addParameter('Table',cType.EMPTY_CHAR,@ischar);
    p.addParameter('View',cType.DEFAULT_TABLEVIEW,@cType.checkTableView);
    p.addParameter('Panel',false,@islogical);
	p.addParameter('SaveAs',cType.EMPTY_CHAR,@isFilename);
    try
		p.parse(varargin{:});
    catch err
        log.printError(err.message);
        log.printError(cMessages.ShowHelp);
        return
    end
    param=p.Results;
    option=cType.getTableView(param.View);
    % If no table is selected work with the results set
    if isempty(param.Table)
        % Show the Results
        if param.Panel
            ResultsPanel(arg);
        elseif option>0
            printResults(arg);
        end
        % Save the Results
        if ~isempty(param.SaveAs)
            SaveResults(arg,param.SaveAs);
        end
    else
    % If table is select work at table level
        tbl=getTable(arg,param.Table);
        if ~tbl.status
            printLogger(tbl);
            return
        end
        % View the table
        showTable(tbl,option);
        % Save table 
        if ~isempty(param.SaveAs)
            SaveTable(tbl,param.SaveAs);
        end
    end
end