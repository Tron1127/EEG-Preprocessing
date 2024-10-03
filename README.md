# EEG-Preprocessing

# Including All Preprocessing Steps： 

%%  1.  导入滤波剔电极重参考  
%%  2. 截取前后段跑ICA
%%  3.1 ICLabel辅助ICA剔除（自动）
%%  3.2 ICLabel辅助ICA剔除(手动)   128 data - 1-2days
%%  4. 创建Eventlist，根据binlister分段基线校正 2h
%%  5.  尾迹检测和识别 2 rounds of artifact detection
