function [ir, red, flt_ECG, Fs, ap] = readpwdata(filename)
%чтение необходимых файлов
    fid = fopen(filename);
    AllData = fread(fid,[34, inf],'int32');    
    fclose(fid);
    
    info= ReadHeader(extAdd(extRemove(filename), 'hdr'));
    Fs = info.Fs;
    
    ir=AllData(15,:)/1000.0;%% ir0
    red=AllData(16,:)/1000.0;%% red0
    
    ap=AllData(13,:)/1000;%% AP
    
    spo = uint32(AllData(19,:));
    spo_0 = double(bitand(spo,uint32(0xFFF)))/10.;
    spo_1 =  double(bitand(bitshift(spo,-12),uint32(0xFFF)))/10.;
    
    rithmsj = extChange(filename, '.json'); % Путь к файлу с ритмами в формате json
    val = jsondecode (fileread (rithmsj));
    
    date0=val.testInfo.date;
    tStart=datenum(date0,'dd-mm-yyyyTHH:MM:SS');
    
    nADf=val.BP.count;% количество измерений АД в пальце
    SADf=double(val.BP.dataSAD.x);% САД в пальце, пересчитанное
    tSADf=double(val.BP.dataSAD.t);%время САД в пальце в мс
    DADf=double(val.BP.dataDAD.x);% ДАД в пальце, пересчитанное
    tDADf=double(val.BP.dataDAD.t);%время ДАД в пальце в мс

    nHR=val.HR.count-1;% количество измерений ЧСС
    tHR=double(val.HR.dataHR.t);%время в мс
    HR=double(val.HR.dataHR.x);% ЧСС уд/мин

    dtt=10.0;
    df=tHR(nHR)/1000.0/dtt+1;
    ticks1=(0:df)*1/(1440*60/dtt)+tStart;
    
    ECG =AllData(1,:);
    
     flt_ECG=ECG;
    for j=11:length(ECG)
    flt_ECG(j)=(ECG(j)+ECG(j-10))/2;
    end
    [b,a]=butter(1,40/1000,'low');
    flt_ECG1 = filtfilt(b,a,flt_ECG);
    [b,a]=butter(1,0.1*2/1000,'high');
    flt_ECG=filtfilt(b,a,flt_ECG1);
end

function [info] = ReadHeader(path)
    info = struct;
    if exist(path,'file')~=0
        fid = fopen(path,'rt');
        str = strsplit(fgetl(fid));
        info.ChCount = str2num(str{1});
        info.Fs = str2num(str{2});
        info.LSB = str2num(str{3});
        if numel(str) > 3
            info.Precision = str{4};
        else
            info.Precision = 'int32'; 
        end
        
        str = strsplit(fgetl(fid));
        info.iBeg = str2num(str{1});
        info.iEnd = str2num(str{2});
        info.StartDateNum = datenum(str(3),'yyyy-mm-ddTHH:MM:SS');
        
        info.ChNames = strsplit(fgetl(fid))';
        info.ChLSB = str2num(fgetl(fid))';
        info.ChUnits = strsplit(fgetl(fid))';
        fclose(fid);
    else
        error('Header file doesn''t exist');
    end
end

function fileNames = extAdd(fileNames, ext)
    if isempty(ext)
        return;
    end
    if strcmp(ext(1), '.' )
        ext = ext(2:end);
    end
    
    if ischar(fileNames)
        fileNames = strcat(fileNames,'.',ext);
    elseif iscell(fileNames)
        fileNames = cellfun(@(x) strcat(x,'.',ext), fileNames, 'un', 0);
    else
        error('invalid fileNames');
    end
end

function fileNames = extRemove(fileNames)
    % ������� �� �������� ������ ���������� � ������ 
    % (��������� ���������, ������� �������� ������ �� ���� ����������)
    if ischar(fileNames)
        fileNames = strsplit(fileNames, filesep);
        names = strsplit(fileNames{end}, '.');
        if numel(names) == 1
            fileNames(end) = names;
        else
            fileNames{end} = strjoin(names(1:end-1),'.');
        end
        fileNames = strjoin(fileNames, filesep);
    elseif iscell(fileNames)
        [path, name, ~] = cellfun(@(x)fileparts(x), fileNames, 'un', 0);
        fileNames = fullfile(path, name);
    else
        error('invalid fileNames');
    end
end

function [ fileNames ] = extChange( fileNames, ext)
% меняет расширение в пути к файлу на другое
fileNames = extAdd(extRemove(fileNames), ext);

end
