% Thermoeconomic Analysis Toolbox
% Version 1.6 (R2024a) 03-Jun-2024
%
% Apps
%   TaesApp                 - TaesLab App.
%   TaesTool                - Octave-compatible alternative to TaesApp.
%
% Read Data Models
%   ReadDataModel           - Reads a data model file.
%   ImportDataModel         - Reads a previously saved data model MAT file.
%
% Get the Thermoeconomic Results
%   ThermoeconomicModel     - Gets the complete thermoeconomic model of a plant.
%   ProductiveStructure     - Shows information on the productive structure of a plant.
%   ProductiveDiagram       - Gets the adjacency tables of the productive structure.
%   DiagramFP               - Gets the Diagram FP information of a plant state.
%   ThermoeconomicState     - Shows the exergy values of a plant state.
%   ThermoeconomicAnalysis  - Provides a thermoeconomic analysis of a plant state.
%   ThermoeconomicDiagnosis - Compares a plant state with its reference state.
%   WasteAnalysis           - Provides a waste recycling analysis of a plant state.
%   SummaryResults          - Gets the summary results of a data model.
%   TotalMalfunctionCost    - Gets a detailed breakdown of the total malfunction cost.
%
% Save Results Information
%   SaveDataModel           - Saves the data model to a file.
%   SaveResults             - Saves the cResultSet object tables to a file.
%   SaveDiagramFP           - Saves the Diagram FP adjacency tables to a file.
%   SaveProductiveDiagram   - Saves the productive structure adjacency tables to a file.
%   SaveSummaryResults      - Saves the summary tables to a file.
%   SaveTable               - Saves an individual table of the model.
%   ExportDataModel         - Copy a model data file to another format.
%
% Results Presentation
%   ListResultTables        - List the properties of the result tables.
%   ShowResults             - Shows the model results tables.
%   ExportResults           - Exports result tables in different formats.
%   ShowGraph               - Shows the graph of a model result table.
%
% GUI functions
%   ViewResults             - View the model results in a GUI App
%   ResultsPanel            - Interactive Results Viewer
%   TaesPanel               - Selects parameters for Thermoeconomic Model
%
% See also cResultSet.