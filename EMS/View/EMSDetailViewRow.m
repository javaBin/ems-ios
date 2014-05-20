//
//  EMSDetailViewRow.m
//

#import "EMSDetailViewRow.h"

@implementation EMSDetailViewRow

- (id) initWithContent:(NSString *)content body:(NSString *)body image:(UIImage *)image link:(NSURL *)url {
    self = [super init];
    
    self.content = content;
    self.body = body;
    self.image = image;
    self.link = url;
    
    return self;
}

- (id) initWithContent:(NSString *)content image:(UIImage *)image link:(NSURL *)url {
    return [self initWithContent:content body:nil image:image link:url];
}

- (id) initWithContent:(NSString *)content image:(UIImage *)image {
    return [self initWithContent:content body:nil image:image link:nil];
}

- (id) initWithContent:(NSString *)content {
    return [self initWithContent:content body:nil image:nil link:nil];
}

@end
