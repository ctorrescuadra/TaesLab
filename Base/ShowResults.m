function ShowResults(arg,varargin)
%ShowResults is the console interface to show the results 
%   Depending on the options you could work with all the results or one specific table
%   If 'Table' option is not selected it works at results set level
%   If 'Table' option is selected the table could be shown in the console, web browser or GUI table
%   depending the 'View' option.
%   If 'Panel' option is selected, the tables could be selected via the ResultsPanel
%   Results or individual tables could be saved into a file in diferent formats with the option 'SaveAs'
%   Use Table 'tindex' to show the table index of the result set
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
%     SaveAs: Save the ResultSet/Table in an external file.
%       char array | string of a valid filename
%
%   Example:
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