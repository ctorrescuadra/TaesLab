# Thermoeconomic Analysis Toolbox

  Version 1.8 (R2024b) 01-Oct-2025

## cThermoeconomicModel Methods

### Set Methods

| Name                 | Description                                       |
| :------------------- | :------------------------------------------------ |
| setState             | Set a new valid state from StateNames             |
| setReferenceState    | Set a new valid reference state from StateNames   |
| setResourceSample    | Set a new valid ResourceSample from SampleNames   |
| setCostTables        | Set a new value of CostTables parameter           |
| setDiagnosisMethod   | Set a new value of DiagnosisMethod parameter      |
| setActiveWaste       | Set a new waste flow for recycling analysis       |
| setRecycling         | setRecycing - Set Recycling parameter             |
| setSummary           | Set a new Summary available option                |
| setDebug             | Set debug control variable                        |
| toggleDebug          | Toggle debug property                             |

### Result Info Methods

| Name                      | Description                                                                |
| :------------------------ | :------------------------------------------------------------------------- |
| productiveStructure       | Get the Productive Structure cResultInfo object                            |
| exergyAnalysis            | Get the ExergyAnalysis cResultInfo object for the current state            |
| thermoeconomicAnalysis    | Get the Thermoeconomic Analysis cResultInfo object for the current state   |
| productiveDiagram         | Get the productive diagram cResultInfo object                              |
| diagramFP                 | Get the diagram FP cResultInfo object of rhe current state                 |
| thermoeconomicDiagnosis   | Get the Thermoeconomic Diagnosis cResultInfo object                        |
| summaryDiagnosis          | Get the diagnosis results summary                                          |
| wasteAnalysis             | Get the Waste Analysis cResultInfo object                                  |
| summaryResults            | Get the Summary Results cResultInfo object                                 |
| dataInfo                  | Get the data model cResultInfo object                                      |
| getResultInfo             | Get the cResultInfo with optional parameters                               |

### Model Info Methods

| Name             | Description                                                               |
| :--------------- | :------------------------------------------------------------------------ |
| showProperties   | Show the values of the current parameters of the model                    |
| isDiagnosis      | Check if diagnosis computation is available.                              |
| isDirectCost     | Check if Direct cost tables are selected                                  |
| isGeneralCost    | isGeneralizedCost - Check if Generalized cost calculation are activated   |
| isResourceCost   | Check if the model has resources cost defined                             |
| isWaste          | Check if model has waste defined                                          |
| showResultInfo   | Show or get a structure containig the results of the model                |

### Summary Info Methods

| Name              | Description                                           |
| :---------------- | :---------------------------------------------------- |
| isSampleSummary   | Check if Samples Summary results has been activated   |
| isStateSummary    | Check if States Summary results has been activated    |
| isSummaryActive   | Check if Summary has been activated                   |
| isSummaryEnable   | Check if Summary is enable                            |
| summaryOptions    | Get the available summary option names                |

### Table Info Methods

| Name                  | Description                                       |
| :-------------------- | :------------------------------------------------ |
| getTable              | Get a table called name, if its available         |
| getTableInfo          | Get the properties of a table                     |
| getTablesDirectory    | Create the tables directory of the active model   |
| showTablesDirectory   | Show the list of available tables                 |

### Result Set Methods

| Name                    | Description                                                                |
| :---------------------- | :------------------------------------------------------------------------- |
| ListOfGraphs            | Get the list of graph tables as cell array                                 |
| ListOfTables            | Get the list of tables as cell array                                       |
| StudyCase               | Get/display the study case names                                           |
| exportResults           | Export result tables into a structure using diferent formats.              |
| exportTable             | Export tname into the selected varmode/format                              |
| getTableIndex           | Get the table index of the results set                                     |
| printResults            | print the result tables on console                                         |
| saveResults             | Save result tables in different file formats depending on file extension   |
| saveTable               | Save a result table into a file depending on extension                     |
| saveDataModel           | Save the data model in a file                                              |
| saveDiagramFP           | Save the Adjacency matrix of the Diagram FP in a file                      |
| saveProductiveDiagram   | Save the productive diagram adjacency tables into a file                   |
| saveSummary             | Save the summary tables into a filename                                    |
| showTableIndex          | View the index table of the results set                                    |
| showDataModel           | Show Data Model tables                                                     |
| showGraph               | Show a graph table.                                                        |
| showResults             | View an individual table                                                   |
| showSummary             | Show Summary tables                                                        |

### Waste Methods

| Name               | Description                                             |
| :----------------- | :------------------------------------------------------ |
| wasteAllocation    | Show waste information in console                       |
| setWasteRecycled   | Set the waste recycling ratios                          |
| setWasteType       | Set the waste type allocation method for Active Waste   |
| setWasteValues     | Set the waste table values                              |

### Resource Methods

| Name                 | Description                                              |
| :------------------- | :------------------------------------------------------- |
| addResourceData      | addExergyData - Set exergy data values to actual state   |
| getResourceData      | Get the resource data cost values of sample              |
| setFlowResource      | setFlowResources - Set the resource cost of the flows    |
| setProcessResource   | Set the resource cost of the processes                   |

### Exergy Methods

| Name            | Description                              |
| :-------------- | :--------------------------------------- |
| addExergyData   | Set exergy data values to actual state   |
| getExergyData   | Get cExergyData object of a state        |
| setExergyData   | Set exergy data values to actual state   |

### Internal Methods

| Name              | Description                                                    |
| :---------------- | :------------------------------------------------------------- |
| updateDataModel   | update the data model if have been changes                     |
| getResultState    | Get the cExergyCost object of each state                       |
| getModelResults   | Get a cell array of cResultInfo objects of the current state   |
| getSampleId       | Get the Sample Id given the resource sample name               |
| getStateId        | Get the State Id given the name.                               |
| getWasteId        | Get the Waste flow Id                                          |
