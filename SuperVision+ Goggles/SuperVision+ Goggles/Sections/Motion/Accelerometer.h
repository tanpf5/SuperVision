//
//  Accelerometer.h
//  SuperVision+ Goggles
//
//  Created by Pengfei Tan on 7/2/15.
//  Copyright (c) 2015 Massachusetts Eye and Ear Infirmary. All rights reserved.
//

#ifndef __SuperVision__Goggles__Accelerometer__
#define __SuperVision__Goggles__Accelerometer__

#import <CoreMotion/CoreMotion.h>
#import <GLKit/GLKit.h>

#include <vector>

namespace SuperVision
{
    
    NSString *const AccelerometerDidDoubleTapNotification = @"AccelerometerDidDoubleTapNotification";
    
    class Accelerometer
    {
    public:
        Accelerometer();
        virtual ~Accelerometer() {}
        void start();
        void stop();
        float getCurrent();
        
    private:
        CMMotionManager *_manager;
        size_t _sampleIndex;
        float _baseline;
        float _current_z;
        std::vector<float> _sensorData;
        std::vector<float> _offsets;
        
        
        void addData(float value);
        void updateCurrent(float value);
        void evaluateModel();
        int checkTap();
        float meanOf(size_t start, int n);
        float std(size_t start, int n);
        
    };
    
}

#endif /* defined(__SuperVision__Goggles__Accelerometer__) */
