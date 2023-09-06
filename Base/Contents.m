% Thermoeconomic Analysis Toolbox
% Version 1.3 (R2023a) 10-Jun-2023 
%
% Apps.
%   TaesLab                 - TaesLab App.
%
% Read Data Models.
%   ReadDataModel           - Read a data model file.
%   CheckDataModel          - Read a data model file and check if all elements are valid.
%
% Get the Thermoeconomic Results
%   ThermoeconomicTool      - Get the complete thermoeconomic model of a plant
%   ProductiveStructure     - Show information of productive structure of a plant
%   ProductiveDiagram       - Get the adjacency tables of the productive structure
%   ThermoeconomicState     - Shows the exergy values of a plant state
%   ThermoeconomicAnalysis  - Provide a termoeconomic analysis of a plant state
%   ThermoeconomicDiagnosis - Compares a plant state with the reference state, and get the diagnosis tables
%   SummaryResults          - Get the summary results of a data model
%   RecyclingAnalysis       - Provide a recycling analysis of the plant
%   DiagramFP               - Get the Diagram FP info of a plant state
%   ExergyCostCalculator    - Calculate the exergy cost values of a plant state
%
% Save Results Information
%   SaveDataModel           - Saves the data model into a file.
%   SaveDiagramFP           - Saves the Diagram FP adjacency tables into a file
%   SaveProductiveDiagram   - Saves the productive structure adjacency tables into a file.
%   SaveResults             - Saves a cResultInfo object into a file.
%   SaveModelResults        - Saves the model results of a plant state into a file.
%   SaveSummaryResults      - Saves the summary cost tables into a file
%
% Show Graphs
%   ShowCostGraph           - Show a bar plot of the Irreversibility-Cost tables 
%   ShowDiagnosisGraph      - Show a bar plot of the Diagnosis tables
%   ShowFlowsDiagram        - Show the structural theory flows diagram (Only Matlab)
%   ShowSummaryGraph        - Show the summary results graph 
%   ShowProductiveDiagram   - Show the productive diagram (Only Matlab)
%	ShowRecyclingGraph		- Show the recycling amalysis graph
%	WasteAllocationGraph    - Show a pie chart with the waste allocation used
%
% GUI functions
%   ThermoeconomicPanel     - Graphic user interface to select the thermoeconomic model parameters.
%   ViewResults             - View the model results in a graphic interface 
%
% See also cResultInfo, cThermoeconomicModel.
