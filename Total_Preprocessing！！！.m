
%%  1.  导入滤波剔电极重参考    32人 4次 128data - 3h
clear;
clc;
eeglab

    eegFolder = 'E:\DSKT\BrainEEGData\EEGNew'; % 数据文件夹路径  
    saveFolder = 'E:\DSKT\BrainEEGData\ICA'; % 保存文件夹路径
    fileList = dir(fullfile(eegFolder, '*.cnt'));   % 获取文件夹中所有 .cnt 文件      dir: 列出特定目录下的文件信息list存储在结构数组 files中

     for i = 1:length(fileList)                                                             % 每个被试跑一遍for循环
     file_path = fullfile(eegFolder, fileList(i).name);                             % fullfile 返回文件路径
     EEG = pop_loadcnt(file_path, 'dataformat', 'auto', 'memmapfile', '');          %数据导入  loadcnt
     
     


     EEG = pop_chanedit(EEG, 'lookup','E:\\DSKT\\47EEGB_day1\\eeglab20240_ZZD_v4\\plugins\\dipfit\\standard_BEM\\elec\\standard_1005.elc');   %电极定位(地址)  chanedit
     EEG = pop_eegfiltnew(EEG, 'locutoff',0.1,'plotfreqz',1);                               %滤波  eegfiltnew
     EEG = pop_eegfiltnew(EEG, 'hicutoff',80,'plotfreqz',1);
     EEG = pop_eegfiltnew(EEG, 'locutoff',49,'hicutoff',51,'revfilt',1,'plotfreqz',1);      %凹陷滤波
     EEG = pop_resample( EEG, 250);                                                         %降采样到250Hz，减少容量，加速数据处理  resample
     EEG = pop_select( EEG, 'rmchannel',{'Trigger'});                                       %剔除无用电极  select
     EEG = pop_reref( EEG, [44 45] );                                                       %重参考M1 M2   reref
     EEG = pop_saveset( EEG, 'filename',strcat(strrep(fileList(i).name, '.cnt', ''),'.set'),'filepath',saveFolder);  %保存    saveset
     end



