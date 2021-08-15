//
//  Accelerate.h
//  Accelerate
//
//  Created by Alexander Ivanov on 15.08.2021.
//

#import <Foundation/Foundation.h>

@import Accelerate;

@interface NSArray<Type> (Accelerate)

- (NSData *)vector:(double (^)(Type value))callback;

@end

@interface NSData (Accelerate)

- (NSArray<NSNumber *> *)meanAndStandardDeviation;
- (NSArray<NSNumber *> *)quartiles;

- (double)sum;

- (double)avg;
- (double)std;

- (double)min;
- (double)med;
- (double)max;

@end
