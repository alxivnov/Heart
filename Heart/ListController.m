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

@property (strong, nonatomic, readonly) NSDateIntervalFormatter *formatter;

@property (strong, nonatomic, readonly) NSMutableDictionary<NSString *, NSArray *> *cache;
@property (strong, nonatomic, readonly) NSMutableDictionary<NSString *, UIColor *> *color;
@property (strong, nonatomic, readonly) NSMutableDictionary<NSString *, NSNumber *> *rmssd;
@end

@implementation ListController

__lazy(NSDateIntervalFormatter *, formatter,
	NSDateIntervalFormatter * formatter = [[NSDateIntervalFormatter alloc] init];
	formatter.dateStyle = NSDateIntervalFormatterNoStyle;
	formatter.timeStyle = NSDateIntervalFormatterShortStyle;
	formatter
)

__lazy(NSMutableDictionary *, cache, [[NSMutableDictionary alloc] init])
__lazy(NSMutableDictionary *, color, [[NSMutableDictionary alloc] init])
__lazy(NSMutableDictionary *, rmssd, [[NSMutableDictionary alloc] init])

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;

	[MODEL observe:^(NSDictionary<NSString *,NSArray<__kindof HKSample *> *> *results) {
        for (NSString *identifier in results.allKeys) {
			NSArray *samples = [results objectForKey:identifier];
			if (!samples)
				continue;

			[self.cache setObject:samples forKey:identifier];

			if (identifier != HKDataTypeIdentifierHeartbeatSeries)
				continue;

			// REFACTOR: group
			self.rows = [samples forEach:^id(__kindof HKSample *value, NSUInteger index, NSMutableDictionary *context) {
				NSDate *key = [value.endDate dateComponent];

				NSMutableArray *arr = context[key];
				if (arr)
					[arr addObject:value];
				else
					context[key] = [[NSMutableArray alloc] initWithObjects:value, Nil];

				return context;
			} context:[[NSMutableDictionary alloc] initWithCapacity:samples.count]];
			self.sections = [self.rows.allKeys sortedArray:NO];
        }

		NSDictionary<NSString *, UIColor *> *map = @{
			HKCategoryTypeIdentifierMindfulSession:	[UIColor systemCyanColor],
			HKCategoryTypeIdentifierSleepAnalysis:	[UIColor systemIndigoColor],
			HKWorkoutTypeIdentifier:				[UIColor systemMintColor]
		};
		for (HKSample *sample in self.cache[HKDataTypeIdentifierHeartbeatSeries]) {
			for (NSString *identifier in map.allKeys) {
				// REFACTOR: any
				for (HKSample *other in self.cache[identifier]) {
					// REFACTOR: intersect
					if (([sample.startDate isLaterThanDate:other.startDate] && [sample.startDate isEarlierThanDate:other.endDate]) ||
						([sample.endDate isLaterThanDate:other.startDate] && [sample.endDate isEarlierThanDate:other.endDate])) {
						self.color[sample.UUID.UUIDString] = map[identifier];

						break;
					}

					if (self.color[sample.UUID.UUIDString])
						break;
				}
			}
		}

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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"HKHeartbeatSeriesSample" forIndexPath:indexPath];

    // Configure the cell...
	HKHeartbeatSeriesSample *sample = self.rows[self.sections[indexPath.section]][indexPath.row];

	cell.textLabel.text = [self.formatter stringFromDate:sample.startDate toDate:sample.endDate];

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

	cell.textLabel.textColor = self.color[sample.UUID.UUIDString] ?: [UIColor labelColor];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        HKHeartbeatSeriesSample *sample = self.rows[self.sections[indexPath.section]][indexPath.row];
        
        [[HKHealthStore defaultStore] deleteObject:sample completion:^(BOOL success) {
            if (success)
                __ui([tableView deleteRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationAutomatic]);
        }];
    }
}

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
