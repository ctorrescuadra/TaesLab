function SaveSummary(model, filename)
%SaveSummary - Export summary comparison tables for multiple states or cost samples.
%   Saves comparative summary tables that consolidate results across multiple
%   operating states or cost samples into a single file. This function is designed
%   specifically for thermoeconomic models with multiple conditions, providing
%   side-by-side comparisons of key performance indicators, efficiencies, costs,
%   and other metrics.
%
%   Summary tables are particularly useful for analyzing system behavior under
%   different operating conditions (e.g., design, part-load, winter, summer) or
%   comparing results with different cost scenarios. The function automatically
%   includes all states and samples defined in the model configuration.
%
%   The format is determined by the file extension and supports both data analysis
%   formats (XLSX, CSV, MAT) and documentation formats (HTML, TXT, TeX).
%
%   Syntax:
%     SaveSummary(model, filename)
%
%   Input Arguments:
%     model - Thermoeconomic model object with summary results
%       cThermoeconomicModel
%       The model must have been created with ThermoeconomicModel() including
%       the desired summary configuration options.
%
%     filename - Output file path with extension
%       char array | string
%       Full path or relative path to the output file. The file extension determines
%       the save format:
%
%       Data Analysis Formats:
%         .xlsx - Excel workbook with formatted sheets for each summary table.
%                 Includes state/sample comparisons with proper headers and units.
%                 Suitable for further analysis or sharing with non-MATLAB users.
%
%         .csv  - Directory with separate CSV files for each summary table. Plain
%                 text format ideal for scripting, automated processing, or version
%                 control systems.
%
%         .mat  - MATLAB binary format preserving complete table objects with all
%                 metadata. Fastest loading and most compact for archival purposes.
%
%       Documentation Formats:
%         .html - Styled web page with formatted comparison tables. Can be viewed
%                 in any browser for presentations or reports. Includes CSS styling
%                 for professional appearance.
%
%         .tex  - LaTeX source with tabular environments ready for inclusion in
%                 academic papers or technical documents. Properly formatted for
%                 LaTeX compilation.
%
%         .txt  - Plain text with ASCII art tables. Monospaced formatting suitable
%                 for console viewing, email, or plain text documentation.
%
%   Summary Table Types:
%     The function saves summary tables based on the model's Summary configuration:
%       - State comparisons: Compare same metrics across different operating states
%       - Resource Sample comparisons: Compare metrics across different cost scenarios
%       - Combined tables: Include both state and sample variations
%     
%     Typical summary tables include:
%       - Flow exergy values across states
%       - Process efficiencies comparison
%       - Unit exergy costs for all conditions
%       - Resource consumption and costs
%       - Overall system performance metrics
%
%   Output:
%     (No output arguments)
%     Status messages are displayed in the console confirming successful export
%     or reporting errors. The function validates that the model has the required
%     summary configuration and states/samples before attempting to save.
%
%   Examples:
%     % Create model with state comparison and save to Excel
%     model = ThermoeconomicModel('plant_model.json', 'Summary', 'STATES');
%     SaveSummary(model, 'state_comparison.xlsx')
%
%     % Compare cost samples across multiple scenarios
%     model = ThermoeconomicModel(data, 'Summary', 'SAMPLES', ...
%     SaveSummary(model, 'reports\cost_scenarios.html')
%
%     % Export complete summary with all states and samples
%     model = ThermoeconomicModel('model.json', 'Summary', 'ALL', ...
%                                  'AllStates', true, 'AllSamples', true);
%     SaveSummary(model, 'complete_summary.xlsx')
%
%     % Generate LaTeX tables for publication
%     model = ThermoeconomicModel(data, 'Summary', 'STATES', ...
%     SaveSummary(model, 'paper\comparison_tables.tex')
%
%   Live Script Demo:
%     <a href="matlab:open SummaryResultsDemo.mlx">Summary Results Demo</a>
%
%   See also ThermoeconomicModel, SummaryResults, SaveResults, cSummaryResults.
% 
    log=cTaesLab();
    % Check Input parameters
    if (nargin~=2)
        log.printError(cMessages.NarginError,cMessages.ShowHelp);
        return
    end
    if ~isObject(model,'cThermoeconomicModel')
        log.printError(cMessages.ThermoModelRequired,cMessages.ShowHelp);
        return
    end
    if ~isFilename(filename)
        log.printError(cMessages.InvalidOutputFile,filename);
        return
    end
    % Save summary results
    log=saveSummary(model,filename);
    log.printLogger;
end