//
//  Model.h
//  Model
//
//  Created by Alexander Ivanov on 05.08.2021.
//

#import <Foundation/Foundation.h>

#import "Foundation.h"
#import "HealthKit.h"

#define MODEL [Model instance]

@interface Model : NSObject

+ (instancetype)instance;

- (void)observe:(void (^)(NSDictionary<NSString *, NSArray<__kindof HKSample *> *> *results))callback;

@end
