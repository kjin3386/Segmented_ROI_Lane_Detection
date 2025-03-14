%% fix the mean V Value for each segmented RoIs
%----------------------------------------------------------------------
%
% 변수 k 를 이용한 단순 계산으로 각 roi당 평균 조도값을 동일하게 조정.
% apply k variable for fixing each RoI's V value.
% 
% 원근법을 고려하여 roi 설정.
% set RoI considering perspective.
%----------------------------------------------------------------------

videoFile = 'Tunnelx10.mp4'; 
video = VideoReader(videoFile);

figure(1);

while hasFrame(video)
    % 프레임 읽기
    I = readFrame(video);
    I = imresize(I,[480 854]);
    gray_I = rgb2gray(I);
    hsv_image = rgb2hsv(I);
    [rows, cols] = size(gray_I);
    
    % 최종 이미지를 초기화 (원본 이미지와 같은 크기)
    combined_image = im2double(zeros(size(I), 'like', I));
    
    % 차선에 cols의 5~10% 가량의 여유분을 두어 픽셀값 설정
    % 좌측 차선의 시작점과 끝점
    P_L1 = [105, 480];
    P_L2 = [440, 320];
    
    % 우측 차선의 시작점과 끝점
    P_R1 = [750, 480];
    P_R2 = [505, 320];
    
    % 월드 좌표계에서의 간격 정의 (실제 계산에는 영향 X)
    world_L1 = [0, 0]; % 좌측 차선 시작점 월드 좌표
    world_L2 = [0, 100]; % 좌측 차선 끝점 월드 좌표
    world_R1 = [3.5, 0]; % 우측 차선 시작점 월드 좌표
    world_R2 = [3.5, 100]; % 우측 차선 끝점 월드 좌표
    
    % Homography 계산 (이미지 좌표 -> 월드 좌표)
    image_points = [P_L1; P_L2; P_R1; P_R2];
    world_points = [world_L1; world_L2; world_R1; world_R2];
    % 'projective' 타입으로 변환
    tform = fitgeotrans(world_points, image_points, 'projective');
    
    % 등분하기
    num_div = 5;
    
    % 좌측 차선 5등분 월드 좌표 계산
    left_line_world = [linspace(world_L1(1), world_L2(1), num_div); ...
                       linspace(world_L1(2), world_L2(2), num_div)]';
    
    % 우측 차선 5등분 월드 좌표 계산
    right_line_world = [linspace(world_R1(1), world_R2(1), num_div); ...
                        linspace(world_R1(2), world_R2(2), num_div)]';
    
    % 월드 좌표에서 이미지 좌표로 투영 (transformPointsForward 사용)
    [left_line_image_x, left_line_image_y] = transformPointsForward(tform, left_line_world(:, 1), left_line_world(:, 2));
    [right_line_image_x, right_line_image_y] = transformPointsForward(tform, right_line_world(:, 1), right_line_world(:, 2));

    
    % ROI 설정
    rois = cell(1, num_div-1);  % 5등분이므로 5개의 ROI가 생성됨
    
    % ROI 설정에 right_line_image와 left_line_image 좌표 추가
    for i = 1:(num_div - 1)
        rois{i} = struct( ...
            'bottom_left', [left_line_image_x(i), left_line_image_y(i)], ...
            'top_left', [left_line_image_x(i+1), left_line_image_y(i+1)], ...
            'top_right', [right_line_image_x(i+1), right_line_image_y(i+1)], ...
            'bottom_right', [right_line_image_x(i), right_line_image_y(i)] ...
        );
    end
    
    areas = zeros(1, numel(rois));  % 넓이를 저장할 배열

    for i = 1:numel(rois)
        % 각 ROI의 꼭짓점 좌표 추출
        x = [rois{i}.bottom_left(1), rois{i}.top_left(1), rois{i}.top_right(1), rois{i}.bottom_right(1)];
        y = [rois{i}.bottom_left(2), rois{i}.top_left(2), rois{i}.top_right(2), rois{i}.bottom_right(2)];
    
        % 다각형의 넓이 계산
        areas(i) = polyarea(x, y);
    end

    k_arr = [0 0 0 0 0];
    
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
        val_min = 0.75;     %임계 최저치 고정 (밝기변화 이용)
        
        roi_hsv_image(:,:,3) = roi_hsv_image(:,:,3) * k; %밝기값을 실시간적으로 변화
        
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
    %figure(2);
    %bar(k_arr);
    %ylim([0,5]);

    fprintf("\n\n");
    
    % roi별로 합쳐진 이미지 표시
    combined_image = rgb2gray(combined_image);
    figure(1);
    imshow(combined_image);
    figure(2);
    imshow(I);
    
    % 프레임 속도에 맞게 잠시 대기 (프레임 속도 조절)
    pause(1 / video.FrameRate);
    
