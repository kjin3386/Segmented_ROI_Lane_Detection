%% Camera Data / BlackBox real road data
% MP4 비디오 파일 읽기
videoFile = 'tunnel_blackbox.mp4'; % MP4 파일의 경로
video = VideoReader(videoFile);

% 비디오 프레임 처리
while hasFrame(video)
    % 프레임 읽기
    I = readFrame(video);
    
    gray_I = rgb2gray(I);
    
    % 이미지 크기 구하기
    [rows, cols] = size(gray_I);
    
    % 원거리 밝기 감지용 ROI 생성 (빨강)
    bottom_left = [cols * 0.4, rows * 0.5];
    bottom_right = [cols * 0.6, rows * 0.5];
    top_left = [cols * 0.45, rows * 0.4];
    top_right = [cols * 0.55, rows * 0.4];

    % 빨강 마스크 생성 및 사다리꼴 영역 설정
    roi_mask2 = poly2mask([bottom_left(1), top_left(1), top_right(1), bottom_right(1)], ...
                         [bottom_left(2), top_left(2), top_right(2), bottom_right(2)], ...
                         rows, cols);
    
    % ROI 마스크를 사용하여 이미지 필터링
    gray_image_roi2 = bsxfun(@times, gray_I, cast(roi_mask2, 'like', gray_I));

    % 평균 조도값 계산
    mean_brightness = mean(gray_image_roi2(:));
    fprintf('평균 조도값 = %f\n', mean_brightness);
   
    
    % HSV 색 공간으로 변환
    hsv_image = rgb2hsv(I);
    
    % 흰색 범위 설정
    hue_min = 0;        % Hue 범위 (흰색에서는 Hue 값이 중요하지 않음)
    hue_max = 1;        % Hue 범위 (흰색에서는 Hue 값이 중요하지 않음)
    
    sat_min = 0;        % 채도 범위 (흰색의 경우 낮은 채도/기본값 0)
    sat_max = 0.1;      % 채도 범위 (기본값 0.3)
    
    if mean_brightness < 0.6
        val_min = 0.2;      % 명도 범위 (흰색의 경우 높은 명도/기본값 0.7)
        hsv_image = imadjust(hsv_image,[0.3 0.7],[]);
        fprintf("어두움 감지");
    else
        val_min = 0.7;
        fprintf("평상시 밝기")
    end
    
    val_max = 1;        % 명도 범위 (기본값 1)
    
    % 흰색 범위에 맞는 픽셀 검출
    mask = (hsv_image(:,:,1) >= hue_min) & (hsv_image(:,:,1) <= hue_max) & ...
           (hsv_image(:,:,2) >= sat_min) & (hsv_image(:,:,2) <= sat_max) & ...
           (hsv_image(:,:,3) >= val_min) & (hsv_image(:,:,3) <= val_max);
    
    % 마스크를 사용하여 흰색 차선만 추출. 원래 이미지에서 흰색만 표시
    filtered_image = bsxfun(@times, hsv_image, cast(mask, 'like', hsv_image));
    
    filtered_image = hsv2rgb(filtered_image); 
    
    % 그레이 스케일로 변환 (명도 등은 기본값)
    gray_image = rgb2gray(filtered_image);
    
    imshow(gray_image)
    
    % 이미지 크기 구하기
    [rows, cols] = size(gray_image);
    
    % 현재 차선인지용 ROI 생성 (파랑)
    bottom_left = [cols * 0.1, rows * 0.9];
    bottom_right = [cols * 0.9, rows * 0.9];
    top_left = [cols * 0.4, rows * 0.5];
    top_right = [cols * 0.6, rows * 0.5];
    
    % 마스크 생성
    roi_mask = poly2mask([bottom_left(1), top_left(1), top_right(1), bottom_right(1)], ...
                         [bottom_left(2), top_left(2), top_right(2), bottom_right(2)], ...
                         rows, cols);
                     
    % ROI 마스크를 사용하여 이미지 필터링
    gray_image_roi = bsxfun(@times, gray_image, cast(roi_mask, 'like', gray_image));
    
    
    %
    %
    
    
    % 원거리 밝기 감지용 ROI 생성 (빨강)
    bottom_left = [cols * 0.4, rows * 0.5];
    bottom_right = [cols * 0.6, rows * 0.5];
    top_left = [cols * 0.45, rows * 0.4];
    top_right = [cols * 0.55, rows * 0.4];

    % 마스크 생성 및 사다리꼴 영역 설정
    roi_mask2 = poly2mask([bottom_left(1), top_left(1), top_right(1), bottom_right(1)], ...
                         [bottom_left(2), top_left(2), top_right(2), bottom_right(2)], ...
                         rows, cols);
                     
    % ROI 마스크를 사용하여 이미지 필터링
    gray_image_roi2 = bsxfun(@times, gray_image, cast(roi_mask2, 'like', gray_image));
    
    
    % ROI 영역을 영상에 합쳐서 표시
    I_roi_highlight = I;  % 원본 이미지 복사본
    
    % 첫 번째 ROI 마스크 적용
    I_roi_highlight(:,:,3) = I(:,:,3) + uint8(roi_mask) * 100;  % 파란색
    
    % 두 번째 ROI 마스크 적용
    I_roi_highlight(:,:,1) = I_roi_highlight(:,:,1) + uint8(roi_mask2) * 100; % 빨간색
    
    % 결과 이미지 표시
    %imshow(I_roi_highlight);  % ROI가 강조된 원본 이미지 표시
    
    hold on;
    
    % Canny edge detection으로 엣지검출 (ROI 영역에서만)
    edges = edge(gray_image_roi, 'Canny', [0.0, 0.1], 1.5);

    
    % Hough 변환
    [H, T, R] = hough(edges);
    P = houghpeaks(H, 4, 'threshold', ceil(0.15 * max(H(:))));
    lines = houghlines(edges, T, R, P, 'FillGap', 20, 'MinLength', 60);

    % 라인 그리기
    for k = 1:length(lines)
        xy = [lines(k).point1; lines(k).point2];
        plot(xy(:,1), xy(:,2), 'LineWidth', 2, 'Color', 'green');
        
        % 시작점과 끝점 표시
        plot(xy(1,1), xy(1,2), 'x', 'LineWidth', 2, 'Color', 'yellow');
        plot(xy(2,1), xy(2,2), 'x', 'LineWidth', 2, 'Color', 'red');
    end
    hold off
    
   
    
    % 프레임 속도에 맞게 잠시 대기 (프레임 속도 조절)
    pause(1 / video.FrameRate);
