//
//  Model.m
//  Model
//
//  Created by Alexander Ivanov on 05.08.2021.
//

#import "Model.h"

@implementation Model

__static(Model *, instance, [[Model alloc] init])

- (void)observe:(void (^)(NSDictionary<NSString *,NSArray<__kindof HKSample *> *> *))callback {
    NSPredicate *predicate = [HKQuery predicateForSamplesWithDate:[[NSDate now] addUnit:NSCalendarUnitWeekOfYear value:-1] date:Nil options:HKQueryOptionNone];
    NSDictionary *map = @{
        HKDataTypeIdentifierHeartbeatSeries:                predicate,
        HKQuantityTypeIdentifierHeartRateVariabilitySDNN:   predicate,
        HKCategoryTypeIdentifierMindfulSession:             predicate,
        HKCategoryTypeIdentifierSleepAnalysis:              predicate,
        HKWorkoutTypeIdentifier:                            predicate
    };
	[[HKHealthStore defaultStore] requestAuthorizationToShareIdentifiers:Nil readIdentifiers:map.allKeys completion:^(BOOL success, NSError *error) {
        [[HKHealthStore defaultStore] observeSamplesWithIdentifiersAndPpredicates:map limit:0 sort:@{ HKSampleSortIdentifierEndDate : @NO } resultsHandler:^(NSDictionary<NSString *, NSArray<__kindof HKSample *> *> *results, NSError *error) {
			if (callback)
				callback(results);
		}];
	}];
}

@end