%%  2. 截取前后段跑ICA               128data -  12h
     eegFolder ='E:\DSKT\BrainEEGData\EEGNew';
     saveFolder = 'E:\DSKT\BrainEEGData\ICA';
     fileList = dir(fullfile(eegFolder, '*.set'));            %  dir: 列出特定目录下的文件信息list存储在结构数组 filelist中 （包括 name date byte isdir等）

    for i = 1:length(fileList)
    file_path = fullfile(eegFolder, fileList(i).name);          %fullfile 返回文件路径
    EEG = pop_loadset(file_path);                               %数据导入 loadset
    
    


    markers = EEG.event;                                       
    first_marker_time = markers(1).latency;
    last_marker_time = markers(end).latency;                    %找到所有的标记的时刻 EEG.event

    start_time = first_marker_time - EEG.srate;                 %设置截取范围，从开始marker的前一秒到最后一个marker的后一秒    -1  +1s      EEG.srate：采样率
    end_time = last_marker_time + EEG.srate;

    start_index = round(start_time);                            %将时间转换为索引，round数值四舍五入到最接近的整数
    end_index = round(end_time);
    
    EEG = pop_select(EEG, 'point', [start_index end_index]);    % 截取数据  select



    EEG = pop_runica(EEG, 'icatype', 'runica', 'extended',1,'rndreset','yes','interrupt','on');   % ICA   runica
    EEG = pop_saveset(EEG, 'filename', fileList(i).name, 'filepath', saveFolder);    % 保存截取的数据   saveset
    end

    %% 3.1 ICLabel辅助ICA剔除（自动） 128 data - 2h

    eegFolder = 'E:\DSKT\BrainEEGData\ICA'; % 替换为你的数据文件夹路径  
    saveFolder = 'E:\DSKT\BrainEEGData\EEGAfterICA'; % 替换为你的保存文件夹路径
    fileList = dir(fullfile(eegFolder, '*.set'));      % 获取文件夹中所有 .set 文件      dir: 列出特定目录下的文件list  

    for i = 1:length(fileList)                         % 循环遍历每个文件
    filePath = fullfile(eegFolder, fileList(i).name);   % 构建完整文件路径
    EEG = pop_loadset(filePath);     % 加载 EEG 数据




    EEG = pop_iclabel(EEG, 'default');            % 使用 ICLabel 进行成分标记  iclabel
    EEG = pop_icflag(EEG, [NaN NaN;0.9 1;0.9 1;0.9 1;NaN NaN;NaN NaN;NaN NaN]); % 标记伪迹成分，自定义设定阈值，依次为Brain, Muscle, Eye, Heart, Line Noise, Channel Noise, Other.    icflag
    EEG = pop_subcomp( EEG, [], 0);   %去除上述伪迹成分 --  拒绝   subcomp
    EEG = eeg_checkset(EEG);   % 检查 EEG 数据结构的完整性   checkset

    EEG = pop_saveset(EEG, 'filename', fileList(i).name, 'filepath', saveFolder);
    end

    disp('所有文件处理完成。');

    %%  3.2 ICLabel辅助ICA剔除(手动)   128 data - 1-2days

    eegFolder = 'E:\DSKT\BrainEEGData\ICA'; % 替换为你的数据文件夹路径  
    saveFolder = 'E:\DSKT\BrainEEGData\EEGAfterICA'; % 替换为你的保存文件夹路径
    fileList = dir(fullfile(eegFolder, '*.set'));      % 获取文件夹中所有 .set 文件      dir: 列出特定目录下的文件list  

    for i = 1:length(fileList)                         % 循环遍历每个文件
    filePath = fullfile(eegFolder, fileList(i).name);   % 构建完整文件路径
    EEG = pop_loadset(filePath);     % 加载 EEG 数据


     
    %  pop_ADJUST_interface(  );
    %  %根据Mark分段  要调整
    %  EEG = pop_epoch( EEG, {  '110'  '111'  }, [-0.5    1], 'newname', ' resampled epochs', 'epochinfo', 'yes');
    %  %卡极值 宽松的标准 -100 100  Tools >> Reject data epochs >> Reject extreme values
    % EEG = pop_eegthresh(EEG,1,1:62 ,-100,100,-1,1.998,0,0);
    

    EEG = pop_iclabel(EEG, 'default');            % 使用 ICLabel 进行成分标记  iclabel
    EEG = pop_icflag(EEG, [NaN NaN;NaN NaN;0.85 1;NaN NaN;NaN NaN;NaN NaN;NaN NaN]); % 标记伪迹成分，自定义设定阈值，依次为Brain, Muscle, Eye, Heart, Line Noise, Channel Noise, Other.    icflag

   % 检查 EEG 数据结构的完整性
    EEG = eeg_checkset(EEG);
 
  % 绘制移除成分后的图 
    pop_selectcomps(EEG, 1:64 );
    disp('请检查ICA剔除成分，按任意键继续...');
    pause; % 等待用户按键继续

    EEG = pop_subcomp( EEG, [], 0);
    EEG = eeg_checkset(EEG);    

 %    figure;
 % 
 %    pop_eegplot(EEG, 1, 1, 1);                % 显示移除后的时域图
 %    title(['移除成分后的时域图 - ' fileList(i).name]);
 %    disp('请检查时域图，按任意键继续...');      % 提示用户检查
 %    pause; % 等待用户按键继续

    EEG = pop_saveset(EEG, 'filename', fileList(i).name, 'filepath', saveFolder);   % 保存剔除后的数据到指定文件夹

    disp(['处理完文件: ', fileList(i).name]);      % 提示用户继续
    % pause; % 等待用户按键继续
end

