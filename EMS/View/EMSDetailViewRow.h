//
//  EMSDetailViewRow.h
//

#import <Foundation/Foundation.h>

@interface EMSDetailViewRow : NSObject

@property (nonatomic, strong) NSString *content;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) NSURL *link;
@property (nonatomic, strong) NSString *body;

- (id) initWithContent:(NSString *)content body:(NSString *)body image:(UIImage *)image link:(NSURL *)url;
- (id) initWithContent:(NSString *)content image:(UIImage *)image link:(NSURL *)url;
- (id) initWithContent:(NSString *)content image:(UIImage *)image;
- (id) initWithContent:(NSString *)content;

@end
