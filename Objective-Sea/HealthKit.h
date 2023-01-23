//
//  HealthKit.h
//  HealthKit
//
//  Created by Alexander Ivanov on 15.08.2021.
//

#import <Foundation/Foundation.h>

#import "Foundation.h"

@import HealthKit;

@interface HKObjectType (HealthKit)

+ (__kindof HKObjectType *)typeForIdentifier:(NSString *)identifier;

@end

@interface HKQuery (HealthKit)

+ (NSPredicate *)predicateForSamplesWithDate:(NSDate *)date1
										date:(NSDate *)date2
									 options:(HKQueryOptions)options;

@end

@interface HKHeartbeatSeriesSample (HealthKit)

- (HKHeartbeatSeriesQuery *)queryHeartbeats:(void (^)(NSArray<NSNumber *> *heartbeats))callback;

- (HKHeartbeatSeriesQuery *)queryRMSSD:(void (^)(double rmssd))callback;

@end

@interface HKHealthStore (HealthKit)

+ (HKHealthStore *)defaultStore;

- (void)requestAuthorizationToShareIdentifiers:(NSArray<NSString *> *)typesToShare
							   readIdentifiers:(NSArray<NSString *> *)typesToRead completion:(void (^)(BOOL, NSError *))completion;

- (HKSampleQuery *)querySamplesWithIdentifier:(NSString *)identifier
                                    predicate:(NSPredicate *)predicate
                                        limit:(NSUInteger)limit
                                         sort:(NSDictionary<NSString *, NSNumber *> *)sort
                               resultsHandler:(void(^)(NSArray<__kindof HKSample *> *results, NSError *error))resultsHandler;

- (HKSampleQuery *)querySamplesWithDescriptors:(NSArray<HKQueryDescriptor *> *)descriptors
                                         limit:(NSUInteger)limit
                                          sort:(NSDictionary<NSString *, NSNumber *> *)sort
                                resultsHandler:(void(^)(NSArray<__kindof HKSample *> *results, NSError *error))resultsHandler;

- (HKObserverQuery *)observeSamplesWithIdentifier:(NSString *)identifier
                                        predicate:(NSPredicate *)predicate
                                    updateHandler:(void(^)(HKObserverQueryCompletionHandler completionHandler, NSError * error))updateHandler;
- (HKObserverQuery *)observeSamplesWithIdentifier:(NSString *)identifier
                                        predicate:(NSPredicate *)predicate
                                            limit:(NSUInteger)limit
                                             sort:(NSDictionary<NSString *, NSNumber *> *)sort
                                   resultsHandler:(void (^)(NSArray<__kindof HKSample *> *results, NSError *error))resultsHandler;

- (HKObserverQuery *)observeSamplesWithIdentifiersAndPpredicates:(NSDictionary<NSString *, NSPredicate *> *)identifiersAndPredicates
                                                   updateHandler:(void(^)(NSArray<HKSampleType *> *sampleTypesAdded, HKObserverQueryCompletionHandler completionHandler, NSError *error))updateHandler;
- (HKObserverQuery *)observeSamplesWithIdentifiersAndPpredicates:(NSDictionary<NSString *, NSPredicate *> *)identifiersAndPredicates
                                                           limit:(NSUInteger)limit
                                                            sort:(NSDictionary<NSString *, NSNumber *> *)sort
                                                  resultsHandler:(void (^)(NSDictionary<NSString *, NSArray<__kindof HKSample *> *> *results, NSError *error))resultsHandler;

- (BOOL)deleteObject:(HKObject *)object
          completion:(void (^)(BOOL success))completion;
- (BOOL)deleteObjects:(NSArray<HKObject *> *)objects
           completion:(void (^)(BOOL success))completion;

@end

