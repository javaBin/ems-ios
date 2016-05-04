//
// NSURLResponse+EMSExtensions.h
//

@interface NSURLResponse (EMSExtensions)

- (NSError *)ems_error;
- (BOOL)ems_hasSuccessfulStatus;

@end