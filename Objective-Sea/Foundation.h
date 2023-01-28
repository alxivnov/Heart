//
//  Foundation.h
//  Foundation
//
//  Created by Alexander Ivanov on 15.08.2021.
//

#import <Foundation/Foundation.h>

#define __lazy(Type, name, INIT) @synthesize name = _##name; - (Type)name { if (!_##name) { _##name = ({ INIT; }); } return _##name; }

#define __static(Type, name, INIT) static Type _##name; + (Type)name { if (!_##name) { _##name = ({ INIT; }); } return _##name; }

#define __as(Type, INSTANCE) ([INSTANCE isKindOfClass:[Type class]] ? (Type *)INSTANCE : Nil)

#define __ui(block) dispatch_async(dispatch_get_main_queue(), ^{ block; })

@interface NSObject (Foundation)

- (void)log:(NSString *)message;

@end

@interface NSArray<Type> (Foundation)

- (instancetype)sortedArray:(BOOL)ascending;

- (id)forEach:(id (^)(Type value, NSUInteger index, id context))callback
	  context:(id)context;

- (BOOL)all:(BOOL (^)(Type value))callback;
- (BOOL)any:(BOOL (^)(Type value))callback;
- (NSMutableArray *)map:(id (^)(Type value))callback;
- (NSMutableDictionary<id, NSMutableArray<Type> *> *)group:(id (^)(Type value))callback;

@end

@interface NSDate (Foundation)

- (BOOL)isEarlierThanDate:(NSDate *)date;
- (BOOL)isLaterThanDate:(NSDate *)date;

- (NSString *)description:(NSDateFormatterStyle)dateAndTimeStyle;
- (NSString *)descriptionForDate:(NSDateFormatterStyle)dateStyle time:(NSDateFormatterStyle)timeStyle;
- (NSString *)descriptionForDate:(NSDateFormatterStyle)dateStyle;
- (NSString *)descriptionForTime:(NSDateFormatterStyle)timeStyle;

- (NSDate *)addUnit:(NSCalendarUnit)unit value:(NSInteger)value;

- (NSDate *)quotient:(NSCalendarUnit)unit;
- (NSTimeInterval)remainder:(NSCalendarUnit)unit;
- (NSDate *)dateComponent;
- (NSTimeInterval)timeComponent;

@end

