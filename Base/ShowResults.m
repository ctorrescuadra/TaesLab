function res=ShowResults(arg,varargin)
%ShowResults is the console interface to show the results 
%   Depending on the options you could work with all the results or one specific table
%   If 'Table' option is not selected it works at results set level
%   If 'Panel' option is selected, the tables could be selected via the ResultsPanel
%   Results could be exported to diferent variable format with the option 'ExportAs'
%   and could be saved into a file in diferent formats with the option 'SaveAs'
%   If 'Table' option is selected the table could be shown in the console, web browser or GUI table
%   depending the 'View' option.
%   Individual tables could be also exported or save into file with options 'ExportAs', 'SaveAs'
%
%   Syntax
%     ShowResults(arg,Name,Value)
%   
%   Input Arguments
%     arg - cResultSet object
%
%   Name-Value Arguments 
%     Table: Name of the table to show. If empty, print on console all the results tables
%       char array
%     View: Select the way to show the table
%       'CONSOLE' - show in console (default)
%       'HTML' - use web browser
%       'GUI' - use uitable
%     Panel: Use ResultsPanel
%       true | false (default)
%     ExportAs: Select the VarMode to output the ResultSet/Table
%       'NONE' - return the cTable object (default)
%       'CELL' - return the table as cell array
%       'STRUCT' - return the table as structured array
%       'TABLE' - return a matlab table
%     SaveAs: Save the ResultSet/Table in an external file. 
%             See SaveResults/SaveTable function
%
%   Output Arguments
%     res - table object in the format specified in ExportAs
%
%   Example
%     <a href="matlab:open ThermoeconomicModelDemo.mlx">Thermoeconomic Model Demo</a>
%
%   See also cResultSet
%
    log=cStatus();
    % Check input
    checkModel=@(x) isa(x,'cResultSet');
    p = inputParser;
    p.addRequired('arg',checkModel);
    p.addParameter('Table','',@ischar);
    p.addParameter('View',cType.DEFAULT_TABLEVIEW,@cType.checkTableView);
    p.addParameter('Panel',false,@islogical);
	p.addParameter('ExportAs',cType.DEFAULT_VARMODE,@cType.checkVarMode);
	p.addParameter('SaveAs','',@isFilename);
    try
		p.parse(arg,varargin{:});
    catch err
        log.printError(err.message);
        log.printError('Usage: ShowResults(arg,options)');
        return
    end
    param=p.Results;
    % If no table is select work with the results set
    option=cType.getTableView(param.View);
    vm=cType.getVarMode(param.ExportAs);
    if isempty(param.Table)
        % Export the results
        if nargout>0
            res=exportResults(arg,vm);
        end
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
        if ~isValid(tbl)
            printLogger(tbl);
            return
        end
        % Export the table
        if nargout>0
            vm=cType.getVarMode(param.ExportAs);
            res=exportTable(tbl,vm);
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