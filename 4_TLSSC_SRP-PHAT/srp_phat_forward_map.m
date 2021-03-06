function [max_srp_index, maxCount]= srp_phat_forward_map(f, ...   % M by T matrix
                                               TDOA_table)
% f为MIC数的音频，每一行一个MIC的一帧数据
% 采样一帧数据进行定位
% Reference:
% J. Dmochowski, J. Benesty, and S. Affes, "A generalized steered response 
% power method for computationally viable source localization," 
% IEEE Transactions on Audio, Speech, and Language Processing, vol. 15, 
% pp. 2510-2526, 2007.
%                                
% Release date: May 2015
% Author: Taewoo Lee, (twlee@speech.korea.ac.kr)
%
% Copyright (C) 2015 Taewoo Lee
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program. If not, see <http://www.gnu.org/licenses/>.

% MIC数
M= size(f,1);
% MIC对数
N= M*(M-1)/2;
% 一帧数据的采样点数
T= size(f,2);
% TDOA表格进行过转置，所以这里的列就是之前的行，代表搜索点数 
Q= size(TDOA_table,2);

% GCC-PHAT
% 和f一样的矩阵
X= zeros(M,T);
for m=1:M
    % 对之前音频的每一行做fft变换，所有值都变成了复数了
    X(m,:)= fft(f(m,:));
    % 这里除以每个元素的模，得到就是单位矩阵了
    % 论文里好像没有单位化啊
    % 哦哦单位化是因为加上了滤波函数，1/Gij
    X(m,:)= X(m,:)./abs(X(m,:));
end     
Z= zeros(N,T);
p= 0;
for m1=1:M-1
    for m2=m1+1:M
        % 对没对音频操作
        p= p+1;
        % conj取共轭
        % m1行.*m2行的共轭表示什么意思?
        % 没两行进行某种操作
        % 计算m1m2的互功率谱
        Z(p,:)= X(m1,:).*conj(X(m2,:));
    end
end
R= zeros(N,T);
for p=1:N
    % 还不太明白运算的原理
    % 先假设得到了这N MIC对的交互数据
    R(p,:)= fftshift(real(ifft(Z(p,:))));
end
save('f.mat', 'f');
save('R.mat', 'R');

% SRP (full search or forward map)
% 1/2采样点数
center= T/2+1;
srp_global= zeros(Q,1);
% 搜索点的个数
for q=1:Q
    srp_local= 0;
    % 遍历MIC对数
    for p=1:N
        % +center啥意思?
        % 某一个搜索点的第一对MIC TDOA值
        % 这里的计算是个难点，需要好好理解
        % 这里的center只是作为一个参考点，防止左右移动点时超出了一帧的范围，这样也就无法取得对应的R值
        tau_qp= TDOA_table(p,q) + center;
        % R矩阵是MIC对*T的矩阵，tau_qp是指第tau_qp个处理后的数据
        % 还不太懂
        srp_local= srp_local + R(p,tau_qp);
    end
    % 第q个搜索点所对应的功率
    srp_global(q,1)= srp_local;
end

save('srp_global.mat', 'srp_global')
% 这里返回的就是在TDOA中的索引，也是在坐标表格中的索引
% 第一个是值，第二个是索引
maxCount= 1;
[max_srp, max_srp_index(1)]= max(srp_global);
srp_global(max_srp_index(1))= 0;
maxCount= maxCount + 1;
[max_srp_tmp, max_srp_index(maxCount)]= max(srp_global);
while max_srp == max_srp_tmp
    srp_global(max_srp_index(maxCount))= 0;
    maxCount= maxCount + 1;
    [max_srp_tmp, max_srp_index(maxCount)]= max(srp_global);
end

maxCount= maxCount - 1;
% max_srp_index

% [~,max_srp_index]= max(srp_global);
