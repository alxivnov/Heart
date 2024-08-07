//
//  ListController.m
//  ListController
//
//  Created by Alexander Ivanov on 05.08.2021.
//

#import "ListController.h"

#import "Model.h"

@interface ListController ()
@property (strong, nonatomic) NSArray<NSDate *> *sections;
@property (strong, nonatomic) NSDictionary<NSDate *, NSArray<HKHeartbeatSeriesSample *> *> *rows;

@property (strong, nonatomic, readonly) NSDateIntervalFormatter *intervalFormatter;
@property (strong, nonatomic, readonly) NSDateComponentsFormatter *durationFormatter;

@property (strong, nonatomic, readonly) NSMutableDictionary<NSString *, NSArray *> *cache;
@property (strong, nonatomic, readonly) NSMutableDictionary<NSString *, UIColor *> *color;
@property (strong, nonatomic, readonly) NSMutableDictionary<NSString *, NSNumber *> *rmssd;
@end

@implementation ListController

__lazy(NSDateIntervalFormatter *, intervalFormatter,
	NSDateIntervalFormatter * formatter = [[NSDateIntervalFormatter alloc] init];
	formatter.dateStyle = NSDateIntervalFormatterNoStyle;
	formatter.timeStyle = NSDateIntervalFormatterShortStyle;
	formatter
)
__lazy(NSDateComponentsFormatter *, durationFormatter,
	NSDateComponentsFormatter * formatter = [[NSDateComponentsFormatter alloc] init];
	formatter.unitsStyle = NSDateComponentsFormatterUnitsStyleAbbreviated;
	formatter.allowedUnits = NSCalendarUnitHour | NSCalendarUnitMinute;
	formatter
)

__lazy(NSMutableDictionary *, cache, [[NSMutableDictionary alloc] init])
__lazy(NSMutableDictionary *, color, [[NSMutableDictionary alloc] init])
__lazy(NSMutableDictionary *, rmssd, [[NSMutableDictionary alloc] init])

// Refactor
// Why image does not tint

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;

	[MODEL observe:^(NSDictionary<NSString *,NSArray<__kindof HKSample *> *> *results) {
        for (NSString *identifier in results.allKeys) {
			if (identifier == HKQuantityTypeIdentifierHeartRateVariabilitySDNN)
				continue;

			NSArray *samples = [results objectForKey:identifier];
			if (!samples)
				continue;

			[self.cache setObject:samples forKey:identifier];
        }

		NSDictionary<NSString *, UIColor *> *map = @{
			HKCategoryTypeIdentifierMindfulSession:	[UIColor systemMintColor],
			HKCategoryTypeIdentifierSleepAnalysis:	[UIColor systemIndigoColor],
			HKWorkoutTypeIdentifier:				[UIColor systemGreenColor]
		};

		for (HKSample *sample in self.cache[HKDataTypeIdentifierHeartbeatSeries])
			for (NSString *identifier in map.allKeys)
				if ([self.cache[identifier] any:^BOOL(HKSample *other) {
					BOOL isEarlier = [sample.startDate isEarlierThanDate:other.startDate] && [sample.endDate isEarlierThanDate:other.startDate];
					BOOL isLater = [sample.startDate isLaterThanDate:other.endDate] && [sample.endDate isLaterThanDate:other.endDate];
					return !(isEarlier || isLater);
				}])
					self.color[sample.UUID.UUIDString] = map[identifier];

		NSArray *samples = [[self.cache.allKeys flatMap:^NSArray *(NSString *identifier) {
			NSArray *samples = self.cache[identifier];
//			if (identifier == HKDataTypeIdentifierHeartbeatSeries)
//				return [samples map:^id(HKSample *sample) {
//					return [map.allKeys any:^BOOL(NSString *key) {
//						return [self.cache[key] any:^BOOL(HKSample *other) {
//							BOOL isEarlier = [sample.startDate isEarlierThanDate:other.startDate] && [sample.endDate isEarlierThanDate:other.startDate];
//							BOOL isLater = [sample.startDate isLaterThanDate:other.endDate] && [sample.endDate isLaterThanDate:other.endDate];
//								return !(isEarlier || isLater);
//						 }];
//					}] ? Nil : sample;
//				}];

			if (identifier == HKCategoryTypeIdentifierSleepAnalysis)
				return [samples map:^id(HKCategorySample *sample) {
					return sample.value == HKCategoryValueSleepAnalysisAsleep ? sample : Nil;
				}];

//			if (identifier == HKCategoryTypeIdentifierMindfulSession)
//				return @[];

			return samples;
		}] sortedArrayUsingComparator:^NSComparisonResult(HKSample *obj1, HKSample *obj2) {
			return [obj2.endDate compare:obj1.endDate];
		}];

		self.rows = [samples group:^id(HKSample *sample) {
			return [sample.endDate dateComponent];
		}];
		self.sections = [self.rows.allKeys sortedArray:NO];

		__ui([self.tableView reloadData]);
	}];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.rows[self.sections[section]].count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return [self.sections[section] descriptionForDate:NSDateFormatterFullStyle];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    // Configure the cell...
	HKHeartbeatSeriesSample *sample = self.rows[self.sections[indexPath.section]][indexPath.row];

	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:sample.sampleType.identifier forIndexPath:indexPath];

	cell.textLabel.text = [self.intervalFormatter stringFromDate:sample.startDate toDate:sample.endDate];

	if (sample.sampleType.identifier == HKDataTypeIdentifierHeartbeatSeries) {
		NSString *key = sample.UUID.UUIDString;
		NSNumber *cache = self.rmssd[key];
		if (cache) {
			cell.detailTextLabel.text = [NSString stringWithFormat:@"%.f%%", fmin(100.0,  log(cache.doubleValue) * 20.0)];
		} else {
			cell.detailTextLabel.text = @"--%";

			[sample queryRMSSD:^(double rmssd) {
				self.rmssd[key] = @(rmssd);

				__ui([tableView reloadRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationAutomatic]);
			}];
		}
	} else {
		cell.detailTextLabel.text = [self.durationFormatter stringFromDate:sample.startDate toDate:sample.endDate];
	}

	cell.textLabel.textColor = self.color[sample.UUID.UUIDString] ?: [UIColor labelColor];
	cell.imageView.tintColor = self.color[sample.UUID.UUIDString] ?: sample.sampleType.identifier == HKDataTypeIdentifierHeartbeatSeries ? [UIColor systemRedColor] : [UIColor labelColor];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

//- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
//	HKHeartbeatSeriesSample *sample = self.rows[self.sections[indexPath.section]][indexPath.row];
//
//	return sample.sampleType.identifier == HKDataTypeIdentifierHeartbeatSeries ? UITableViewCellEditingStyleDelete : UITableViewCellEditingStyleNone;
//}
//
//- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
//    if (editingStyle == UITableViewCellEditingStyleDelete) {
//        HKHeartbeatSeriesSample *sample = self.rows[self.sections[indexPath.section]][indexPath.row];
//        
//        [MODEL delete:sample completion:^(BOOL success) {
//            if (success)
//                __ui([tableView deleteRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationAutomatic]);
//        }];
//    }
//}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
