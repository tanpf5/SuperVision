//
//  Accelerometer.cpp
//  SuperVision+ Goggles
//
//  Created by Pengfei Tan on 7/2/15.
//  Copyright (c) 2015 Massachusetts Eye and Ear Infirmary. All rights reserved.
//

#include "Accelerometer.h"

#include <algorithm>


//  doubleTap
#define FREQUENCY 100
#define TIME_THRESHOLD 0.6
#define TAP_WND 60
#define GAP_WND 30
#define TOTAL_WND 90

#define STABLE_THRESHOLD 0.01
#define FLUC_THRESHOLD 0.05
#define HIT_THRESHOLD 15
#define TAPWIDTH_THRESHOLD 6

namespace SuperVision
{
    
    Accelerometer::Accelerometer() :
    _sampleIndex(0),
    _sensorData(TOTAL_WND),
    _offsets(TOTAL_WND)
    {
        _manager = [[CMMotionManager alloc] init];
    }
    
    void Accelerometer::start()
    {
        if (_manager.isAccelerometerAvailable && !_manager.isAccelerometerActive)
        {
            _manager.accelerometerUpdateInterval = 1.0f / FREQUENCY;
            NSOperationQueue *acclerometerQueue = [[NSOperationQueue alloc] init];
            [_manager startAccelerometerUpdatesToQueue:acclerometerQueue
                                           withHandler:^(CMAccelerometerData* accelerometerData, NSError *error)
             {
                 addData((float) -accelerometerData.acceleration.y);
             }];
        }
    }
    
    void Accelerometer::stop()
    {
        [_manager stopAccelerometerUpdates];
    }
    
    void Accelerometer::addData(float value)
    {
        _sensorData[_sampleIndex % TOTAL_WND] = value;
        _baseline = value;
        ++_sampleIndex;
        evaluateModel();
    }
    
    int Accelerometer::checkTap()
    {
        size_t n = _sampleIndex + GAP_WND - 1;
        float fluc = std(_sampleIndex, GAP_WND);
        if (fluc < STABLE_THRESHOLD) {
            float stable_mean = meanOf(_sampleIndex, GAP_WND);
            if (fabs(_sensorData[(n + 1) % TOTAL_WND] - stable_mean) > HIT_THRESHOLD * fluc && std(n + 1, TAP_WND) > FLUC_THRESHOLD) {
                std::vector<float> probedata0(TAP_WND);
                for (size_t i = n + 1; i < n + 1 + TAP_WND; i++) {
                    probedata0[i - n - 1] = _sensorData[i % TOTAL_WND] - stable_mean > 0? _sensorData[i % TOTAL_WND] - stable_mean: 0;
                }
                std::vector<float> probedata(TAP_WND);
                for (int i = 0; i < probedata0.size(); i++) {
                    if (i == 0 || i == probedata0.size() - 1) {
                        probedata[i] = probedata0[i];
                    } else {
                        probedata[i] = probedata0[i - 1] * 0.25 + probedata0[i] * 0.5 + probedata0[i + 1] * 0.25;
                    }
                }
                bool started = false;
                int start = 0, end = 0, count = 0;
                for (int i = 0; i < probedata.size(); i++) {
                    if (!started && probedata[i] > HIT_THRESHOLD * fluc) {
                        started = true;
                        start = i;
                    }
                    if (started && probedata[i] <= HIT_THRESHOLD * fluc) {
                        started = false;
                        end = i;
                        if (end - start > TAPWIDTH_THRESHOLD)
                            return 0;
                        else {
                            count++;
                        }
                    }
                }
                return count;
            }
        }
        return 0;
    }
    
    void Accelerometer::evaluateModel()
    {
        if (_sampleIndex < (TOTAL_WND))
        {
            return;
        }
        
        int n = checkTap();
        
        if (n >= 2)
        {
            NSLog(@"n = %d", n);
            _sampleIndex = 0;
            [[NSNotificationCenter defaultCenter] postNotificationName:DoubleTapsNotification object:nil];
        }
    }
    
    float Accelerometer::meanOf(size_t start, int n)
    {
        float runningTotal = 0.0;
        for (int i = 0; i < n; i++)
        {
            runningTotal += _sensorData[(start + i) % TOTAL_WND];
        }
        return runningTotal / n;
    }
    
    float Accelerometer::std(size_t start, int n)
    {
        if (n == 0 && n == 1) return 0;
        
        float mean = meanOf(start, n);
        float sumOfSquaredDifferences = 0.0;
        
        for (int i = 0; i < n; i++)
        {
            float valueOfNumber = _sensorData[(start + i) % TOTAL_WND];
            float difference = valueOfNumber - mean;
            sumOfSquaredDifferences += difference * difference;
        }
        return sqrt(sumOfSquaredDifferences / (n - 1));
    }
    
}