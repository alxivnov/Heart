//
//  HealthKit.m
//  HealthKit
//
//  Created by Alexander Ivanov on 15.08.2021.
//

#import "HealthKit.h"

@implementation HKObjectType (HealthKit)

+ (__kindof HKObjectType *)typeForIdentifier:(NSString *)identifier {
	return [identifier hasPrefix:@"HKQuantityTypeIdentifier"] ? [HKObjectType quantityTypeForIdentifier:identifier]
		: [identifier hasPrefix:@"HKCategoryTypeIdentifier"] ? [HKObjectType categoryTypeForIdentifier:identifier]
		: [identifier hasPrefix:@"HKCharacteristicTypeIdentifier"] ? [HKObjectType characteristicTypeForIdentifier:identifier]
		: [identifier hasPrefix:@"HKCorrelationTypeIdentifier"] ? [HKObjectType correlationTypeForIdentifier:identifier]
		: [identifier hasPrefix:@"HKDocumentTypeIdentifier"] ? [HKObjectType documentTypeForIdentifier:identifier]
		: [identifier isEqualToString:HKWorkoutRouteTypeIdentifier] || [identifier isEqualToString:HKDataTypeIdentifierHeartbeatSeries] ? [HKObjectType seriesTypeForIdentifier:identifier]
	: /*[identifier hasPrefix:@"HKWorkoutTypeIdentifier"] ?*/ [HKObjectType workoutType];
//		: [identifier hasPrefix:@""] ? [HKObjectType activitySummaryType]
//		: [identifier hasPrefix:@""] ? [HKObjectType audiogramSampleType]
//		: [identifier hasPrefix:@""] ? [HKObjectType electrocardiogramType]
//		: Nil;
}

@end

@implementation HKQuery (HealthKit)

+ (NSPredicate *)predicateForSamplesWithDate:(NSDate *)date1
										date:(NSDate *)date2
									 options:(HKQueryOptions)options {

	NSDate *startDate = Nil;
	NSDate *endDate = Nil;
	if (date1 && date2) {
		if ([date1 isLaterThanDate:date2]) {
			startDate = date2;
			endDate = date1;
		} else {
			startDate = date1;
			endDate = date2;
		}
	} else {
		startDate = date1 ?: date2 ?: [NSDate now];
	}

	return [self predicateForSamplesWithStartDate:startDate endDate:endDate options:options];
}

@end

@implementation HKHeartbeatSeriesSample (HealthKit)

- (HKHeartbeatSeriesQuery *)queryHeartbeats:(void (^)(NSArray<NSNumber *> *))callback {
	__block NSMutableArray *beats = [[NSMutableArray alloc] initWithCapacity:self.count];
	__block NSTimeInterval previousBeat = 0.0;
	HKHeartbeatSeriesQuery* query = [[HKHeartbeatSeriesQuery alloc] initWithHeartbeatSeries:self dataHandler:^(HKHeartbeatSeriesQuery * _Nonnull query, NSTimeInterval timeSinceSeriesStart, BOOL precededByGap, BOOL done, NSError * _Nullable error) {
		[error log:@"HKHeartbeatSeriesQuery"];

		NSTimeInterval beat = timeSinceSeriesStart - previousBeat;
		[beats addObject:@(precededByGap ? -beat : beat)];

		previousBeat = timeSinceSeriesStart;

		if (done)
			if (callback)
				callback(beats);
	}];
	[[HKHealthStore defaultStore] executeQuery:query];
	return query;
}

- (HKHeartbeatSeriesQuery *)queryRMSSD:(void (^)(double))callback {
	return [self queryHeartbeats:^(NSArray<NSNumber *> *heartbeats) {
		double sum = 0.0;
		double len = 0.0;

		for (NSUInteger index = 1; index < heartbeats.count; index++) {
			double prev = heartbeats[index - 1].doubleValue * 1000.0;
			double curr = heartbeats[index].doubleValue * 1000.0;

			// Skip calculating differences with beats preceded by gap
			if (prev < 0.0 || curr < 0.0)
				continue;

			sum += pow(fabs(prev) - fabs(curr), 2.0);
			len += 1.0;
		}

		// RMSSD
		double rmssd = sqrt(sum / len);

		if (callback)
			callback(rmssd);
	}];
}

