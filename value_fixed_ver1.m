%% 평균 조도값 고정 버전
%----------------------------------------------------------------------
%
% 변수 k 를 이용한 단순 계산으로 각 roi당 평균 
% 조도값을 동일하게 실시간 조정.
%
% 일종의 feed-back 시스템이 될 수 있음.
%
%----------------------------------------------------------------------

videoFile = 'Tunnelx10.mp4'; 
video = VideoReader(videoFile);

figure(1);
figure(2);

while hasFrame(video)
    % 프레임 읽기
    I = readFrame(video);
    I = imresize(I,[540 960]);
    gray_I = rgb2gray(I);
    hsv_image = rgb2hsv(I);
    [rows, cols] = size(gray_I);
    
    % 최종 이미지를 초기화 (원본 이미지와 같은 크기)
    combined_image = im2double(zeros(size(I), 'like', I));
    

    % ROI 설정 및 평균 조도 계산 (원거리, 중거리, 근거리, 초근거리)
    rois = {
        struct('bottom_left', [cols * 0.45, rows * 0.7], 'top_left', [cols * 0.5, rows * 0.66], ...
               'top_right', [cols * 0.6, rows * 0.66], 'bottom_right', [cols * 0.65, rows * 0.7], 'color', 'red'),
        struct('bottom_left', [cols * 0.35, rows * 0.8], 'top_left', [cols * 0.45, rows * 0.7], ...
               'top_right', [cols * 0.65, rows * 0.7], 'bottom_right', [cols * 0.75, rows * 0.8], 'color', 'green'),
        struct('bottom_left', [cols * 0.25, rows * 0.9], 'top_left', [cols * 0.35, rows * 0.8], ...
               'top_right', [cols * 0.75, rows * 0.8], 'bottom_right', [cols * 0.85, rows * 0.9], 'color', 'blue'),
        struct('bottom_left', [cols * 0.1, rows * 1], 'top_left', [cols * 0.25, rows * 0.9], ...
               'top_right', [cols * 0.85, rows * 0.9], 'bottom_right', [cols * 0.95, rows * 1], 'color', 'yellow')
    };
    
    
    areas = zeros(1, numel(rois));  % 넓이를 저장할 배열

    for i = 1:numel(rois)
        % 각 ROI의 꼭짓점 좌표 추출
        x = [rois{i}.bottom_left(1), rois{i}.top_left(1), rois{i}.top_right(1), rois{i}.bottom_right(1)];
        y = [rois{i}.bottom_left(2), rois{i}.top_left(2), rois{i}.top_right(2), rois{i}.bottom_right(2)];
    
        % 다각형의 넓이 계산
        areas(i) = polyarea(x, y);
    end

    k_arr = [0 0 0 0];
    
    % ROI마다 처리 수행
    for i = 1:length(rois)
        roi = rois{i};
        roi_mask = poly2mask([roi.bottom_left(1), roi.top_left(1), roi.top_right(1), roi.bottom_right(1)], ...
                             [roi.bottom_left(2), roi.top_left(2), roi.top_right(2), roi.bottom_right(2)], ...
                             rows, cols);
        
        %roi_hsv_image -> roi처리된 hsv 이미지
        roi_hsv_image = bsxfun(@times, hsv_image, cast(roi_mask, 'like', hsv_image)); 
        
        %roi_val -> roi당 조도(value) 추출값
        %sum_val -> roi당 조도(value) 의 합
        roi_val = bsxfun(@times, hsv_image(:,:,3), cast(roi_mask, 'like', hsv_image(:,:,3))); 
        sum_val = sum(roi_val(:));
        
        % k 는 밝기의 평균값을 고정시키기 위한 변수
        k = (0.7*areas(i)) / sum_val;
        
        fprintf("%d 번째 roi / k = %f", i, k);

        % 흰색 범위 설정
        hue_min = 0;        % Hue 범위 (흰색에서는 Hue 값이 중요하지 않음)
        hue_max = 1;        % Hue 범위 (흰색에서는 Hue 값이 중요하지 않음)
    
        sat_min = 0;        % 채도 범위 (흰색의 경우 낮은 채도)
        sat_max = 0.2;      % 채도 범위

        val_max = 2;        % 명도 범위   
        val_min = 0.77;     %임계 최저치 고정 (밝기변화 이용)

        roi_hsv_image(:,:,3) = roi_hsv_image(:,:,3) * k; %밝기값을 실시간적으로 변화
        
        % if k < 0.9
        %     fprintf(" / 임계값 낮춤");
        %     val_min = val_min - 0.07;
        % elseif k > 1.6
        %     fprintf(" / 임계값 높임");
        %     val_min = val_min + 0.07;
        % end
        
        k_arr(i) = k;

        % 흰색 범위에 맞는 픽셀 검출
        mask = (roi_hsv_image(:,:,1) >= hue_min) & (roi_hsv_image(:,:,1) <= hue_max) & ...
               (roi_hsv_image(:,:,2) >= sat_min) & (roi_hsv_image(:,:,2) <= sat_max) & ...
               (roi_hsv_image(:,:,3) >= val_min) & (roi_hsv_image(:,:,3) <= val_max);
        
        % ROI 마스크 적용
        %~cast(a,'like',b))~ 에서 a값 변경.
        masked_image = bsxfun(@times, roi_hsv_image, cast(mask, 'like', roi_hsv_image));
        % 필터링된 이미지를 RGB로 변환
        rgb_image = hsv2rgb(masked_image);
        filtered_image = rgb_image;

        doubled_image = im2double(filtered_image);
        combined_image = combined_image + filtered_image;
        fprintf("\n");
    end
    figure(2);
    bar(k_arr);
    ylim([0,3]);

    fprintf("\n\n");
    
    % roi별로 합쳐진 이미지 표시
    combined_image = rgb2gray(combined_image);
    %edges = edge(combined_image, 'Canny', [0.1, 0.3], 3);
    figure(1);
    imshow(combined_image);
    % figure(2);
    % imshow(I);
    

    
    % 프레임 속도에 맞게 잠시 대기 (프레임 속도 조절)
    pause(1 / video.FrameRate);
    
