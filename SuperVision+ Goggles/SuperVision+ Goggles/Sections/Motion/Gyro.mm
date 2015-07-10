//
//  Gyro.cpp
//  SuperVision+ Goggles
//
//  Created by Pengfei Tan on 7/6/15.
//  Copyright (c) 2015 Massachusetts Eye and Ear Infirmary. All rights reserved.
//

#include "Gyro.h"
#include "ViewController.h"

#include <algorithm>

#define STABLE_THRESHOLD_GYRO 0.01
#define MINCHANGE 0.015
#define MAXCHANGE 0.03

namespace SuperVision
{
    
    Gyro::Gyro() :
    _sampleIndex(0),
    _sensorData(numberOfSamples),
    _x_offset(0),
    _y_offset(0),
    _x_number(0),
    _y_number(0),
    isUpAndDown(false),
    isLeftAndRight(false)
    {
        _manager = [[CMMotionManager alloc] init];
    }
    
    void Gyro::start()
    {
        if (_manager.isGyroAvailable && !_manager.isGyroActive)
        {
            _manager.gyroUpdateInterval = 1.0f / frequency;
            NSOperationQueue *gyroQueue = [[NSOperationQueue alloc] init];
            [_manager startGyroUpdatesToQueue:gyroQueue
                                           withHandler:^(CMGyroData* gyroData, NSError *error)
             {
                 addData(GLKVector3Make(
                                        (float) gyroData.rotationRate.x,
                                        (float) gyroData.rotationRate.y,
                                        (float) gyroData.rotationRate.z));
                 //NSLog(@"x = %.05f, y = %.05f", gyroData.rotationRate.x, gyroData.rotationRate.y);
             }];
        }
    }
    
    void Gyro::stop()
    {
        [_manager stopGyroUpdates];
    }
    
    void Gyro::startUpAndDown()
    {
        isUpAndDown = true;
    }
    
    void Gyro::stopUpAndDown()
    {
        isUpAndDown = false;
    }
    
    void Gyro::startLeftAndRight()
    {
        isLeftAndRight = true;
    }
    
    void Gyro::stopLeftAndRight()
    {
        isLeftAndRight = false;
    }
    
    void Gyro::addData(GLKVector3 value)
    {
        _sensorData[_sampleIndex % numberOfSamples] = value;
        computeOffsets();
        if (isLeftAndRight) {
            valueChanged(true);
        }
        if (isUpAndDown) {
            valueChanged(false);
        }
        ++_sampleIndex;
    }
    
    void Gyro::computeOffsets()
    {
        if (_sampleIndex < numberOfSamples || _x_number >= 100000 || _y_number >= 100000)
        {
            return;
        }
        if (std(_sampleIndex, numberOfSamples, true) <= STABLE_THRESHOLD_GYRO && std(_sampleIndex, numberOfSamples, false)) {
            float mean_x = meanOf(_sampleIndex, numberOfSamples, true);
            float mean_y = meanOf(_sampleIndex, numberOfSamples, false);
            _x_offset = (_x_offset * _x_number + mean_x * numberOfSamples) / (_x_number + numberOfSamples);
            _x_number = _x_number + numberOfSamples;
            _y_offset = (_y_offset * _y_number + mean_y * numberOfSamples) / (_y_number + numberOfSamples);
            _y_number = _y_number + numberOfSamples;
        }
    }
    
    void Gyro::valueChanged(bool isX)
    {
        double first = isX ? _sensorData[(_sampleIndex - 1) % numberOfSamples].x : _sensorData[(_sampleIndex - 1) % numberOfSamples].y;
        double second = isX ? _sensorData[_sampleIndex % numberOfSamples].x : _sensorData[_sampleIndex % numberOfSamples].y;
        double result = second - first;
        if (fabs(result) > MINCHANGE && fabs(result) < MAXCHANGE) {
            if (isX) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSDictionary *userInfo = @{@"Value":[[NSNumber alloc] initWithDouble:second - _x_offset]};
                    [[NSNotificationCenter defaultCenter] postNotificationName:GyroDidMoveLeftAndRightNotification object:nil userInfo:userInfo];
                });
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSDictionary *userInfo = @{@"Value":[[NSNumber alloc] initWithDouble:second - _y_offset]};
                    [[NSNotificationCenter defaultCenter] postNotificationName:GyroDidMoveUpAndDownNotification object:nil userInfo:userInfo];
                });
            }
        }
    }
    
    float Gyro::meanOf(size_t start, int n, bool isX)
    {
        float runningTotal = 0.0;
        for (int i = 0; i < n; i++)
        {
            runningTotal += isX ? _sensorData[(start + i) % numberOfSamples].x : _sensorData[(start + i) % numberOfSamples].y;
        }
        return runningTotal / n;
    }
    
    float Gyro::std(size_t start, int n, bool isX)
    {
        if (n == 0 && n == 1) return 0;
        
        float mean = meanOf(start, n, isX);
        float sumOfSquaredDifferences = 0.0;
        
        for (int i = 0; i < n; i++)
        {
            float valueOfNumber = isX ? _sensorData[(start + i) % numberOfSamples].x : _sensorData[(start + i) % numberOfSamples].y;
            float difference = valueOfNumber - mean;
            sumOfSquaredDifferences += difference * difference;
        }
        return sqrt(sumOfSquaredDifferences / (n - 1));
    }
    
}