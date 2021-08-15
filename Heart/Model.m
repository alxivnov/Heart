//
//  Model.m
//  Model
//
//  Created by Alexander Ivanov on 05.08.2021.
//

#import "Model.h"

@implementation Model

__static(Model *, instance, [[Model alloc] init])

- (void)observe:(void (^)(NSArray<__kindof HKSample *> *))callback {
	NSArray *types = @[
		HKDataTypeIdentifierHeartbeatSeries,
		HKQuantityTypeIdentifierHeartRateVariabilitySDNN,
		HKCategoryTypeIdentifierMindfulSession,
		HKCategoryTypeIdentifierSleepAnalysis,
		HKWorkoutTypeIdentifier
	];
	[[HKHealthStore defaultStore] requestAuthorizationToShareIdentifiers:Nil readIdentifiers:types completion:^(BOOL success, NSError *error) {
		NSPredicate *predicate = [HKQuery predicateForSamplesWithDate:[[NSDate now] addUnit:NSCalendarUnitWeekOfYear value:-1] date:Nil options:HKQueryOptionNone];

		[[HKHealthStore defaultStore] observeSamplesWithIdentifier:HKDataTypeIdentifierHeartbeatSeries predicate:predicate limit:0 sort:@{ HKSampleSortIdentifierEndDate : @NO } resultsHandler:^(NSArray<__kindof HKSample *> *results, NSError *error) {
			if (callback)
				callback(results);
		}];
	}];
}

@end
