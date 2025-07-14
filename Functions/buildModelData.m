function res = buildModelData(obj)
%buildModelData - Update ModelData
    % General variables
    ps=obj.ProductiveStructure;
    % Exergy
    ds=obj.ExergyData;
    fields={'key','value'};
    snames=obj.StateNames;
    st=cell(obj.NrOfStates,1);
    for i=1:obj.NrOfStates
        st{i}.stateId=snames{i};
        exd=ds.getValues(i);
        values=[ps.FlowKeys;num2cell(exd.FlowsExergy)];
        st{i}.exergy=cell2struct(values,fields,1);
    end
    ExergyStates.States=cell2mat(st);
    %Waste Definition
    if obj.isWaste
        keys=ps.ProcessKeys;
        wd=obj.WasteData;
        NR=obj.NrOfWastes;
        pswd=cell(NR,1);
        for i=1:NR
            pswd{i}.flow=wd.Names{i};
            pswd{i}.type=wd.Type{i};
            pswd{i}.recycle=wd.RecycleRatio(i);
            [~,cols,vals]=find(wd.Values(i,:));
            nnz=length(vals);
            if nnz>0
                tmp=cell(nnz,1);
                for j=1:nnz
                    tmp{j}.process=keys{cols(j)};
                    tmp{j}.value=vals(j);
                end
                pswd{i}.values=cell2mat(tmp);
            end
        end
        WasteDefinition.waste=cell2mat(pswd);
    end
    %Resource data
    if obj.isResourceCost
        ds=obj.ResourceData;
        snames=obj.SampleNames;
        rs=cell(obj.NrOfSamples,1);
        for i=1:obj.NrOfSamples
            rs{i}.stateId=snames{i};
            rsd=ds.getValues(i);
            % Flow Resources
            idx=rsd.frsc;
            keys=ps.FlowKeys(idx);
            vals=num2cell(rsd.c0(idx));            
            values=[keys;vals];
            rs{i}.flows=cell2struct(values,fields,1);
            % Process Resources
            keys=ps.ProcessKeys(1:end-1);
            vals=num2cell(rsd.Z);            
            values=[keys;vals];
            rs{i}.processes=cell2struct(values,fields,1);
        end
    end
    % Build Model Data
    ResourcesCost.Samples=cell2mat(rs);
    md=struct('ProductiveStructure',obj.ModelData.ProductiveStructure,...
        'Format',obj.ModelData.Format,...
        'ExergyStates',ExergyStates,...
        'WasteDefinition',WasteDefinition,...
        'ResourcesCost',ResourcesCost);
    res=cModelData(obj.ModelName,md);
end