end


%% sinle RoI for comparsion1.

%----------------------------------------------------
% k 값 미적용 
% didn't apply k value.
% 고정된 임계값 + 고정된 조도값 + 미분할 roi
% fixed threshold, fix V value, singe RoI
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
    sat_max = 0.2;      % 채도 범위

    val_max = 2;        % 명도 범위   
    val_min = 0.75;     %임계 최저치 고정 (밝기변화 이용)
        
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

%% single RoI for comparsion2.

%----------------------------------------------------
% k 값 적용
% Apply k variable.
% 고정된 임계값 + 변동되는 조도값 + 미분할 roi
% fixed threshold, unfixed V value, single RoI
%
%------------------------------------------

videoFile = 'Tunnelx10.mp4'; 
video = VideoReader(videoFile);

while hasFrame(video)
    % 프레임 읽기
    I = readFrame(video);
    I = imresize(I,[480 854]);
    gray_I = rgb2gray(I);
    hsv_image = rgb2hsv(I);
    [rows, cols] = size(gray_I);
    
    P_L1 = [110, 480];  % 좌측 차선 시작점
    P_L2 = [440, 320];  % 좌측 차선 끝점
    
    % 우측 차선의 시작점과 끝점
    P_R1 = [750, 480];  % 우측 차선 시작점
    P_R2 = [505, 320];  % 우측 차선 끝점
    
    % ROI 좌표 설정
    roi_x = [P_L1(1), P_L2(1), P_R1(1), P_R2(1)];
    roi_y = [P_L1(2), P_L2(2), P_R1(2), P_R2(2)];
    roi_mask = poly2mask(roi_x, roi_y, rows, cols);
    area = polyarea(roi_x, roi_y);

    %roi_val -> roi당 조도(value) 추출값
    %sum_val -> roi당 조도(value) 의 합
    roi_val = bsxfun(@times, hsv_image(:,:,3), cast(roi_mask, 'like', hsv_image(:,:,3))); 
    sum_val = sum(roi_val(:));

    % k 는 밝기의 평균값을 고정시키기 위한 변수
    k = (0.7*area) / sum_val;
    fprintf("area = %f, k = %f",area, k);

    % ROI적용
    hsv_image = bsxfun(@times, hsv_image, cast(roi_mask, 'like', hsv_image));


    % 흰색 범위 설정
    hue_min = 0;        % Hue 범위 (흰색에서는 Hue 값이 중요하지 않음)
    hue_max = 1;        % Hue 범위 (흰색에서는 Hue 값이 중요하지 않음)
    
    sat_min = 0;        % 채도 범위 (흰색의 경우 낮은 채도)
    sat_max = 0.2;      % 채도 범위

    val_max = 5;        % 명도 범위   
    val_min = 0.75;     %임계 최저치 고정 (밝기변화 이용)

    hsv_image(:,:,3) = hsv_image(:,:,3) * k;

    % 흰색 범위에 맞는 픽셀 검출
    mask = (hsv_image(:,:,1) >= hue_min) & (hsv_image(:,:,1) <= hue_max) & ...
           (hsv_image(:,:,2) >= sat_min) & (hsv_image(:,:,2) <= sat_max) & ...
           (hsv_image(:,:,3) >= val_min) & (hsv_image(:,:,3) <= val_max);
    
    % ROI 마스크 적용
    masked_image = bsxfun(@times, hsv_image, cast(hsv_image, 'like', hsv_image));
    % 필터링된 이미지를 RGB로 변환
    rgb_image = hsv2rgb(masked_image);
    filtered_image = rgb_image;

    imshow(filtered_image);
    
    fprintf("\n\n");
    
    
    
    % 프레임 속도에 맞게 잠시 대기 (프레임 속도 조절)
    pause(1 / video.FrameRate);
    
end
