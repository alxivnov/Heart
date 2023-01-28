//
//  Foundation.m
//  Foundation
//
//  Created by Alexander Ivanov on 15.08.2021.
//

#import "Foundation.h"

@implementation NSObject (Foundation)

- (void)log:(NSString *)message {
	NSString *description = [self debugDescription];

	if (message)
		NSLog(@"%@ %@", message, description);
	else
		NSLog(@"%@", description);
}

@end

@implementation NSArray (Foundation)

- (instancetype)sortedArray:(BOOL)ascending {
	return [self sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
		return ascending
			? [obj1 respondsToSelector:@selector(compare:)] ? [obj1 compare:obj2] : NSOrderedSame
			: [obj1 respondsToSelector:@selector(compare:)] ? [obj2 compare:obj1] : NSOrderedSame;
	}];
}

- (id)forEach:(id (^)(id, NSUInteger, id))callback context:(id)context {
	for (NSUInteger index = 0; index < self.count; index++) {
		id value = [self objectAtIndex:index];

		if (callback)
			context = callback(value, index, context);
	}

	return context;
}

- (BOOL)any:(BOOL (^)(id))callback {
	for (id value in self)
		if (!callback || callback(value))
			return YES;

	return NO;
}

- (BOOL)all:(BOOL (^)(id))callback {
	for (id value in self)
		if (callback && !callback(value))
			return NO;

	return YES;
}

- (NSMutableArray *)map:(id (^)(id))callback {
	return [self forEach:^id(id value, NSUInteger index, NSMutableArray *context) {
		id object = callback ? callback(value) : Nil;

		if (object)
			[context addObject:object];

		return context;
	} context:[[NSMutableArray alloc] initWithCapacity:self.count]];
}

- (NSMutableDictionary *)group:(id (^)(id))callback {
	return [self forEach:^id(id value, NSUInteger index, NSMutableDictionary *dic) {
		id key = callback ? callback(value) : Nil;

		if (key) {
			NSMutableArray *arr = [dic objectForKey:key];
			if (arr)
				[arr addObject:value];
			else
				[dic setObject:[[NSMutableArray alloc] initWithObjects:value, Nil] forKey:key];
		}

		return dic;
	} context:[[NSMutableDictionary alloc] initWithCapacity:self.count]];
}

@end

@implementation NSDate (Foundation)

- (BOOL)isEarlierThanDate:(NSDate *)date {
	return [self compare:date] == NSOrderedAscending;
}

- (BOOL)isLaterThanDate:(NSDate *)date {
	return [self compare:date] == NSOrderedDescending;
}

- (NSString *)description:(NSDateFormatterStyle)dateAndTimeStyle {
	return [NSDateFormatter localizedStringFromDate:self dateStyle:dateAndTimeStyle timeStyle:dateAndTimeStyle];
}

- (NSString *)descriptionForDate:(NSDateFormatterStyle)dateStyle time:(NSDateFormatterStyle)timeStyle {
	return [NSDateFormatter localizedStringFromDate:self dateStyle:dateStyle timeStyle:timeStyle];
}

- (NSString *)descriptionForDate:(NSDateFormatterStyle)dateStyle {
	return [NSDateFormatter localizedStringFromDate:self dateStyle:dateStyle timeStyle:NSDateFormatterNoStyle];
}

- (NSString *)descriptionForTime:(NSDateFormatterStyle)timeStyle {
	return [NSDateFormatter localizedStringFromDate:self dateStyle:NSDateFormatterNoStyle timeStyle:timeStyle];
}

- (NSDate *)addUnit:(NSCalendarUnit)unit value:(NSInteger)value {
	return [[NSCalendar currentCalendar] dateByAddingUnit:unit value:value toDate:self options:0];
}

- (NSDate *)quotient:(NSCalendarUnit)unit {
	NSDate *startDate;
	NSTimeInterval interval;

	if ([[NSCalendar currentCalendar] rangeOfUnit:unit startDate:&startDate	 interval:&interval forDate:self])
		return startDate;
	else
		return Nil;
}

- (NSTimeInterval)remainder:(NSCalendarUnit)unit {
	NSDate *startDate;
	NSTimeInterval interval;

	if ([[NSCalendar currentCalendar] rangeOfUnit:unit startDate:&startDate	 interval:&interval forDate:self])
		return interval;
	else
		return 0.0;
}

- (NSDate *)dateComponent {
	return [self quotient:NSCalendarUnitDay];
}

- (NSTimeInterval)timeComponent {
	return [self remainder:NSCalendarUnitDay];
}

@end