end


%% roi 확인

% 비디오 파일과 프레임 처리
videoFile = 'tunnel_blackbox.mp4'; 
video = VideoReader(videoFile);

while hasFrame(video)
    % 프레임 읽기
    I = readFrame(video);
    gray_I = rgb2gray(I);
    [rows, cols] = size(gray_I);

    % ROI 설정 및 평균 조도 계산 (원거리, 중거리, 근거리, 초근거리)
    rois = {
        struct('bottom_left', [cols * 0.4, rows * 0.5], 'top_left', [cols * 0.45, rows * 0.4], ...
               'top_right', [cols * 0.55, rows * 0.4], 'bottom_right', [cols * 0.6, rows * 0.5], 'color', 'red'),
        struct('bottom_left', [cols * 0.35, rows * 0.6], 'top_left', [cols * 0.4, rows * 0.5], ...
               'top_right', [cols * 0.6, rows * 0.5], 'bottom_right', [cols * 0.65, rows * 0.6], 'color', 'green'),
        struct('bottom_left', [cols * 0.25, rows * 0.7], 'top_left', [cols * 0.35, rows * 0.6], ...
               'top_right', [cols * 0.65, rows * 0.6], 'bottom_right', [cols * 0.75, rows * 0.7], 'color', 'blue'),
        struct('bottom_left', [cols * 0.1, rows * 0.9], 'top_left', [cols * 0.25, rows * 0.7], ...
               'top_right', [cols * 0.75, rows * 0.7], 'bottom_right', [cols * 0.9, rows * 0.9], 'color', 'yellow')
    };
    
    
    % ROI마다 처리 수행
    for i = 1:length(rois)
        roi = rois{i};
        roi_mask = poly2mask([roi.bottom_left(1), roi.top_left(1), roi.top_right(1), roi.bottom_right(1)], ...
                             [roi.bottom_left(2), roi.top_left(2), roi.top_right(2), roi.bottom_right(2)], ...
                             rows, cols);
        gray_image_roi = bsxfun(@times, I, cast(roi_mask, 'like', I));
        mean_brightness = mean(gray_image_roi(:));
        %fprintf('%s 거리 평균 조도값 = %f\n', roi.color, mean_brightness);
        
        
        % 흰색 검출
        filtered_image = hsv_white_detection(I, mean_brightness, roi_mask);
    end
    


    % 최종 이미지 표시
    %imshow(combined_image);
        
    end


function filtered_image = hsv_white_detection(I, mean_brightness, roi_mask)
    % HSV 색 공간으로 변환
    hsv_image = rgb2hsv(I);
    
    % 흰색 범위 설정
    hue_min = 0;        % Hue 범위 (흰색에서는 Hue 값이 중요하지 않음)
    hue_max = 1;        % Hue 범위 (흰색에서는 Hue 값이 중요하지 않음)
    
    sat_min = 0;        % 채도 범위 (흰색의 경우 낮은 채도)
    sat_max = 0.3;      % 채도 범위

    % 밝기에 따른 명도 범위 설정
    if mean_brightness < 0.1
        val_min = 0.2;  % 명도 범위 (어두운 경우)
        fprintf("어두움 감지\n");
    else
        val_min = 0.6;  % 명도 범위 (밝은 경우)
    end
    
    val_max = 1;        % 명도 범위
    
    % 흰색 범위에 맞는 픽셀 검출
    mask = (hsv_image(:,:,1) >= hue_min) & (hsv_image(:,:,1) <= hue_max) & ...
           (hsv_image(:,:,2) >= sat_min) & (hsv_image(:,:,2) <= sat_max) & ...
           (hsv_image(:,:,3) >= val_min) & (hsv_image(:,:,3) <= val_max);
    
    % ROI 마스크 적용
    masked_image = bsxfun(@times, hsv_image, cast(mask, 'like', hsv_image));
    masked_image = bsxfun(@times, masked_image, cast(roi_mask, 'like', masked_image));

    % 필터링된 이미지를 RGB로 변환
    rgb_image = hsv2rgb(masked_image);
    filtered_image = rgb2gray(rgb_image);
    