disp('所有文件处理完成。');




           
%%  4. 创建Eventlist，根据binlister分段基线校正 2h

    eegFolder = 'E:\DSKT\ICLabel-ICA\EEG_bin1-4\bin4'; % 替换为你的数据文件夹路径  
    saveFolder = 'E:\DSKT\ICLabel-ICA\EEG_Epoch\bin4'; % 替换为你的保存文件夹路径
    fileList = dir(fullfile(eegFolder, '*.set'));      % 获取文件夹中所有 .set 文件      dir: 列出特定目录下的文件list  



    for i = 1:length(fileList)                         % 循环遍历每个文件
    filePath = fullfile(eegFolder, fileList(i).name);   % 构建完整文件路径
    EEG = pop_loadset(filePath);     % 加载 EEG 数据



     EEG  = pop_creabasiceventlist( EEG , 'AlphanumericCleaning', 'on', 'BoundaryNumeric', { -99 }, 'BoundaryString', { 'boundary' } ); % GUI: 13-Sep-2024 08:52:00
     EEG  = pop_binlister( EEG , 'BDF', 'E:\DSKT\ICLabel-ICA\binlister\binlister_4.txt', 'IndexEL',  1, 'SendEL2', 'EEG', 'Voutput', 'EEG' ); % GUI: 13-Sep-2024 08:53:00
     EEG = pop_epochbin( EEG , [-500.0  1000.0],  'pre'); % GUI: 13-Sep-2024 08:53:59
     pop_eegplot( EEG, 1, 1, 1);
     
     pause;

     EEG = pop_saveset(EEG, 'filename', fileList(i).name, 'filepath', saveFolder);   % 保存剔除后的数据到指定文件夹
    disp(['处理完文件: ', fileList(i).name]);      % 提示用户继续
    end

    disp('所有文件处理完成。');





    % EEG = pop_iclabel(EEG, 'default');            % 使用 ICLabel 进行成分标记  iclabel
    % EEG = pop_icflag(EEG, [NaN NaN;0.9 1;0.9 1;0.9 1;NaN NaN;NaN NaN;NaN NaN]); % 标记伪
    % 迹成分，自定义设定阈值，依次为Brain, Muscle, Eye, Heart, Line Noise, Channel Noise, Other.    icflag
    % EEG = pop_subcomp( EEG, [], 0);   %去除上述伪迹成分 --  拒绝   subcomp
    % EEG = eeg_checkset(EEG);   % 检查 EEG 数据结构的完整性   checkset
    


%% 5.  尾迹检测和识别 2 rounds of artifact detection  
    eegFolder = 'E:\DSKT\ICLabel-ICA\EEG_Epoch_bin1-4\bin4'; % 替换为你的数据文件夹路径  
    saveFolder = 'E:\DSKT\ICLabel-ICA\EEG_Artifact_Detechion\bin4'; % 替换为你的保存文件夹路径
    fileList = dir(fullfile(eegFolder, '*.set'));      % 获取文件夹中所有 .set 文件      dir: 列出特定目录下的文件list  

    for i = 1:length(fileList)                         % 循环遍历每个文件
    filePath = fullfile(eegFolder, fileList(i).name);   % 构建完整文件路径
    EEG = pop_loadset(filePath);     % 加载 EEG 数据

            % Then export eventlist just for review
            % Save the processed EEG to disk because the next step will be averaging
            fprintf('\n\n\n**** %s: Artifact detection (moving window peak-to-peak and step function) ****\n\n\n', [fileList(i).name]);              

            % Artifact detection - Rd. 1
            %  Moving window. Test window = [-100
            % 798]; Threshold = 70 uV; Window width = 200 ms;
            % Window step = 50 ms; Channels = 1:64-2 data chanel (no M1 and M2); Flags to be activated =
            % 1 & 2 

            EEG = pop_artmwppth( EEG , ...
                                'Channel'     ,  1:62      , ...
                                'Flag'        , [ 1 2]     , ...
                                'Threshold'   ,  100       , ...
                                'Twindow'     , [-500.0  1000.0], ...
                                'Windowsize'  ,  200       , ...
                                'Windowstep'  ,  50        );
            EEG = eeg_checkset( EEG );
