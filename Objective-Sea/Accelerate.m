//
//  Accelerate.m
//  Accelerate
//
//  Created by Alexander Ivanov on 15.08.2021.
//

#import "Accelerate.h"

@implementation NSArray (Accelerate)

- (NSData *)vector:(double (^)(id))callback {
	NSMutableData *data = [[NSMutableData alloc] initWithCapacity:self.count * sizeof(double)];

	for (id item in self) {
		double d = callback ? callback(item) : [item respondsToSelector:@selector(doubleValue)] ? [item doubleValue] : 0.0;

		[data appendBytes:&d length:sizeof(double)];
	}

	return data;
}

@end

@implementation NSData (Accelerate)

- (NSArray<NSNumber *> *)meanAndStandardDeviation {
	double mean = 0.0;
	double standardDeviation = 0.0;

	NSUInteger count = self.length / sizeof(double);

	if (self.length)
		vDSP_normalizeD(self.bytes, 1, NULL, 1, &mean, &standardDeviation, count);

	return @[ @(mean), @(standardDeviation) ];
}

- (NSArray<NSNumber *> *)quartiles {
	double *bytes = malloc(self.length);
	[self getBytes:bytes length:self.length];

	NSUInteger count = self.length / sizeof(double);

	vDSP_vsortD(bytes, count, 1);

	double min = NAN;
	double q1 = NAN;
	double q2 = NAN;
	double q3 = NAN;
	double max = NAN;

	if (count >= 1) {
		min = bytes[0];
		max = bytes[count - 1];

		if (count >= 2) {
			NSUInteger i2 = count * 0.5;
			q2 = count % 2 ? bytes[i2] : ((bytes[i2 - 1] + bytes[i2]) / 2.0);

			if (count >= 3) {
				NSUInteger i1 = count * 0.25;
				q1 = i2 % 2 ? bytes[i1] : ((bytes[i1 - 1] + bytes[i1]) / 2.0);
				NSUInteger i3 = count * 0.75;
				q3 = i2 % 2 ? bytes[i3] : ((bytes[i3 - 1] + bytes[i3]) / 2.0);
			}
		}
	}

	free(bytes);

	return @[ @(min), @(q1), @(q2), @(q3), @(max) ];
}

- (double)sum {
	double sum = 0.0;

	NSUInteger count =  self.length / sizeof(double);

	if (self.length)
		vDSP_sveD(self.bytes, 1, &sum, count);

	return sum;
}

- (double)avg {
	return [self meanAndStandardDeviation][0].doubleValue;
}

- (double)std {
	return [self meanAndStandardDeviation][1].doubleValue;
}

- (double)min {
	return [self quartiles][0].doubleValue;
}

- (double)med {
	return [self quartiles][2].doubleValue;
}

- (double)max {
	return [self quartiles][4].doubleValue;
}

@end