end

%% roi
%dd
% 비디오 파일과 프레임 처리
videoFile = 'tunnel_blackbox.mp4'; 
video = VideoReader(videoFile);

while hasFrame(video)
    % 프레임 읽기
    I = readFrame(video);
    gray_I = rgb2gray(I);
    [rows, cols] = size(gray_I);

    % 최종 이미지를 초기화 (원본 이미지와 같은 크기)
    combined_image = zeros(size(I), 'like', I);

    % ROI 설정 및 평균 조도 계산 (원거리, 중거리, 근거리, 초근거리)
    rois = {
        struct('bottom_left', [cols * 0.4, rows * 0.5], 'top_left', [cols * 0.45, rows * 0.4], ...
               'top_right', [cols * 0.55, rows * 0.4], 'bottom_right', [cols * 0.6, rows * 0.5], 'color', 'red'),
        struct('bottom_left', [cols * 0.35, rows * 0.6], 'top_left', [cols * 0.4, rows * 0.5], ...
               'top_right', [cols * 0.6, rows * 0.5], 'bottom_right', [cols * 0.65, rows * 0.6], 'color', 'green'),
        struct('bottom_left', [cols * 0.25, rows * 0.7], 'top_left', [cols * 0.35, rows * 0.6], ...
               'top_right', [cols * 0.65, rows * 0.6], 'bottom_right', [cols * 0.75, rows * 0.7], 'color', 'blue'),
        struct('bottom_left', [cols * 0.1, rows * 0.9], 'top_left', [cols * 0.25, rows * 0.7], ...
               'top_right', [cols * 0.75, rows * 0.7], 'bottom_right', [cols * 0.9, rows * 0.9], 'color', 'yellow')
    };
    
    % ROI마다 처리 수행
    for i = 1:length(rois)
        roi = rois{i};
        roi_mask = poly2mask([roi.bottom_left(1), roi.top_left(1), roi.top_right(1), roi.bottom_right(1)], ...
                             [roi.bottom_left(2), roi.top_left(2), roi.top_right(2), roi.bottom_right(2)], ...
                             rows, cols);
        gray_image_roi = bsxfun(@times, I, cast(roi_mask, 'like', I));
        mean_brightness = mean(gray_image_roi(:));
        
        % 흰색 검출
        filtered_image = hsv_white_detection(I, mean_brightness, roi_mask);
        
        % 각 ROI의 결과를 combined_image에 누적
        for c = 1:3  % RGB 각 채널에 대해 수행
            combined_image(:,:,c) = combined_image(:,:,c) + uint8(roi_mask) .* filtered_image;
        end
    end

    % 최종 이미지 표시
    imshow(combined_image);
end


function filtered_image = hsv_white_detection(I, mean_brightness, roi_mask)
    % HSV 색 공간으로 변환
    hsv_image = rgb2hsv(I);
    
    % 흰색 범위 설정
    hue_min = 0;        % Hue 범위 (흰색에서는 Hue 값이 중요하지 않음)
    hue_max = 1;        % Hue 범위 (흰색에서는 Hue 값이 중요하지 않음)
    
    sat_min = 0;        % 채도 범위 (흰색의 경우 낮은 채도)
    sat_max = 0.3;      % 채도 범위

    % 밝기에 따른 명도 범위 설정
    if mean_brightness < 0.1
        val_min = 0.2;  % 명도 범위 (어두운 경우)
        fprintf("어두움 감지\n");
    else
        val_min = 0.6;  % 명도 범위 (밝은 경우)
    end
    
    val_max = 1;        % 명도 범위
    
    % 흰색 범위에 맞는 픽셀 검출
    mask = (hsv_image(:,:,1) >= hue_min) & (hsv_image(:,:,1) <= hue_max) & ...
           (hsv_image(:,:,2) >= sat_min) & (hsv_image(:,:,2) <= sat_max) & ...
           (hsv_image(:,:,3) >= val_min) & (hsv_image(:,:,3) <= val_max);
    
    % ROI 마스크 적용
    masked_image = bsxfun(@times, hsv_image, cast(mask, 'like', hsv_image));
    masked_image = bsxfun(@times, masked_image, cast(roi_mask, 'like', masked_image));

    % 필터링된 이미지를 RGB로 변환
    rgb_image = hsv2rgb(masked_image);
    filtered_image = rgb2gray(rgb_image);
end
