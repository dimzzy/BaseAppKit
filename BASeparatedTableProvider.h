#import <UIKit/UIKit.h>

enum {
	BACellSeparatorPositionNone = 0,
	BACellSeparatorPositionTop = 1 << 0,
	BACellSeparatorPositionBottom = 1 << 1
};

typedef NSUInteger BACellSeparatorPositions;


@protocol BASeparatedTableProviderDelegate <NSObject, UITableViewDataSource, UITableViewDelegate>

- (BACellSeparatorPositions)tableView:(UITableView *)tableView separatorPositionsForRow:(NSIndexPath *)indexPath;
- (UITableViewCell *)tableView:(UITableView *)tableView topSeparatorCellForRowAtIndexPath:(NSIndexPath *)indexPath;
- (UITableViewCell *)tableView:(UITableView *)tableView bottomSeparatorCellForRowAtIndexPath:(NSIndexPath *)indexPath;
- (CGFloat)tableView:(UITableView *)tableView heightForTopSeparatorRowAtIndexPath:(NSIndexPath *)indexPath;
- (CGFloat)tableView:(UITableView *)tableView heightForBottomSeparatorRowAtIndexPath:(NSIndexPath *)indexPath;

@end


@interface BASeparatedTableProvider : NSObject <UITableViewDataSource, UITableViewDelegate>

@property(nonatomic, assign) id<BASeparatedTableProviderDelegate> delegate;

- (NSIndexPath *)separatedIndexPathForIndexPath:(NSIndexPath *)indexPath;
- (NSArray *)separatedIndexPathsForIndexPaths:(NSArray *)indexPaths;

@end