@end

@implementation HKHealthStore (HealthKit)

__static(HKHealthStore *, defaultStore, [[HKHealthStore alloc] init])

- (void)requestAuthorizationToShareIdentifiers:(NSArray<NSString *> *)typesToShare
							   readIdentifiers:(NSArray<NSString *> *)typesToRead
									completion:(void (^)(BOOL, NSError * _Nullable))completion {

	NSSet *toShare = [NSSet setWithArray:[typesToShare map:^id(NSString *value) {
		return [HKObjectType typeForIdentifier:value];
	}]];
	NSSet *toRead = [NSSet setWithArray:[typesToRead map:^id(NSString *value) {
		return [HKObjectType typeForIdentifier:value];
	}]];
	[self requestAuthorizationToShareTypes:toShare readTypes:toRead completion:^(BOOL success, NSError * _Nullable error) {
		[error log:@"requestAuthorizationToShareTypes:"];

		if (completion)
			completion(success, error);
	}];
}

- (HKSampleQuery *)querySamplesWithIdentifier:(NSString *)identifier
                                    predicate:(NSPredicate *)predicate
                                        limit:(NSUInteger)limit
                                         sort:(NSDictionary<NSString *, NSNumber *> *)sort
                               resultsHandler:(void (^)(NSArray<__kindof HKSample *> *, NSError *))resultsHandler {

    id type = [HKObjectType typeForIdentifier:identifier];

    NSArray<NSSortDescriptor *> *sortDescriptors = [sort.allKeys map:^id(NSString *key) {
        return [NSSortDescriptor sortDescriptorWithKey:key ascending:sort[key].boolValue];
    }];

    HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType:type predicate:predicate limit:limit sortDescriptors:sortDescriptors resultsHandler:^(HKSampleQuery * _Nonnull query, NSArray<__kindof HKSample *> * _Nullable results, NSError * _Nullable error) {
        [error log:@"HKSampleQuery"];

        if (resultsHandler)
            resultsHandler(results, error);

    }];
    [self executeQuery:query];

    return query;
}

- (HKSampleQuery *)querySamplesWithDescriptors:(NSArray<HKQueryDescriptor *> *)descriptors
                                         limit:(NSUInteger)limit
                                          sort:(NSDictionary<NSString *, NSNumber *> *)sort
                                resultsHandler:(void (^)(NSArray<__kindof HKSample *> *, NSError *))resultsHandler {

    NSArray<NSSortDescriptor *> *sortDescriptors = [sort.allKeys map:^id(NSString *key) {
        return [NSSortDescriptor sortDescriptorWithKey:key ascending:sort[key].boolValue];
    }];

    HKSampleQuery *query = [[HKSampleQuery alloc] initWithQueryDescriptors:descriptors limit:limit sortDescriptors:sortDescriptors resultsHandler:^(HKSampleQuery * _Nonnull query, NSArray<__kindof HKSample *> * _Nullable results, NSError * _Nullable error) {
        [error log:@"HKSampleQuery"];

        if (resultsHandler)
            resultsHandler(results, error);

    }];
    [self executeQuery:query];

    return query;
}

- (HKObserverQuery *)observeSamplesWithIdentifier:(NSString *)identifier
										predicate:(NSPredicate *)predicate
									updateHandler:(void(^)(HKObserverQueryCompletionHandler completionHandler, NSError * error))updateHandler {

	HKSampleType *type = [HKObjectType typeForIdentifier:identifier];

	HKObserverQuery *query = [[HKObserverQuery alloc] initWithSampleType:type predicate:predicate updateHandler:^(HKObserverQuery * _Nonnull query, HKObserverQueryCompletionHandler  _Nonnull completionHandler, NSError * _Nullable error) {
		[error log:@"HKObserverQuery"];

		if (updateHandler)
			updateHandler(completionHandler, error);
	}];
	[self executeQuery:query];

	return query;
}

