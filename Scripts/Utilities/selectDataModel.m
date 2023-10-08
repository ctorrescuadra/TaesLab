function model=selectDataModel()
% selectDataModel - Interactive selection of data model
%  OUTPUT:
%	model - cReadModel object
% 
	model=cStatusLogger();
	[~,name]=fileparts(pwd);
	default_file=strcat(name,'_model.xlsx');
	data_file=fileChoice('Select data model file',default_file);
	if ~exist(data_file,'file')
	    model.messageLog(cType.ERROR,'Data Model file %s not found',data_file);
        return
	end
	% Read and Check model
	model=checkDataModel(data_file);
end