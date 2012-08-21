//
//  BAJSONViewController.m
//  BADemo
//
//  Created by Dmitry Stadnik on 8/21/12.
//  Copyright (c) 2012 BaseAppKit. All rights reserved.
//

#import "BAJSONViewController.h"
#import "BATextViewController.h"

@interface BAJSONViewController ()

@end

@implementation BAJSONViewController {
	id _JSONValue;
	NSArray *_allSortedKeys;
}

- (void)dealloc {
    [_JSONValue release];
	[_allSortedKeys release];
    [super dealloc];
}

- (id)JSONValue {
	return _JSONValue;
}

- (void)setJSONValue:(id)JSONValue {
	if (_JSONValue == JSONValue) {
		return;
	}
	[_allSortedKeys release];
	_allSortedKeys = nil;
	[_JSONValue release];
	_JSONValue = [JSONValue retain];
	if ([self isViewLoaded]) {
		[self.tableView reloadData];
	}
}

- (NSArray *)allSortedKeys {
	if (!_allSortedKeys) {
		if ([self.JSONValue isKindOfClass:[NSDictionary class]]) {
			_allSortedKeys = [[[self.JSONValue allKeys] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
				if ([obj1 isKindOfClass:[NSString class]] && [obj2 isKindOfClass:[NSString class]]) {
					return [obj1 compare:obj2 options:NSLiteralSearch];
				}
				return NSOrderedSame;
			}] retain];
		} else {
			_allSortedKeys = [[NSArray array] retain];
		}
	}
	return _allSortedKeys;
}

- (NSString *)JSONDetails:(id)JSONValue {
	if ([JSONValue isKindOfClass:[NSArray class]]) {
		return [NSString stringWithFormat:@"[%d]", [JSONValue count]];
	} else if ([JSONValue isKindOfClass:[NSDictionary class]]) {
		return [NSString stringWithFormat:@"{%d}", [JSONValue count]];
	} else if (JSONValue) {
		return [JSONValue description];
	} else {
		return @"";
	}
}

- (NSUInteger)JSONChildrenCount {
	if ([self.JSONValue isKindOfClass:[NSArray class]]) {
		return [self.JSONValue count];
	} else if ([self.JSONValue isKindOfClass:[NSDictionary class]]) {
		return [[self allSortedKeys] count];
	} else {
		return 0;
	}
}

- (id)JSONChildKeyAtIndex:(NSUInteger)index {
	if ([self.JSONValue isKindOfClass:[NSArray class]]) {
		return [NSNumber numberWithUnsignedInteger:index];
	} else if ([self.JSONValue isKindOfClass:[NSDictionary class]]) {
		return [[self allSortedKeys] objectAtIndex:index];
	} else {
		return nil;
	}
}

- (id)JSONChildValueAtIndex:(NSUInteger)index {
	if ([self.JSONValue isKindOfClass:[NSArray class]]) {
		return [self.JSONValue objectAtIndex:index];
	} else if ([self.JSONValue isKindOfClass:[NSDictionary class]]) {
		id key = [[self allSortedKeys] objectAtIndex:index];
		return [self.JSONValue objectForKey:key];
	} else {
		return nil;
	}
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

#pragma mark - Table view

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self JSONChildrenCount];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"BAJSONCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (!cell) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1
									   reuseIdentifier:CellIdentifier] autorelease];
	}
	id key = [self JSONChildKeyAtIndex:indexPath.row];
	id value = [self JSONChildValueAtIndex:indexPath.row];
	cell.textLabel.text = key ? [key description] : @"";
	cell.detailTextLabel.text = [self JSONDetails:value];
	cell.selectionStyle = value ? UITableViewCellSelectionStyleBlue : UITableViewCellSelectionStyleNone;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	id key = [self JSONChildKeyAtIndex:indexPath.row];
	id value = [self JSONChildValueAtIndex:indexPath.row];
	if ([value isKindOfClass:[NSArray class]] || [value isKindOfClass:[NSDictionary class]]) {
		BAJSONViewController *controller = [[[BAJSONViewController alloc] initWithStyle:self.tableView.style] autorelease];
		controller.navigationItem.title = key ? [key description] : @"";
		controller.JSONValue = value;
		[self.navigationController pushViewController:controller animated:YES];
	} else if (value) {
		BATextViewController *controller = [[[BATextViewController alloc] init] autorelease];
		controller.navigationItem.title = key ? [key description] : @"";
		controller.textView.text = [value description];
		[self.navigationController pushViewController:controller animated:YES];
	}
}

@end
