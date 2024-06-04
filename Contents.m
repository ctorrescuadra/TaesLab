% Thermoeconomic Analysis Toolbox
% Version 1.6 (R2024a) 03-Jun-2024
%
% Apps
%   TaesApp                 - TaesLab App.
%
% Read Data Models
%   ReadDataModel           - Read a data model file.
%   CheckDataModel          - Read a data model file and check if all elements are valid.
%   ImportDataModel         - Read a data model MAT file previously saved      
%
% Get the Thermoeconomic Results
%   ThermoeconomicModel     - Get the complete thermoeconomic model of a plant
%   ProductiveStructure     - Show information of productive structure of a plant
%   ProductiveDiagram       - Get the adjacency tables of the productive structure
%   DiagramFP               - Get the Diagram FP info of a plant state
%   ThermoeconomicState     - Shows the exergy values of a plant state
%   ThermoeconomicAnalysis  - Provide a termoeconomic analysis of a plant state
%   ThermoeconomicDiagnosis - Compares a plant state with its reference state
%   WasteAnalysis           - Provide waste recycling analysis of a plant state
%   SummaryResults          - Get the summary results of a data model
%   TotalMalfunctionCost    - Get detailed breakdown of total malfunction cost
%
% Save Results Information
%   SaveDataModel           - Saves the data model into a file.
%   SaveResults             - Saves a cResultSet object tables into a file.
%   SaveDiagramFP           - Saves the Diagram FP adjacency tables into a file
%   SaveProductiveDiagram   - Saves the productive structure adjacency tables into a file.
%   SaveSummaryResults      - Saves the summary tables into a file
%   SaveTable               - Save an individual table of the model
%   ExportDataModel         - Copy a model data file in another format
%
% Results Presentation
%   ListResultTables        - List the result tables properties
%   ShowResults             - Show model results tables
%   ExportResults           - Export result tables in diferent formats
%	ShowGraph               - Show the graph of a model result table
%
% GUI functions
%   TaesTool                - Octave compatible alternative to TaesApp
%   ViewResults             - View the model results in a GUI App
%   ResultsPanel            - Interactive Results Viewer
%   TaesPanel               - Select parameters for Thermoeconomic Model
%
% See also cResultSet.
