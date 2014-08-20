//
//  EMSDetailViewRow.h
//

#import <Foundation/Foundation.h>

@interface EMSDetailViewRow : NSObject

@property(nonatomic, strong) NSString *content;
@property(nonatomic, strong) UIImage *image;
@property(nonatomic, strong) NSURL *link;
@property(nonatomic, strong) NSString *body;
@property(nonatomic, strong) NSString *title;
@property(nonatomic) BOOL emphasis;

- (id)initWithContent:(NSString *)content image:(UIImage *)image link:(NSURL *)url;

- (id)initWithContent:(NSString *)content image:(UIImage *)image;

- (id)initWithContent:(NSString *)content;

- (id)initWithContent:(NSString *)content emphasized:(BOOL)emphasized;

- (id)initWithContent:(NSString *)content title:(NSString *)title;
@end
