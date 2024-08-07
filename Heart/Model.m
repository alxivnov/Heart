//
//  Model.m
//  Model
//
//  Created by Alexander Ivanov on 05.08.2021.
//

#import "Model.h"

@implementation Model

__static(Model *, instance, [[Model alloc] init])

__static(HKHealthStore *, store, [HKHealthStore defaultStore])

- (void)observe:(void (^)(NSDictionary<NSString *,NSArray<__kindof HKSample *> *> *))callback {
    NSPredicate *predicate = [HKQuery predicateForSamplesWithDate:[[NSDate now] addUnit:NSCalendarUnitWeekOfYear value:-1] date:Nil options:HKQueryOptionNone];
    NSDictionary *map = @{
        HKDataTypeIdentifierHeartbeatSeries:                predicate,
		HKQuantityTypeIdentifierHeartRateVariabilitySDNN:   predicate,
        HKCategoryTypeIdentifierMindfulSession:             predicate,
        HKCategoryTypeIdentifierSleepAnalysis:              predicate,
        HKWorkoutTypeIdentifier:                            predicate
    };
	NSArray *write = @[
//		HKDataTypeIdentifierHeartbeatSeries,
//		HKQuantityTypeIdentifierHeartRateVariabilitySDNN
	];
	[[self class].store requestAuthorizationToShareIdentifiers:write readIdentifiers:map.allKeys completion:^(BOOL success, NSError *error) {
        [[HKHealthStore defaultStore] observeSamplesWithIdentifiersAndPpredicates:map limit:0 sort:@{ HKSampleSortIdentifierEndDate : @NO } resultsHandler:^(NSDictionary<NSString *, NSArray<__kindof HKSample *> *> *results, NSError *error) {
			if (callback)
				callback(results);
		}];
	}];
}

- (void)delete:(HKSample *)sample completion:(void(^)(BOOL success))completion {
	[[self class].store deleteObject:sample completion:completion];
}

@end
