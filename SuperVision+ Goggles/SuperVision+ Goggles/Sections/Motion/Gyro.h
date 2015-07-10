//
//  Gyro.h
//  SuperVision+ Goggles
//
//  Created by Pengfei Tan on 7/6/15.
//  Copyright (c) 2015 Massachusetts Eye and Ear Infirmary. All rights reserved.
//

#ifndef __SuperVision__Goggles__Gyro__
#define __SuperVision__Goggles__Gyro__

#import <CoreMotion/CoreMotion.h>
#import <GLKit/GLKit.h>

#include <vector>

namespace SuperVision
{
    NSString *const GyroDidMoveUpAndDownNotification = @"GyroDidMoveUpAndDownNotification";
    NSString *const GyroDidMoveLeftAndRightNotification = @"GyroDidMoveLeftAndRightNotification";
    
    class Gyro
    {
    public:
        Gyro();
        virtual ~Gyro() {}
        void start();
        void stop();
        void startUpAndDown();
        void stopUpAndDown();
        void startLeftAndRight();
        void stopLeftAndRight();
        
    private:
        CMMotionManager *_manager;
        size_t _sampleIndex;
        double _x_offset;
        double _y_offset;
        int _x_number;
        int _y_number;
        std::vector<GLKVector3> _sensorData;
        bool isUpAndDown;
        bool isLeftAndRight;
        
        void addData(GLKVector3 value);
        void computeOffsets();
        void valueChanged(bool isX);
        float meanOf(size_t start, int n, bool isX);
        float std(size_t start, int n, bool isX);
        
        
        static const size_t numberOfSamples = 40;
        static const size_t frequency = 50;
    };
    
}

#endif /* defined(__SuperVision__Goggles__Gyro__) */
