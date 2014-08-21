//
//  EMSDetailViewRow.m
//

#import "EMSDetailViewRow.h"

@implementation EMSDetailViewRow

- (id)initWithContent:(NSString *)content body:(NSString *)body image:(UIImage *)image link:(NSURL *)url title:(NSString *)title emphasized:(BOOL) emphasized{
    self = [super init];

    self.content = content;
    self.body = body;
    self.image = image;
    self.link = url;

    self.title = title;
    self.emphasis = emphasized;

    return self;
}

- (id)initWithContent:(NSString *)content image:(UIImage *)image link:(NSURL *)url {
    return [self initWithContent:content body:nil image:image link:url title:nil emphasized:NO];
}

- (id)initWithContent:(NSString *)content image:(UIImage *)image {
    return [self initWithContent:content body:nil image:image link:nil title:nil emphasized:NO];
}

- (id)initWithContent:(NSString *)content {
    return [self initWithContent:content body:nil image:nil link:nil title:nil emphasized:NO];
}


- (id)initWithContent:(NSString *)content emphasized:(BOOL)emphasized {
    return [self initWithContent:content body:nil image:nil link:nil title:nil emphasized:emphasized];
}

- (id)initWithContent:(NSString *)content title:(NSString *)title {
    return [self initWithContent:content body:nil image:nil link:nil title:title emphasized:NO];
}
@end
