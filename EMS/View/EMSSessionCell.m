//
//  EMSSessionCell.m
//

#import "EMSSessionCell.h"
#import "Session.h"
#import "Room.h"
#import "Speaker.h"
#import "EMSAppDelegate.h"
#import "EMS-Bridging-Header.h"

@interface EMSSessionCell ()
@property (weak, nonatomic) IBOutlet StarView *starView;
@property(nonatomic, weak) IBOutlet UILabel *title;
@property(nonatomic, weak) IBOutlet UILabel *room;
@property(nonatomic, weak) IBOutlet UILabel *typeLabel;
@property(nonatomic, weak) IBOutlet SessionLevelLineView *levelColorView;
@end

IB_DESIGNABLE
@implementation EMSSessionCell

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if(self = [super initWithCoder:aDecoder]) {
        [self internalInit];
    }
    return self;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self internalInit];
    }
    return self;
}

- (void) internalInit {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textSizeDidChange:) name:UIContentSizeCategoryDidChangeNotification object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) textSizeDidChange: (NSNotification *) notification {
    
}

- (void)setSession:(Session *)session {
    _session = session;
    
    [self configure];
}

- (void) configure {
    
    self.title.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    self.room.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    
    self.starView.hidden = ![self.session.favourite boolValue];
    
    
    self.typeLabel.text =  [self titleForSessionFormat];
    self.typeLabel.hidden = [self.session.format isEqualToString:@"presentation"];
    
    NSArray *levelColors = [EMSSessionCell colorsForLevel:self.session.level];
    self.levelColorView.lineColor = levelColors.firstObject;
    
    if ([levelColors count] > 1) {
        self.levelColorView.secondaryLineColor = [levelColors objectAtIndex:1];
    } else {
        self.levelColorView.secondaryLineColor = nil;
    }
    
    self.title.text = self.session.title;
    
    if (self.session.room) {
        self.room.text = self.session.room.name;
    } else {
        self.room.text = @"";
    }
    
    NSMutableArray *speakerNames = [[NSMutableArray alloc] init];
    
    [self.session.speakers enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        Speaker *speaker = (Speaker *) obj;
        
        [speakerNames addObject:speaker.name];
    }];
    
    NSString *speakers    = [speakerNames componentsJoinedByString:@", "];
    
    
    static NSDateFormatter *formatter;
    if (!formatter) {
        formatter = [[NSDateFormatter alloc] init];
        formatter.locale = [NSLocale autoupdatingCurrentLocale];
        formatter.timeStyle = NSDateFormatterShortStyle;
        formatter.dateStyle = NSDateFormatterNoStyle;
    }
    
    
    NSString *time = [NSString stringWithFormat:@"%@-%@", [formatter stringFromDate:self.session.slot.start], [formatter stringFromDate:self.session.slot.end]];
    
    self.room.text = [NSString stringWithFormat:@"%@: %@ – %@", self.session.room.name, time, speakers];

    
    //Accessibility
    
    self.title.accessibilityLanguage = self.session.language;

    self.accessibilityLabel = [NSString stringWithFormat:NSLocalizedString(@"%@, Location: %@, Speakers: %@", @"{Session title}, Location: {Session Location}, Speakers: {Session speakers}"),
                                      self.title.text, self.room.text, speakers];
    self.accessibilityLanguage = self.session.language;
    
  
}

#define UIColorFromRGBA(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF000000) >> 24))/255.0 green:((float)((rgbValue & 0xFF0000) >> 16))/255.0 blue:((float)((rgbValue & 0xFF00) >> 8 ))/255.0 alpha:((float)((rgbValue & 0xFF))/255.0)]


+ (NSArray *) colorsForLevel:(NSString *) level{
    
    if ([@"beginner" isEqualToString:level]) {
        static NSArray *beginner;
        if (!beginner) {
            beginner =  @[UIColorFromRGBA(0x1F8F88FF)];
        }
        return beginner;
    } else if ([@"beginner-intermediate" isEqualToString:level]) {
        static NSArray *beginner;
        if (!beginner) {
            beginner =  @[UIColorFromRGBA(0x1F8F88FF), UIColorFromRGBA(0xFAAE31FF)];
        }
        return beginner;
    } else if ([@"intermediate" isEqualToString:level]) {
        static NSArray *beginner;
        if (!beginner) {
            beginner =  @[UIColorFromRGBA(0xFAAE31FF)];
        }
        return beginner;
    } else if ([@"intermediate-advanced" isEqualToString:level]) {
        static NSArray *beginner;
        if (!beginner) {
            beginner =  @[UIColorFromRGBA(0xFAAE31FF), UIColorFromRGBA(0xFC5151FF)];
        }
        return beginner;
    } else if ([@"advanced" isEqualToString:level]) {
        static NSArray *beginner;
        if (!beginner) {
            beginner =  @[UIColorFromRGBA(0xFC5151FF)];
        }
        return beginner;
    } else {
        return @[];
    }
}

- (NSString *) titleForSessionFormat {
    NSString *format = self.session.format;
    if ([format isEqualToString:@"presentation"]) {
        return @"Presentasjon";
    } else if ([format isEqualToString:@"lightning-talk"]) {
        return @"Lyntale";
    } else if ([format isEqualToString:@"workshop"]) {
        return @"Workshop";
    } else {
        return @"Ukjent";
    }
}

@end