%             EEG  = pop_artextval( EEG , 'Channel',  1:62, 'Flag', [ 1 2], 'Threshold', [ -100 100], 'Twindow', [ -100 799] ); % absolute value 
%             % Artifact detection - Rd. 2
%             %  Moving window. Test window = [-100
%             % 798]; Threshold = 70 uV; Window width = 200 ms;
%             % Window step = 50 ms; Channels = 66 -2 (VEO) ; Flags to be activated =
%             % 1 & 3 

            EEG = pop_artmwppth( EEG , ...
                                'Channel'     ,  64      , ...
                                'Flag'        , [ 1 3]     , ...
                                'Threshold'   ,  100       , ...
                                'Twindow'     , [-500.0  1000.0], ...
                                'Windowsize'  ,  200       , ...
                                'Windowstep'  ,  50        );
            EEG = eeg_checkset( EEG );

            % Artifact detection - Rd. 3
            % Step-like artifacts in HEO channel(channel 65-2reference channel)
            % Threshold = 40 uV; Window width = 400 ms;
            % Window step = 10 ms; Flags to be activated = 1 & 4
            
            EEG = pop_artstep( EEG , ...
                               'Channel'   ,  63        , ... 
                               'Flag'      , [ 1 4]     , ...
                               'Threshold' ,  40        , ...
                               'Twindow'   , [-500.0  1000.0], ...
                               'Windowsize',  400       , ...
                               'Windowstep',  10        );

            EEG         = eeg_checkset( EEG );

            EEG = pop_saveset(EEG, 'filename', fileList(i).name, 'filepath', saveFolder);   % 保存剔除后的数据到指定文件夹

            pop_summary_AR_eeg_detection(EEG,[saveFolder fileList(i).name '_AR_summary.txt']);
            EEG = pop_exporteegeventlist(EEG, 'Filename', [saveFolder fileList(i).name '_eventlist_ar.txt']);          
            % Report percentage of rejected trials (collapsed across all bins)
            artifact_proportion = getardetection(EEG);
            fprintf('%s: Percentage of rejected trials was %1.2f\n', [fileList(i).name], artifact_proportion);

     %pause;

     
    disp(['处理完文件: ', fileList(i).name]);      % 提示用户继续
    end

    disp('所有文件处理完成。');



%% 6， 使用STUDY模块计算ERSP后，不关闭eeglab，用下述脚本保存数据（需在eeglab中载入STUDY数据后再运行）  
%%% yh revised
channel_labels = {ALLEEG(1,1).chanlocs.labels};
 
[STUDY, erspdata, times, freqs, events, params] = std_readdata(STUDY, ALLEEG, 'datatype', 'ersp', 'channels',channel_labels);

params.singletrials = 'off';
ersp_bl = newtimefbaseln(erspdata, times, params);
ersp_bl = cellfun(@(x)10*log10(x), ersp_bl, 'uniformoutput', false);


% 设置感兴趣的频段范围
freqs_roi = [4 30];  
% 设置感兴趣的时间段
times_roi = [0 700];

for i = 1:length(ersp_bl)
    ersp_temp = ersp_bl{i};
    ersp_roi{i} = mean(ersp_temp(freqs >= freqs_roi(1,1) & freqs < freqs_roi(1,2), times >= times_roi(1,1) & times < times_roi(1,2),:,:), [1,2]);
end

ersp1_roi = squeeze(ersp_roi{1})';
ersp2_roi = squeeze(ersp_roi{2})';

writecell([channel_labels; num2cell(ersp1_roi)],'ersp1_roi.xlsx');
writecell([channel_labels; num2cell(ersp2_roi)],'ersp2_roi.xlsx');


%%
clear all; close all; clc
%% 指定相关信息
File_Dir = uigetdir([],'Path to the data of one condition/group level'); 

con_name = inputdlg('The name of this condition');
con_name = con_name{1};

group_name = inputdlg('The name of this group');
group_name = group_name{1};

SavePath   = uigetdir([],'Path to store the results'); 

Files = dir(fullfile(File_Dir,'*.set'));
FileNames = {Files.name};

new_segmentation = inputdlg('New Segmentation?  True = 1 False = 0');
new_segmentation = str2num(new_segmentation{1});

if new_segmentation
    markers = inputdlg('Markers');
    epoch_limits = inputdlg('New epoch limits (in millisecond)');
    epoch_limits = str2num(epoch_limits{1})/1000;
