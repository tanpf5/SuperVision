//
//  MagnetSensor.h
//  SuperVision+ Goggles
//
//  Created by Pengfei Tan on 7/2/15.
//  Copyright (c) 2015 Massachusetts Eye and Ear Infirmary. All rights reserved.
//

#ifndef SuperVision__Goggles_MagnetSensor_h
#define SuperVision__Goggles_MagnetSensor_h

#import <CoreMotion/CoreMotion.h>
#import <GLKit/GLKit.h>
#include <vector>


namespace SuperVision
{
    
    NSString *const CBDTriggerPressedNotification = @"CBTriggerPressedNotification";
    
    class MagnetSensor
    {
    public:
        MagnetSensor();
        virtual ~MagnetSensor() {}
        void start();
        void stop();
        
    private:
        CMMotionManager *_manager;
        size_t _sampleIndex;
        GLKVector3 _baseline;
        std::vector<GLKVector3> _sensorData;
        std::vector<float> _offsets;
        
        
        void addData(GLKVector3 value);
        void evaluateModel();
        void computeOffsets(int start, GLKVector3 baseline);
        
        static const size_t numberOfSamples = 20;
    };
    
}
#endif