end


%% segment roi 미적용 (비교분석 용)

%----------------------------------------------------
% k 값 미적용 
%
% 고정된 임계값 + 고정된 조도값 + 미분할 roi
%
%
%------------------------------------------

videoFile = 'Tunnelx10.mp4'; 
video = VideoReader(videoFile);

while hasFrame(video)
    % 프레임 읽기0
    I = readFrame(video);
    gray_I = rgb2gray(I);
    hsv_image = rgb2hsv(I);
    [rows, cols] = size(gray_I);
    
    roi = {
     struct('bottom_left', [cols * 0.1, rows * 1], 'top_left', [cols * 0.5, rows * 0.63], ...
            'top_right', [cols * 0.6, rows * 0.63], 'bottom_right', [cols * 0.95, rows * 1])
               };


    roi_x = [cols*0.1 cols*0.5 cols*0.6 cols*0.95];
    roi_y = [rows rows*0.63 rows*0.63 rows];
    roi_mask = poly2mask(roi_x, roi_y, rows, cols);

    % ROI적용
    hsv_image = bsxfun(@times, hsv_image, cast(roi_mask, 'like', hsv_image));


    % 흰색 범위 설정
    hue_min = 0;        % Hue 범위 (흰색에서는 Hue 값이 중요하지 않음)
    hue_max = 1;        % Hue 범위 (흰색에서는 Hue 값이 중요하지 않음)
    
    sat_min = 0;        % 채도 범위 (흰색의 경우 낮은 채도)
    sat_max = 0.5;      % 채도 범위

    val_max = 1;        % 명도 범위   
    val_min = 0.77;     %임계 최저치 고정 (밝기변화 이용)
        
    % 흰색 범위에 맞는 픽셀 검출
    mask = (hsv_image(:,:,1) >= hue_min) & (hsv_image(:,:,1) <= hue_max) & ...
            (hsv_image(:,:,2) >= sat_min) & (hsv_image(:,:,2) <= sat_max) & ...
            (hsv_image(:,:,3) >= val_min) & (hsv_image(:,:,3) <= val_max);
    
    % ROI 마스크 적용
    masked_image = bsxfun(@times, hsv_image, cast(mask, 'like', hsv_image));
    % 필터링된 이미지를 RGB로 변환
    rgb_image = hsv2rgb(masked_image);
    filtered_image = rgb_image;

    imshow(filtered_image);
             
    fprintf("\n\n");
    
    
    
    % 프레임 속도에 맞게 잠시 대기 (프레임 속도 조절)
    pause(1 / video.FrameRate);
    
