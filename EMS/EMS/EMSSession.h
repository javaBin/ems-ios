//
//  EMSSession.h
//

#import <Foundation/Foundation.h>

@interface EMSSession : NSObject

@property(strong, nonatomic) NSURL *href;
@property(strong, nonatomic) NSString *format;
@property(strong, nonatomic) NSString *body;
@property(strong, nonatomic) NSString *state;
@property(strong, nonatomic) NSString *audience;
@property(strong, nonatomic) NSArray *keywords;
@property(strong, nonatomic) NSString *title;
@property(strong, nonatomic) NSString *language;
@property(strong, nonatomic) NSString *summary;
@property(strong, nonatomic) NSString *level;
@property(strong, nonatomic) NSURL *videoLink;
@property(strong, nonatomic) NSArray *speakers;

@property(strong, nonatomic) NSURL *attachmentCollection;
@property(strong, nonatomic) NSURL *speakerCollection;
@property(strong, nonatomic) NSURL *roomItem;
@property(strong, nonatomic) NSURL *slotItem;

- (NSString *)description;

@end
