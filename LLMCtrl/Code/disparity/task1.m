function [disparity, keyPoints, wPoints] = task1(w, mag, phase, frequencyRange, dB_flag, dB_conversion_percent, controlFactor)
    index_mag_180_up_start = find(w == frequencyRange(1, 1));
    index_mag_180_up_end = find(w == frequencyRange(1, 2));

    index_phase_0_down_start = find(w == frequencyRange(2, 1));
    index_phase_0_down_end = find(w == frequencyRange(2, 2));

    index_mag_180_down_start = find(w == frequencyRange(3, 1));
    index_mag_180_down_end = find(w == frequencyRange(3, 2));

    index_w_0_down_start = find(w == frequencyRange(4, 1));
    index_w_0_down_end = find(w == frequencyRange(4, 2));

    mag_180_up_low = -100;
    w_180_up_low = 1000;
    mag_180_up_low_exist = 0;
    index_mag_180_up_low = 1;
    
    for j = index_mag_180_up_start:index_mag_180_up_end

        if (mod(phase(j), 360) <= 180) && (mod(phase(j + 1), 360) >= 180) && (phase(j) < phase(j + 1)) % 上穿180
            w_180_up_low_vector(index_mag_180_up_low) = w(j);
            mag_180_up_low_vector(index_mag_180_up_low) = mag(j);
            index_mag_180_up_low = index_mag_180_up_low + 1;
            mag_180_up_low_exist = 1;
            break;
        end

    end
    
    if index_mag_180_up_low ~= 1
        [mag_180_up_low, index] = min(mag_180_up_low_vector);
        w_180_up_low = w_180_up_low_vector(index);
    else
        if (w_180_up_low == 1000 && mod(phase(1), 360) >= 180 && mod(phase(20), 360) <= 190)
            mag_180_up_low = mag(1);
            w_180_up_low = w(1);
            mag_180_up_low_exist = 1;
        end
    end
    
    w_0_down_low = 0; % 截频频率
    phase_0_down_low = -10;
    phase_0_down_low_exist = 0;
    
    for j = 1:index_w_0_down_end

        if (mag(j) >= 0) && (mag(j + 1) < 0)
            w_0_down_low = w(j);
            phase_0_down_low = mod(phase(j), 360) - 180;
            phase_0_down_low_exist = 1;
            break;
        end

    end

    mag_180_down_high = 50;
    w_mag_180_down_high = 0;
    mag_180_down_high_exist = 0;

    for j = index_mag_180_down_start:index_mag_180_down_end - 1

        if (mod(phase(j), 360) > 180) && (mod(phase(j + 1), 360) < 180) && (phase(j) > phase(j + 1)) % 下穿180
            w_mag_180_down_high = w(j);
            mag_180_down_high = mag(j);
            mag_180_down_high_exist = 1;
            break;
        end

    end

    normalRange = [0, 140; % 低频幅值裕度正常范围
                0, 60; % 低频相位裕度正常范围
                -50, 0]; % 高频幅值裕度正常范围

    flag_mag_180_up_low = (mag_180_up_low > controlFactor(1)) && (mag_180_up_low >= normalRange(1, 1)) && (mag_180_up_low <= normalRange(1, 2));
    flag_phase_0_down_low = (phase_0_down_low > controlFactor(2)) && (phase_0_down_low >= normalRange(2, 1)) && (phase_0_down_low <= normalRange(2, 2));
    flag_mag_180_down_high = (mag_180_down_high < controlFactor(3)) && (mag_180_down_high >= normalRange(3, 1)) && (mag_180_down_high <= normalRange(3, 2));
    flag_w_0_down_low = (w_0_down_low >= frequencyRange(4, 1)) && (w_0_down_low <= frequencyRange(4, 2));

    disparity = 0;

    if flag_mag_180_up_low && flag_phase_0_down_low && flag_mag_180_down_high && flag_w_0_down_low
        dB_conversion_percent = 1;
        disparity1 = 0 + (mag_180_up_low - controlFactor(1)) * dB_conversion_percent;
        disparity2 = 0 + phase_0_down_low - controlFactor(2);
        disparity3 = 0 - (mag_180_down_high - controlFactor(3)) * dB_conversion_percent;
        disparity = (disparity1 + disparity2 + disparity3);
    else

        if ~flag_mag_180_up_low
            if mag_180_up_low_exist == 0    % 不存在
                disparity = disparity - 10000;
            else
                if (mag_180_up_low - controlFactor(1)) < 0 % 小于要求
                    d = mag_180_up_low - controlFactor(1);
                    disparity = disparity + d * dB_conversion_percent;
                else % 大于上限
                    d = mag_180_up_low - normalRange(1, 2);
                    disparity = disparity - d * dB_conversion_percent;
                end
            end
        end

        if ~flag_phase_0_down_low
            if phase_0_down_low_exist == 0  % 不存在
                disparity = disparity - 10000;
            else
                if (phase_0_down_low - controlFactor(2)) < 0 % 小于要求
                    d = phase_0_down_low - controlFactor(2);
                    disparity = disparity + d;
                else % 大于上限
                    d = phase_0_down_low - normalRange(2, 2);
                    disparity = disparity - d;
                end
            end
        end

        if ~flag_mag_180_down_high
            
            if mag_180_down_high_exist == 0 % 不存在
                disparity = disparity - 10000;
            else
                if (mag_180_down_high - controlFactor(3)) > 0 % 大于要求
                    d = mag_180_down_high - controlFactor(3);
                    disparity = disparity - d * dB_conversion_percent;
                else % 小于下限
                    d = mag_180_down_high - normalRange(3, 1);
                    disparity = disparity + d * dB_conversion_percent;
                end
            end
        end

        if ~flag_w_0_down_low
            disparity = disparity - abs(min(w_0_down_low - frequencyRange(4, 1), w_0_down_low - frequencyRange(4, 2)));
        end

    end

    keyPoints = [mag_180_up_low, phase_0_down_low, mag_180_down_high, w_0_down_low];
    
    wPoints = [w_180_up_low, w_0_down_low, w_mag_180_down_high, w_0_down_low];

    disparity = -disparity;