end

new_filter = inputdlg('New band-pass filtering?  True = 1 False = 0');
new_filter = str2num(new_filter{1});

if new_filter    
    filter_limits = inputdlg('New band-pass filtering limits (in Hz)');
    filter_limits = str2num(filter_limits{1});
end


channels_selected = inputdlg('Write the index of channels to be analyzed');
channels_selected = str2num(channels_selected{1});

channels_mean = inputdlg('Mean selected channels?  True = 1 False = 0');
channels_mean = str2num(channels_mean{1});

erpcomponent_latency = inputdlg('The latencies of ERP component to be analyzed (in millisecond)');
erpcomponent_latency = str2num(erpcomponent_latency{1});

polarity = inputdlg('polarity of ERP component?  Postive = 1 Negative = 0');
polarity = str2num(polarity{1});

%%  7. ERP features

for i = 1:length(FileNames) 
    EEG = pop_loadset(FileNames{i}, File_Dir);
    
    if new_filter
        EEG = pop_eegfiltnew(EEG, filter_limits(1,1), filter_limits(1,2), [], 0, [], 0);
    end
        
    if new_segmentation
        EEG = pop_epoch( EEG, markers, epoch_limits, 'epochinfo', 'yes');
        EEG = pop_rmbase( EEG, [epoch_limits(1,1)*1000    0]);
    end
    
    erpdata = mean(EEG.data,3);    
    erpdata_selected = erpdata(channels_selected, EEG.times >= erpcomponent_latency(1,1) & EEG.times <= erpcomponent_latency(1,2));
    if channels_mean
        erpdata_selected = mean(erpdata_selected);
    end

    if polarity   
       [peak_amplitude_temp, peak_latency_temp] = max(erpdata_selected,[],2); 
    else
       [peak_amplitude_temp, peak_latency_temp] = min(erpdata_selected,[],2);  
    end
    
    idx = dsearchn(EEG.times', erpcomponent_latency(1,1));
    peak_latency_temp = EEG.times(1,idx + peak_latency_temp - 1)';
    
    mean_amplitude_temp = mean(erpdata_selected,2); 
      
    peak_amplitude(i,:) = double(peak_amplitude_temp)';
    peak_latency(i,:) = double(peak_latency_temp)';
    mean_amplitude(i,:) = double(mean_amplitude_temp)';
end

save(strcat(SavePath,filesep,'peak_amplitude_',group_name,'_',con_name,'.txt'),'peak_amplitude','-ascii')
save(strcat(SavePath,filesep,'peak_latency_',group_name,'_',con_name,'.txt'),'peak_latency','-ascii')    
save(strcat(SavePath,filesep,'mean_amplitude_',group_name,'_',con_name,'.txt'),'mean_amplitude','-ascii')    
    

%% EEGLab 函数大全

%载入原始数据（根据自己的厂家来）
EEG = pop_loadbv('E:\0\0leraning\36EEG\day1\36EEGB_day1\demo_task_data\step0_rawdata\', '1.vhdr', [1 439880], [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64]);
%载入set格式文件
EEG = pop_loadset('filename','sub001.set','filepath','E:\\0\\0leraning\\36EEG\\day1\\36EEGB_day1\\demo_task_data\\step1_raw2set\\');
%通道定位
EEG=pop_chanedit(EEG, 'lookup','E:\\0\\0leraning\\36EEG\\day1\\36EEGB_day1\\eeglab14_1_1b\\plugins\\dipfit2.3\\standard_BESA\\standard-10-5-cap385.elp');
%保存文件 
EEG = pop_saveset( EEG, 'filename','sub001.set','filepath','E:\\0\\0leraning\\36EEG\\day1\\36EEGB_day1\\demo_task_data\\step2_chanlocs\\');
%剔除无用电极
EEG = pop_select( EEG,'nochannel',{'HEO' 'VEO'});
%保存
EEG = pop_saveset( EEG, 'filename','sub001.set','filepath','E:\\0\\0leraning\\36EEG\\day1\\36EEGB_day1\\demo_task_data\\step3_rm_chan\\');
%plot通道位置图
% figure; topoplot([],EEG.chanlocs, 'style', 'blank',  'electrodes', 'labelpoint', 'chaninfo', EEG.chaninfo);
% figure; topoplot([],EEG.chanlocs, 'style', 'blank',  'electrodes', 'numpoint', 'chaninfo', EEG.chaninfo);
%高通滤波
EEG = pop_eegfiltnew(EEG, [], 0.1, 33000, true, [], 1);
%绘制频谱图
% figure; pop_spectopo(EEG, 1, [0  439879], 'EEG' , 'percent', 15, 'freq', [6 10 22], 'freqrange',[2 125],'electrodes','off');
%低通滤波
EEG = pop_eegfiltnew(EEG, [], 45, 294, 0, [], 1);
%绘制频谱图
% figure; pop_spectopo(EEG, 1, [0  439879], 'EEG' , 'percent', 15, 'freq', [6 10 22], 'freqrange',[2 100],'electrodes','off');
%凹陷滤波
EEG = pop_eegfiltnew(EEG, 48, 52, 1650, 1, [], 1);
%绘制频谱图
% figure; pop_spectopo(EEG, 1, [0  439879], 'EEG' , 'percent', 15, 'freq', [6 10 22], 'freqrange',[1 80],'electrodes','off');
EEG = pop_saveset( EEG, 'filename','sub001.set','filepath','E:\\0\\0leraning\\36EEG\\day1\\36EEGB_day1\\demo_task_data\\step4_filter\\');
%重采样
EEG = pop_resample( EEG, 500);
EEG = pop_saveset( EEG, 'filename','sub001.set','filepath','E:\\0\\0leraning\\36EEG\\day1\\36EEGB_day1\\demo_task_data\\step5_resample\\');
%polt data 
pop_eegplot( EEG, 1, 1, 1);
%分段
EEG = pop_epoch( EEG, {  '10'  '11'  }, [-1  2], 'newname', ' resampled epochs', 'epochinfo', 'yes');
%基线校正
EEG = pop_rmbase( EEG, [-1000     0]);
%删除反应marker为200的数据段
EEG = pop_selectevent( EEG, 'type',200,'deleteevents','off','deleteepochs','on','invertepochs','off');
%插值坏导
EEG = pop_interp(EEG, [13  42], 'spherical');
EEG = pop_saveset( EEG, 'filename','sub001.set','filepath','E:\\0\\0leraning\\36EEG\\day1\\36EEGB_day1\\demo_task_data\\step7_interpolate\\');
%删除坏段
EEG = pop_rejepoch( EEG, 86,0);
EEG = pop_saveset( EEG, 'filename','sub001.set','filepath','E:\\0\\0leraning\\36EEG\\day1\\36EEGB_day1\\demo_task_data\\step8_rm_epoch\\');
%run ICA
EEG = pop_runica(EEG, 'extended',1,'pca',60,'interupt','on');
EEG = pop_saveset( EEG, 'filename','sub001.set','filepath','E:\\0\\0leraning\\36EEG\\day1\\36EEGB_day1\\demo_task_data\\step9_runica\\');
%标记ICA成分
pop_selectcomps(EEG, [1:60] );
pop_prop( EEG, 0, [1:60], NaN, {'freqrange' [2 60] });
%去除成分
EEG = pop_subcomp( EEG, [1   3  31  34], 0);
%检查ICA成分
pop_selectcomps(EEG, [1:56] );
EEG = pop_subcomp( EEG, [9], 0);
EEG = pop_saveset( EEG, 'filename','sub001.set','filepath','E:\\0\\0leraning\\36EEG\\day1\\36EEGB_day1\\demo_task_data\\step10_rm_ic\\');
%去除极端值
EEG = pop_eegthresh(EEG,1,[1:62] ,-100,100,-1,1.998,0,1);
%重参考，双侧乳突
EEG = pop_reref( EEG, [33 43] );
EEG = pop_saveset( EEG, 'filename','sub001.set','filepath','E:\\0\\0leraning\\36EEG\\day1\\36EEGB_day1\\demo_task_data\\step12_ref\\');