- (HKObserverQuery *)observeSamplesWithIdentifier:(NSString *)identifier
										predicate:(NSPredicate *)predicate
											limit:(NSUInteger)limit
											 sort:(NSDictionary<NSString *,NSNumber *> *)sort
								   resultsHandler:(void (^)(NSArray<__kindof HKSample *> *, NSError *))resultsHandler {
	
	return [self observeSamplesWithIdentifier:identifier predicate:predicate updateHandler:^(HKObserverQueryCompletionHandler completionHandler, NSError *error) {
		[self querySamplesWithIdentifier:identifier predicate:predicate limit:limit sort:sort resultsHandler:^(NSArray<__kindof HKSample *> *results, NSError *error) {
			if (resultsHandler)
				resultsHandler(results, error);

			if (completionHandler)
				completionHandler();
		}];
	}];
}

- (HKObserverQuery *)observeSamplesWithIdentifiersAndPpredicates:(NSDictionary<NSString *,NSPredicate *> *)identifiersAndPredicates
                                                   updateHandler:(void (^)(NSArray<HKSampleType *> *, HKObserverQueryCompletionHandler, NSError *))updateHandler {
    
    NSArray<HKQueryDescriptor *> *descriptors = [identifiersAndPredicates.allKeys map:^id(NSString *identifier) {
        HKSampleType *type = [HKObjectType typeForIdentifier:identifier];
        
        return [[HKQueryDescriptor alloc] initWithSampleType:type predicate:[identifiersAndPredicates objectForKey:identifier]];
    }];

    HKObserverQuery *query = [[HKObserverQuery alloc] initWithQueryDescriptors:descriptors updateHandler:^(HKObserverQuery * _Nonnull query, NSSet<HKSampleType *> * _Nullable sampleTypesAdded, HKObserverQueryCompletionHandler  _Nonnull completionHandler, NSError * _Nullable error) {
        [error log:@"HKObserverQuery"];

        if (updateHandler)
            updateHandler([sampleTypesAdded allObjects], completionHandler, error);
    }];
    [self executeQuery:query];
    
    return query;
}

-(HKObserverQuery *)observeSamplesWithIdentifiersAndPpredicates:(NSDictionary<NSString *,NSPredicate *> *)identifiersAndPredicates
                                                          limit:(NSUInteger)limit
                                                           sort:(NSDictionary<NSString *,NSNumber *> *)sort
                                                 resultsHandler:(void (^)(NSDictionary<NSString *,NSArray<__kindof HKSample *> *> *, NSError *))resultsHandler {
    
    return [self observeSamplesWithIdentifiersAndPpredicates:identifiersAndPredicates updateHandler:^(NSArray<HKSampleType *> *sampleTypesAdded, HKObserverQueryCompletionHandler completionHandler, NSError *error) {
        NSArray<HKQueryDescriptor *> *descriptors = [sampleTypesAdded map:^id(HKSampleType *type) {
            return [[HKQueryDescriptor alloc] initWithSampleType:type predicate:[identifiersAndPredicates objectForKey:type.identifier]];
        }];
        
        [self querySamplesWithDescriptors:descriptors limit:limit sort:sort resultsHandler:^(NSArray<__kindof HKSample *> *results, NSError *error) {
			NSDictionary *groupedResults = [results group:^id(__kindof HKSample *sample) {
				return sample.sampleType.identifier;
			}];
            
            if (resultsHandler)
                resultsHandler(groupedResults, error);

            if (completionHandler)
                completionHandler();
        }];
    }];
}

- (BOOL)deleteObject:(HKObject *)object
          completion:(void(^)(BOOL success))completion {
    
    if (!object)
        return NO;
    
    [self deleteObject:object withCompletion:^(BOOL success, NSError *error) {
        [error log:@"deleteObject:"];

        if (completion)
            completion(success);
    }];

    return YES;
}

- (BOOL)deleteObjects:(NSArray<HKObject *> *)objects
           completion:(void (^)(BOOL))completion {
    
    if (!objects.count)
        return NO;

    [self deleteObjects:objects withCompletion:^(BOOL success, NSError *error) {
        [error log:@"deleteObjects:"];

        if (completion)
            completion(success);
    }];

    return YES;
}

@end
