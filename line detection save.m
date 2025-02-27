%% Camera Data / BlackBox real road data
% MP4 비디오 파일 읽기
videoFile = 'tunnel_blackbox.mp4'; % MP4 파일의 경로
video = VideoReader(videoFile);

% 비디오 프레임 처리
while hasFrame(video)
    % 프레임 읽기
    I = readFrame(video);
    
    % HSV 색 공간으로 변환
    hsv_image = rgb2hsv(I);
    
    
    % 흰색 범위 설정
    hue_min = 0;        % Hue 범위 (흰색에서는 Hue 값이 중요하지 않음)
    hue_max = 1;        % Hue 범위 (흰색에서는 Hue 값이 중요하지 않음)
    
    sat_min = 0;        % 채도 범위 (흰색의 경우 낮은 채도/기본값 0)
    sat_max = 0.1;      % 채도 범위 (기본값 0.3)
    
    val_min = 0.7;      % 명도 범위 (흰색의 경우 높은 명도/기본값 0.7)
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
    imshow(gray_image_roi);
    
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
    
    
    % 평균 조도값 계산
    mean_brightness = mean(gray_image_roi2(:));
    fprintf('평균 조도값 = %f\n', mean_brightness);
    
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
    P = houghpeaks(H, 5, 'threshold', ceil(0.05 * max(H(:))));
    lines = houghlines(edges, T, R, P, 'FillGap', 5, 'MinLength', 100);

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


%%
videoFile = 'tunnel_blackbox.mp4'; % MP4 파일의 경로
video = VideoReader(videoFile);

% 비디오 프레임 처리
while hasFrame(video)
    % 프레임 읽기
    I = readFrame(video);
    
    % HSV 색 공간으로 변환
    hsv_image = rgb2hsv(I);
    
    % 흰색 범위 설정
    hue_min = 0;        % Hue 범위 (흰색에서는 Hue 값이 중요하지 않음)
    hue_max = 1;        % Hue 범위 (흰색에서는 Hue 값이 중요하지 않음)
    
    sat_min = 0;        % 채도 범위 (흰색의 경우 낮은 채도/기본값 0)
    sat_max = 0.3;      % 채도 범위 (기본값 0.3)
    
    val_min = 0.1;      % 명도 범위 (흰색의 경우 높은 명도/기본값 0.7)
    val_max = 1;        % 명도 범위 (기본값 1)
    
    
    % 흰색 범위에 맞는 픽셀 검출
    mask = (hsv_image(:,:,1) >= hue_min) & (hsv_image(:,:,1) <= hue_max) & ...
           (hsv_image(:,:,2) >= sat_min) & (hsv_image(:,:,2) <= sat_max) & ...
           (hsv_image(:,:,3) >= val_min) & (hsv_image(:,:,3) <= val_max);
    
    % 마스크를 사용하여 흰색 차선만 추출. 원래 이미지에서 흰색만 표시
    filtered_image = bsxfun(@times, hsv_image, cast(mask, 'like', hsv_image));
    
    % 그레이 스케일로 변환 (명도 등은 기본값)
    gray_image = rgb2gray(filtered_image);
 
    imshow(gray_image)
    
end

%% roi 확인
    imshow(roi_mask);
    hold on;
    polt([bottom_left(1), top_left(1), top_right(1), bottom_right(1)], ...
         [bottom_left(2), top_left(2), top_right(2), bottom_right(2)], ... 
         'b', 'LineWidth', 2);
     hold off
