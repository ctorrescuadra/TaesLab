function SaveResults(arg, filename)
%SaveResults - Export result tables to file in multiple formats.
%   Saves analysis results from thermoeconomic calculations to files for reporting,
%   documentation, or further analysis. This function provides a unified interface
%   for exporting result tables in various formats suitable for different purposes:
%   data analysis (XLSX, CSV, MAT), documentation (HTML, LaTeX), or review (TXT).
%
%   All tables in the result set are exported to the specified file format. The
%   format is automatically determined from the file extension. Tables are formatted
%   according to their type (matrix, cell, or data table) and include appropriate
%   headers, units, and numerical formatting.
%
%   The function validates inputs and displays status messages confirming successful
%   export or reporting any errors encountered during the save operation.
%   
%   Syntax:
%     SaveResults(arg, filename)
%
%   Input Arguments:
%     arg - Result set object containing analysis tables
%       cResultSet (or derived classes)
%       Any object containing result tables including:
%         - cModelResults: Complete thermoeconomic model analysis results
%         - cResultInfo: Specific analysis results (exergy, costs, diagnosis)
%         - cDataModel: Data model tables (flows, processes, states)
%         - cThermoeconomicModel: Model with embedded results
%       All tables contained in the object will be exported to the output file.
%
%     filename - Output file path with extension
%       char array | string
%       Full path or relative path to the output file. The file extension determines
%       the save format and structure:
%
%       Data Analysis Formats:
%         .xlsx - Excel workbook with one sheet per table. Formatted cells with
%                 borders, colors, and proper numeric formatting. Compatible with
%                 Excel, LibreOffice, and data analysis tools.
%
%         .csv  - Directory containing separate CSV files (one per table). Plain text
%                 format ideal for version control, scripting, and data processing.
%
%         .mat  - MATLAB binary format preserving full table objects. Fastest loading
%                 and most compact. Includes all table metadata and formatting info.
%
%       Documentation Formats:
%         .html - Web page with styled tables. Can be opened in any browser for
%                 viewing or printing. Includes CSS styling for professional appearance.
%
%         .tex  - LaTeX source file with table environments. Ready for inclusion in
%                 LaTeX documents or academic papers. Uses tabular environments with
%                 proper formatting commands.
%
%         .txt  - Plain text with ASCII art tables. Monospaced formatting suitable
%                 for console viewing, email, or plain text documentation.
%
%   Output:
%     (No output arguments)
%     Status messages are displayed in the console indicating success or failure
%     of the save operation. Error messages provide details about validation
%     failures or file I/O issues.
%
%   Format Selection Guidelines:
%     - Use XLSX for sharing with non-MATLAB users or importing into spreadsheets
%     - Use CSV for version control systems or command-line processing
%     - Use MAT for archiving results with fast re-loading in MATLAB
%     - Use HTML for web-based reports or browser viewing
%     - Use LaTeX for academic publications or professional documents
%     - Use TXT for simple viewing or inclusion in plain text reports
%
%   Examples:
%     % Save exergy analysis results to Excel
%     results = model.exergyAnalysis();
%     SaveResults(results, 'exergy_results.xlsx')
%
%     % Export cost analysis to HTML for reporting
%     costs = ThermoeconomicAnalysis(data, 'state1');
%     SaveResults(costs, 'reports\cost_analysis.html')
%
%     % Save diagnosis results to LaTeX for publication
%     diagnosis = ThermoeconomicDiagnosis(model, 'design', 'malfunction');
%     SaveResults(diagnosis, 'diagnosis_results.tex')
%
%     % Archive complete model results in binary format
%     allResults = model.thermoeconomicAnalysis();
%     SaveResults(allResults, 'archive\complete_analysis.mat')
%
%     % Export to CSV for automated processing
%     SaveResults(modelResults, 'output\results.csv')
%
%     % Create plain text report for documentation
%     SaveResults(summary, 'documentation\summary.txt')
%
%   Live Script Demo:
%     <a href="matlab:open SaveResultsDemo.mlx">Save Results Demo</a>
%
%   See also ShowResults, ExportResults, SaveTable, cResultSet, cResultInfo.
%   
    log=cTaesLab();
    % Check Input parameters    
    if (nargin~=2) 
        log.printError(cMessages.NarginError,cMessages.ShowHelp);
        return
    end
    if ~isObject(arg,'cResultSet')
        log.printError(cMessages.ResultSetRequired);
        return
    end
    if ~isFilename(filename)
        log.printError(cMessages.InvalidOutputFile,filename);
        return
    end
    % Save Results  
    log=saveResults(arg,filename);
    printLogger(log);
end