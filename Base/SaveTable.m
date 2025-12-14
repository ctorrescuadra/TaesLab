function SaveTable(tbl, filename)
%SaveTable - Export a single table to file in various formats.
%   Saves an individual cTable object (matrix, cell, or data table) to a file
%   for analysis, documentation, or integration with other tools. This function
%   provides the most flexible export options, supporting both data-oriented
%   formats (XLSX, CSV, JSON, XML, MAT) and documentation formats (HTML, LaTeX, TXT).
%
%   Unlike SaveResults which exports entire result sets, SaveTable focuses on
%   exporting a single table with precise control over the output format. This
%   is useful for extracting specific tables, creating custom reports, or
%   integrating individual results into external workflows.
%
%   The output format is automatically determined from the file extension, and
%   the table structure (matrix vs. cell-based) influences the formatting applied.
%
%   Syntax:
%     SaveTable(tbl, filename)
%
%   Input Arguments:
%     tbl - Table object to export
%       cTable (or derived classes)
%       Any table object including:
%         - cTableMatrix: Flow-process matrices, cost allocation tables, FP tables
%         - cTableCell: Results with mixed data types, efficiency tables, summaries
%         - cTableData: Input data tables (flows, processes, states)
%       The table type determines formatting options and export structure. Matrix
%       tables include row/column totals, while cell tables preserve column-specific
%       formatting and units.
%
%     filename - Output file path with extension
%       char array | string
%       Full or relative path to the output file. The file extension determines
%       both the format and structure of the saved data:
%
%       Spreadsheet Formats:
%         .xlsx - Excel file with single formatted sheet. Includes borders, colors,
%                 merged cells for headers, and proper numeric formatting. Compatible
%                 with Excel, Google Sheets, and LibreOffice Calc.
%
%         .csv  - Comma-separated values file. Plain text format with one row per
%                 line. Ideal for data processing, scripting, version control, and
%                 importing into databases or analysis tools.
%
%       Structured Data Formats:
%         .json - JSON structure with table metadata, headers, and data arrays.
%                 Machine-readable format for web applications, APIs, and
%                 cross-language data exchange.
%
%         .xml  - XML document with hierarchical table structure. Includes schema
%                 information and full metadata. Suitable for XML-based systems
%                 and validation workflows.
%
%         .mat  - MATLAB binary format preserving complete cTable object with all
%                 properties and methods. Fastest loading and smallest file size.
%                 Recommended for MATLAB-to-MATLAB workflows.
%
%       Documentation Formats:
%         .html - Standalone web page with styled table. Includes embedded CSS for
%                 professional appearance. Can be opened in any browser for viewing,
%                 printing, or embedding in web documents.
%
%         .tex  - LaTeX source code with tabular environment. Properly formatted
%                 with column alignment, headers, and rules. Ready for inclusion
%                 in LaTeX documents, papers, or technical reports.
%
%         .txt  - Plain text with ASCII art table layout. Uses spaces and characters
%                 to create visual alignment. Suitable for console viewing, email,
%                 or plain text documentation.
%
%   Table Type Behaviors:
%     cTableMatrix: Exports include row and column totals, process/flow names as
%                   headers, and specialized matrix formatting for better readability.
%
%     cTableCell:   Preserves column-specific formatting, units in headers, mixed
%                   data types, and field name associations for each column.
%
%     cTableData:   Simple tabular export with column headers and data rows,
%                   optimized for data model information.
%
%   Output:
%     (No output arguments)
%     Status messages are displayed in the console indicating successful save
%     or reporting any errors encountered during the export process.
%
%   Examples:
%     % Export cost allocation matrix to Excel       
%     model = ThermoeconomicModel('plant_model.json');
%     costMatrix = model.getTable('dcost');
%     SaveTable(costMatrix, 'cost_allocation.xlsx')
%
%     % Save efficiency table as CSV for processing
%     results = model.thermoeconomicAnalysis();
%     effTable = results.Tables.eprocesses;
%     SaveTable(effTable, 'data\efficiencies.csv')
%
%     % Generate HTML table for web report
%     data = ReadDataModel('plant_model.json'); 
%     fpTable = ExergyAnalysis(data);
%     SaveTable(fpTable.Tables.tfp, 'report\productive_structure.html')
%
%     % Export to LaTeX for academic paper
%     diagnosis = ThermoeconomicDiagnosis(model, 'ReferenceState','design', 'State','malfunction');
%     diagnosisTable = diagnosis.getTable('mfc');
%     SaveTable(diagnosisTable, 'paper\tables\malfunction.tex')
%
%   Live Script Demo:
%     <a href="matlab:open TableInfoDemo.mlx">Tables Info Demo</a>
%
%   See also SaveResults, ShowTable, ExportResults, cTable, cTableMatrix, cTableCell.
%
    log=cTaesLab();
    % Check Input parameters
    if (nargin~=2)
        log.printError(cMessages.NarginError,cMessages.ShowHelp);
        return
    end
    if  ~isObject(tbl,'cTable')
        log.printError(cMessages.TableRequired,cMessages.ShowHelp);
        return
    end
    if ~isFilename(filename)
        log.printError(cMessages.InvalidOutputFilename,filename);
        return
    end
    % Save table
    log=tbl.saveTable(filename);
    printLogger(log);
end