end

%% segment roi 미적용2 (비교분석 용)

%----------------------------------------------------
% k 값 적용
%
% 고정된 임계값 + 변동되는 조도값 + 미분할 roi
%
%
%------------------------------------------

videoFile = 'Tunnelx10.mp4'; 
video = VideoReader(videoFile);

while hasFrame(video)
    % 프레임 읽기0
    I = readFrame(video);
    gray_I = rgb2gray(I);
    hsv_image = rgb2hsv(I);
    [rows, cols] = size(gray_I);
    
    roi = {
     struct('bottom_left', [cols * 0.1, rows * 1], 'top_left', [cols * 0.5, rows * 0.63], ...
            'top_right', [cols * 0.6, rows * 0.63], 'bottom_right', [cols * 0.95, rows * 1])
               };


    roi_x = [cols*0.1 cols*0.5 cols*0.6 cols*0.95];
    roi_y = [rows rows*0.63 rows*0.63 rows];
    roi_mask = poly2mask(roi_x, roi_y, rows, cols);
    area = polyarea(roi_x, roi_y);

    %roi_val -> roi당 조도(value) 추출값
    %sum_val -> roi당 조도(value) 의 합
    roi_val = bsxfun(@times, hsv_image(:,:,3), cast(roi_mask, 'like', hsv_image(:,:,3))); 
    sum_val = sum(roi_val(:));

    % k 는 밝기의 평균값을 고정시키기 위한 변수
    k = (0.7*area) / sum_val;
    fprintf("k = %f", k);

    % ROI적용
    hsv_image = bsxfun(@times, hsv_image, cast(roi_mask, 'like', hsv_image));


    % 흰색 범위 설정
    hue_min = 0;        % Hue 범위 (흰색에서는 Hue 값이 중요하지 않음)
    hue_max = 1;        % Hue 범위 (흰색에서는 Hue 값이 중요하지 않음)
    
    sat_min = 0;        % 채도 범위 (흰색의 경우 낮은 채도)
    sat_max = 0.5;      % 채도 범위

    val_max = 2;        % 명도 범위   
    val_min = 0.77;     %임계 최저치 고정 (밝기변화 이용)

    hsv_image = hsv_image * k;

    % 흰색 범위에 맞는 픽셀 검출
    mask = (hsv_image(:,:,1) >= hue_min) & (hsv_image(:,:,1) <= hue_max) & ...
           (hsv_image(:,:,2) >= sat_min) & (hsv_image(:,:,2) <= sat_max) & ...
           (hsv_image(:,:,3) >= val_min) & (hsv_image(:,:,3) <= val_max);
    
    % ROI 마스크 적용
    masked_image = bsxfun(@times, hsv_image, cast(mask, 'like', hsv_image));
    % 필터링된 이미지를 RGB로 변환
    rgb_image = hsv2rgb(masked_image);
    filtered_image = rgb_image;

    imshow(filtered_image);
    
    fprintf("\n\n");
    
    
    
    % 프레임 속도에 맞게 잠시 대기 (프레임 속도 조절)
    pause(1 / video.FrameRate);
    
end
