//
//  EMSModel.m
//

#import "EMSModel.h"

#import "EMS-Swift.h"

#import "EMSAppDelegate.h"

#import "EMSTracking.h"
#import "EMSConfig.h"

#import "NSDate+EMSExtensions.h"

static const DDLogLevel ddLogLevel = DDLogLevelDebug;

@implementation EMSModel

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)moc {
    self = [super init];

    self.managedObjectContext = moc;

    return self;
}

#pragma mark - get list of objects

- (NSArray *)objectsForPredicate:(NSPredicate *)predicate andSort:(NSArray *)sort withType:(NSString *)type {

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];

    [fetchRequest setEntity:[NSEntityDescription entityForName:type inManagedObjectContext:[self managedObjectContext]]];

    [fetchRequest setPredicate:predicate];

    if (sort != nil) {
        [fetchRequest setSortDescriptors:sort];
    }

    NSError *error;

    NSArray *objects = [[self managedObjectContext] executeFetchRequest:fetchRequest error:&error];

    if (!objects) {
        DDLogError(@"Failed to fetch objects for predicate %@, sort %@, type %@ - %@ - %@", predicate, sort, type, error, [error userInfo]);
    }

    return objects;
}

- (NSArray *)conferencesForPredicate:(NSPredicate *)predicate andSort:(NSArray *)sort {
    return [self objectsForPredicate:predicate andSort:sort withType:NSStringFromClass([Conference class])];
}

- (NSArray *)slotsForPredicate:(NSPredicate *)predicate andSort:(NSArray *)sort {
    return [self objectsForPredicate:predicate andSort:sort withType:NSStringFromClass([Slot class])];
}

- (NSArray *)sessionsForPredicate:(NSPredicate *)predicate andSort:(NSArray *)sort {
    return [self objectsForPredicate:predicate andSort:sort withType:NSStringFromClass([Session class])];
}

- (NSArray *)roomsForPredicate:(NSPredicate *)predicate andSort:(NSArray *)sort {
    return [self objectsForPredicate:predicate andSort:sort withType:NSStringFromClass([Room class])];
}

- (NSArray *)speakersForPredicate:(NSPredicate *)predicate andSort:(NSArray *)sort {
    return [self objectsForPredicate:predicate andSort:sort withType:NSStringFromClass([Speaker class])];
}

#pragma mark - get single object

- (Conference *)conferenceForHref:(NSString *)url {
    NSArray *matched = [self
            conferencesForPredicate:[NSPredicate predicateWithFormat:@"(href LIKE %@)", url]
                            andSort:nil];

    if (matched.count > 0) {
        if (matched.count > 1) {
            DDLogWarn(@"Found %lu conferences for href %@", (unsigned long) matched.count, url);

            [self analyticsWarningForType:@"conference" andHref:url withCount:@(matched.count)];
        }
        return matched[0];
    }

    return nil;
}

- (Conference *)conferenceForSessionHref:(NSString *)url {
    NSArray *matched = [self
            conferencesForPredicate:[NSPredicate predicateWithFormat:@"(ANY sessions.href LIKE %@)", url]
                            andSort:nil];

    if (matched.count > 0) {
        if (matched.count > 1) {
            DDLogWarn(@"Found %lu conferences for sessions href %@", (unsigned long) matched.count, url);

            [self analyticsWarningForType:@"conferenceForSession" andHref:url withCount:@(matched.count)];
        }
        return matched[0];
    }

    return nil;
}

- (Slot *)slotForHref:(NSString *)url {
    NSArray *matched = [self
            slotsForPredicate:[NSPredicate predicateWithFormat:@"(href LIKE %@)", url]
                      andSort:nil];

    if (matched.count > 0) {
        if (matched.count > 1) {
            DDLogWarn(@"Found %lu slots for href %@", (unsigned long) matched.count, url);

            [self analyticsWarningForType:@"slot" andHref:url withCount:@(matched.count)];
        }
        return matched[0];
    }

    return nil;
}

- (Room *)roomForHref:(NSString *)url {
    NSArray *matched = [self
            roomsForPredicate:[NSPredicate predicateWithFormat:@"(href LIKE %@)", url]
                      andSort:nil];

    if (matched.count > 0) {
        if (matched.count > 1) {
            DDLogWarn(@"Found %lu rooms for href %@", (unsigned long) matched.count, url);

            [self analyticsWarningForType:@"room" andHref:url withCount:@(matched.count)];
        }
        return matched[0];
    }

    return nil;
}

- (Session *)sessionForHref:(NSString *)url {
    NSArray *matched = [self
            sessionsForPredicate:[NSPredicate predicateWithFormat:@"(href LIKE %@)", url]
                         andSort:nil];

    if (matched.count > 0) {
        if (matched.count > 1) {
            DDLogWarn(@"Found %lu sessions for href %@", (unsigned long) matched.count, url);

            [self analyticsWarningForType:@"session" andHref:url withCount:@(matched.count)];
        }
        return matched[0];
    }

    return nil;
}

- (Speaker *)speakerForHref:(NSString *)url {
    NSArray *matched = [self
            speakersForPredicate:[NSPredicate predicateWithFormat:@"(href LIKE %@)", url]
                         andSort:nil];

    if (matched.count > 0) {
        if (matched.count > 1) {
            DDLogWarn(@"Found %lu speakers for href %@", (unsigned long) matched.count, url);

            [self analyticsWarningForType:@"speaker" andHref:url withCount:@(matched.count)];
        }
        return matched[0];
    }

    return nil;
}

#pragma mark - create hash from href to object

- (NSDictionary *)conferencesKeyedByHref:(NSArray *)conferences {
    NSMutableDictionary *hrefKeyed = [[NSMutableDictionary alloc] init];

    [conferences enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        EMSConference *ems = (EMSConference *) obj;
        [hrefKeyed setValue:ems forKey:[ems.href absoluteString]];
    }];

    return [NSDictionary dictionaryWithDictionary:hrefKeyed];
}

- (NSDictionary *)slotsKeyedByHref:(NSArray *)slots {
    NSMutableDictionary *hrefKeyed = [[NSMutableDictionary alloc] init];

    [slots enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        EMSSlot *ems = (EMSSlot *) obj;
        [hrefKeyed setValue:ems forKey:[ems.href absoluteString]];
    }];

    return [NSDictionary dictionaryWithDictionary:hrefKeyed];
}

- (NSDictionary *)roomsKeyedByHref:(NSArray *)slots {
    NSMutableDictionary *hrefKeyed = [[NSMutableDictionary alloc] init];

    [slots enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        EMSRoom *ems = (EMSRoom *) obj;
        [hrefKeyed setValue:ems forKey:[ems.href absoluteString]];
    }];

    return [NSDictionary dictionaryWithDictionary:hrefKeyed];
}

- (NSDictionary *)sessionsKeyedByHref:(NSArray *)slots {
    NSMutableDictionary *hrefKeyed = [[NSMutableDictionary alloc] init];

    [slots enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        EMSSession *ems = (EMSSession *) obj;
        [hrefKeyed setValue:ems forKey:[ems.href absoluteString]];
    }];

    return [NSDictionary dictionaryWithDictionary:hrefKeyed];
}

- (NSDictionary *)speakersKeyedByHref:(NSArray *)speakers {
    NSMutableDictionary *hrefKeyed = [[NSMutableDictionary alloc] init];

    [speakers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        EMSSpeaker *ems = (EMSSpeaker *) obj;
        [hrefKeyed setValue:ems forKey:[ems.href absoluteString]];
    }];

    return [NSDictionary dictionaryWithDictionary:hrefKeyed];
}

#pragma mark - populate managed object from EMS object

- (void)populateConference:(Conference *)conference fromEMS:(EMSConference *)ems {
    conference.name = ems.name;
    conference.venue = ems.venue;
    conference.href = [ems.href absoluteString];
    if (ems.start != nil) {
        conference.start = ems.start;
    }
    if (ems.end != nil) {
        conference.end = ems.end;
    }

    conference.roomCollection = [ems.roomCollection absoluteString];
    conference.sessionCollection = [ems.sessionCollection absoluteString];
    conference.slotCollection = [ems.slotCollection absoluteString];

    if (ems.hintCount == nil) {
        conference.hintCount = @0;
    } else {
        conference.hintCount = ems.hintCount;
    }
}

- (void)populateSlot:(Slot *)slot fromEMS:(EMSSlot *)ems forConference:(Conference *)conference {
    slot.start = ems.start;
    slot.end = ems.end;
    slot.href = [ems.href absoluteString];

    slot.conference = conference;
}

- (void)populateRoom:(Room *)room fromEMS:(EMSRoom *)ems forConference:(Conference *)conference {
    room.name = ems.name;
    room.href = [ems.href absoluteString];

    room.conference = conference;
}

- (void)populateSession:(Session *)session fromEMS:(EMSSession *)ems forConference:(Conference *)conference {
    session.href = [ems.href absoluteString];
    session.title = ems.title;
    session.format = ems.format;
    session.body = ems.body;
    session.state = ems.state;
    session.audience = ems.audience;
    session.language = ems.language;
    session.summary = ems.summary;
    session.level = ems.level;
    session.link = [ems.link absoluteString];
    session.videoLink = [ems.videoLink absoluteString];

    NSSet *foundLevels = [conference.conferenceLevels objectsPassingTest:^BOOL(id obj, BOOL *stop) {
        ConferenceLevel *conferenceLevel = (ConferenceLevel *) obj;

        return [conferenceLevel.name isEqualToString:ems.level];
    }];

    if ([foundLevels count] == 0) {
        ConferenceLevel *conferenceLevel = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([ConferenceLevel class]) inManagedObjectContext:[self managedObjectContext]];

        conferenceLevel.name = ems.level;
        conferenceLevel.conference = conference;
    }

    NSSet *foundTypes = [conference.conferenceTypes objectsPassingTest:^BOOL(id obj, BOOL *stop) {
        ConferenceType *conferenceType = (ConferenceType *) obj;

        return [conferenceType.name isEqualToString:ems.format];
    }];

    if ([foundTypes count] == 0) {
        ConferenceType *conferenceType = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([ConferenceType class]) inManagedObjectContext:[self managedObjectContext]];

        conferenceType.name = ems.format;
        conferenceType.conference = conference;
    }

    if (ems.keywords != nil) {
        [ems.keywords enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSString *keyword = (NSString *) obj;

            NSSet *foundKeywords = [session.keywords objectsPassingTest:^BOOL(id keywordObj, BOOL *keywordStop) {
                Keyword *sessionKeyword = (Keyword *) keywordObj;

                return [sessionKeyword.name isEqualToString:keyword];
            }];

            if ([foundKeywords count] == 0) {
                Keyword *newKeyword = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([Keyword class]) inManagedObjectContext:[self managedObjectContext]];

                newKeyword.name = keyword;
                newKeyword.session = session;
            }

            NSSet *foundConferenceKeywords = [conference.conferenceKeywords objectsPassingTest:^BOOL(id conferenceObj, BOOL *conferenceStop) {
                ConferenceKeyword *conferenceKeyword = (ConferenceKeyword *) conferenceObj;

                return [conferenceKeyword.name isEqualToString:keyword];
            }];

            if ([foundConferenceKeywords count] == 0) {
                ConferenceKeyword *conferenceKeyword = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([ConferenceKeyword class]) inManagedObjectContext:[self managedObjectContext]];

                conferenceKeyword.name = keyword;
                conferenceKeyword.conference = conference;
            }
        }];
    }

    if (ems.keywords != nil) {
        [self deleteAllObjectForPredicate:[NSPredicate predicateWithFormat:@"(session = %@) AND (NOT(name IN %@))",
                                                                           session,
                                                                           ems.keywords]
                                  andType:NSStringFromClass([Keyword class])];
    } else {
        if (session.keywords != nil) {
            [session.keywords enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
                Keyword *keyword = (Keyword *) obj;

                [self.managedObjectContext deleteObject:keyword];
            }];
        }
    }

    session.attachmentCollection = [ems.attachmentCollection absoluteString];
    session.speakerCollection = [ems.speakerCollection absoluteString];

    session.conference = conference;

    if (ems.roomItem != nil) {
        Room *room = [self roomForHref:[ems.roomItem absoluteString]];

        session.room = room;
        session.roomName = room.name;
    }

    if (ems.slotItem != nil) {
        Slot *slot = [self slotForHref:[ems.slotItem absoluteString]];

        session.slot = slot;

        if ([ems.format isEqualToString:@"lightning-talk"]) {
            // Generate lightning slot names on first fetch - so that calculation is based on more correct data
            session.slotName = nil;
        } else {
            session.slotName = [self slotNameForSlot:slot];
        }
    } else {
        session.slotName = @"Time slot not yet allocated";
    }

    if (ems.speakers != nil) {
        [ems.speakers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            EMSSpeaker *emsSpeaker = (EMSSpeaker *) obj;

            Speaker *speaker = [self speakerForHref:[emsSpeaker.href absoluteString]];

            if (speaker == nil) {
                speaker = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([Speaker class])
                                                        inManagedObjectContext:[self managedObjectContext]];
            }

            [self populateSpeaker:speaker fromEMS:emsSpeaker forSession:session];
        }];

        NSSet *emsSpeakers = [NSSet setWithArray:ems.speakers];

        [session.speakers enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
            Speaker *speaker = (Speaker *) obj;

            NSSet *foundSpeakers = [emsSpeakers objectsPassingTest:^BOOL(id speakerObj, BOOL *speakerStop) {
                EMSSpeaker *emsSpeaker = (EMSSpeaker *) speakerObj;

                return [[emsSpeaker.href absoluteString] isEqualToString:speaker.href];
            }];

            if (foundSpeakers.count == 0) {
                [self.managedObjectContext deleteObject:speaker];
            }
        }];
    } else {
        if (session.speakers != nil) {
            [session.speakers enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
                Speaker *speaker = (Speaker *) obj;

                [self.managedObjectContext deleteObject:speaker];
            }];
        }
    }
}

- (void)populateSpeaker:(Speaker *)speaker fromEMS:(EMSSpeaker *)ems forSession:(Session *)session {
    speaker.href = [ems.href absoluteString];
    speaker.name = ems.name;
    speaker.bio = ems.bio;
    speaker.thumbnailUrl = [ems.thumbnailUrl absoluteString];
    if (ems.lastUpdated != nil) {
        speaker.lastUpdated = ems.lastUpdated;
    } else {
        speaker.lastUpdated = [NSDate date];
    }

    speaker.session = session;
}

#pragma mark - public interface

- (Conference *)mostRecentConference {

    return [[self activeConferences] firstObject];
}

- (NSArray *)activeConferences {
    return [self conferencesForPredicate:[NSPredicate predicateWithFormat:@"hintCount > 0"] andSort:[EMSModel conferenceListSortDescriptors]];
}

+ (NSArray *)conferenceListSortDescriptors {
    NSSortDescriptor *startSort = [[NSSortDescriptor alloc]
            initWithKey:@"start" ascending:NO];

    NSSortDescriptor *nameSort = [[NSSortDescriptor alloc]
            initWithKey:@"name" ascending:NO];

    return @[startSort, nameSort];
}

- (BOOL)storeConferences:(NSArray *)conferences error:(NSError **)error {
    if (conferences == nil || conferences.count == 0) {
        if (error != NULL) {
            NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
            [errorDetail setValue:NSLocalizedString(@"Empty conference list seen", @"Error message when trying to store empty conference list.") forKey:NSLocalizedDescriptionKey];
            *error = [NSError errorWithDomain:@"EMSModel" code:100 userInfo:errorDetail];
        }

        return NO;
    }

    NSDictionary *hrefKeyed = [self conferencesKeyedByHref:conferences];

    NSArray *sortedHrefs = [hrefKeyed.allKeys sortedArrayUsingSelector:@selector(compare:)];

    NSArray *sort = @[[[NSSortDescriptor alloc] initWithKey:@"href" ascending:YES]];

    // Get two lists - all matching - all not matching
    NSArray *matched = [self
            conferencesForPredicate:[NSPredicate predicateWithFormat:@"(href IN %@)", sortedHrefs]
                            andSort:sort];

    NSArray *unmatched = [self
            conferencesForPredicate:[NSPredicate predicateWithFormat:@"NOT (href IN %@)", sortedHrefs]
                            andSort:sort];


    // Walk thru non-matching and delete
    DDLogVerbose(@"Deleting %lu conferences", (unsigned long) [unmatched count]);

    [unmatched enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        Conference *conference = (Conference *) obj;

        [[self managedObjectContext] deleteObject:conference];
    }];

    // Walk thru matching and for each one - update. Store in list
    DDLogVerbose(@"Updating %lu conferences", (unsigned long) [matched count]);

    NSMutableSet *seen = [[NSMutableSet alloc] init];

    [matched enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        Conference *conference = (Conference *) obj;

        [seen addObject:conference.href];

        [self populateConference:conference fromEMS:hrefKeyed[conference.href]];
    }];

    // Walk thru any new ones left
    DDLogVerbose(@"Inserting from %lu conferences with %lu seen", (unsigned long) [hrefKeyed count], (unsigned long) [seen count]);

    [hrefKeyed enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if (![seen containsObject:key]) {
            Conference *conference = [NSEntityDescription
                    insertNewObjectForEntityForName:NSStringFromClass([Conference class])
                             inManagedObjectContext:[self managedObjectContext]];

            EMSConference *ems = (EMSConference *) obj;

            [self populateConference:conference fromEMS:ems];
        }
    }];

    NSError *saveError = nil;

    if (![[self managedObjectContext] save:&saveError]) {
        DDLogError(@"Failed to save conferences %@ - %@", saveError, [saveError userInfo]);

        *error = saveError;

        return NO;
    }

    return YES;
}

- (BOOL)storeSlots:(NSArray *)slots forHref:(NSString *)href error:(NSError **)error {
    if (slots == nil || slots.count == 0) {
        if (error != NULL) {
            NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
            [errorDetail setValue:NSLocalizedString(@"Empty slots list seen"  , @"Error message when trying to save empty slot list.") forKey:NSLocalizedDescriptionKey];
            *error = [NSError errorWithDomain:@"EMSModel" code:200 userInfo:errorDetail];
        }

        return NO;
    }

    NSArray *conferences = [self
            conferencesForPredicate:[NSPredicate predicateWithFormat:@"(slotCollection LIKE %@)", href]
                            andSort:nil];

    if (conferences.count == 0) {
        NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
        [errorDetail setValue:NSLocalizedString(@"Conference not found in database", @"Error message if conference was not found in database when saving slots.") forKey:NSLocalizedDescriptionKey];
        *error = [NSError errorWithDomain:@"EMS" code:100 userInfo:errorDetail];
        return NO;
    }

    if (conferences.count > 1) {
        DDLogWarn(@"Found %lu conferences for slot collection href %@", (unsigned long) conferences.count, href);

        [self analyticsWarningForType:@"conferenceForSlotCollection" andHref:href withCount:@(conferences.count)];
    }

    Conference *conference = conferences[0];

    NSDictionary *hrefKeyed = [self slotsKeyedByHref:slots];

    NSArray *sortedHrefs = [hrefKeyed.allKeys sortedArrayUsingSelector:@selector(compare:)];

    NSArray *sort = @[[[NSSortDescriptor alloc] initWithKey:@"href" ascending:YES]];

    // Get two lists - all matching - all not matching
    NSArray *matched = [self
            slotsForPredicate:[NSPredicate predicateWithFormat:@"((href IN %@) AND conference == %@)", sortedHrefs, conference]
                      andSort:sort];

    NSArray *unmatched = [self
            slotsForPredicate:[NSPredicate predicateWithFormat:@"((NOT (href IN %@)) AND conference == %@)", sortedHrefs, conference]
                      andSort:sort];


    // Walk thru non-matching and delete
    DDLogVerbose(@"Deleting %lu slots", (unsigned long) [unmatched count]);

    [unmatched enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        Slot *slot = (Slot *) obj;

        [[self managedObjectContext] deleteObject:slot];
    }];

    // Walk thru matching and for each one - update. Store in list
    DDLogVerbose(@"Updating %lu slots", (unsigned long) [matched count]);

    NSMutableSet *seen = [[NSMutableSet alloc] init];

    [matched enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        Slot *slot = (Slot *) obj;

        [seen addObject:slot.href];

        [self populateSlot:slot fromEMS:hrefKeyed[slot.href] forConference:conference];
    }];

    // Walk thru any new ones left
    DDLogVerbose(@"Inserting from %lu slots with %lu seen", (unsigned long) [hrefKeyed count], (unsigned long) [seen count]);

    [hrefKeyed enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if (![seen containsObject:key]) {
            Slot *slot = [NSEntityDescription
                    insertNewObjectForEntityForName:NSStringFromClass([Slot class])
                             inManagedObjectContext:[self managedObjectContext]];

            EMSSlot *ems = (EMSSlot *) obj;

            [self populateSlot:slot fromEMS:ems forConference:conference];
        }
    }];

    NSError *saveError = nil;

    if (![[self managedObjectContext] save:&saveError]) {
        DDLogError(@"Failed to save conferences %@ - %@", saveError, [saveError userInfo]);

        *error = saveError;

        return NO;
    }

    return YES;
}

- (BOOL)storeRooms:(NSArray *)rooms forHref:(NSString *)href error:(NSError **)error {
    if (rooms == nil || rooms.count == 0) {
        if (error != NULL) {
            NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
            [errorDetail setValue:NSLocalizedString(@"Empty rooms list seen", @"Error message when trying to save an empty room list.") forKey:NSLocalizedDescriptionKey];
            *error = [NSError errorWithDomain:@"EMSModel" code:300 userInfo:errorDetail];
        }

        return NO;
    }

    NSArray *conferences = [self
            conferencesForPredicate:[NSPredicate predicateWithFormat:@"(roomCollection LIKE %@)", href]
                            andSort:nil];

    if (conferences.count == 0) {
        if (error != NULL) {
            NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
            [errorDetail setValue:NSLocalizedString(@"Conference not found in database", @"Error message if conference was not found when trying to store room list.") forKey:NSLocalizedDescriptionKey];
            *error = [NSError errorWithDomain:@"EMS" code:100 userInfo:errorDetail];
        }
        return NO;
    }

    if (conferences.count > 1) {
        DDLogWarn(@"Found %lu conferences for room collection href %@", (unsigned long) conferences.count, href);

        [self analyticsWarningForType:@"conferenceForRoomCollection" andHref:href withCount:@(conferences.count)];
    }

    Conference *conference = conferences[0];

    NSDictionary *hrefKeyed = [self roomsKeyedByHref:rooms];

    NSArray *sortedHrefs = [hrefKeyed.allKeys sortedArrayUsingSelector:@selector(compare:)];

    NSArray *sort = @[[[NSSortDescriptor alloc] initWithKey:@"href" ascending:YES]];

    // Get two lists - all matching - all not matching
    NSArray *matched = [self
            roomsForPredicate:[NSPredicate predicateWithFormat:@"((href IN %@) AND conference == %@)", sortedHrefs, conference]
                      andSort:sort];

    NSArray *unmatched = [self
            roomsForPredicate:[NSPredicate predicateWithFormat:@"((NOT (href IN %@)) AND conference == %@)", sortedHrefs, conference]
                      andSort:sort];

    // Walk thru non-matching and delete
    DDLogVerbose(@"Deleting %lu rooms", (unsigned long) [unmatched count]);

    [unmatched enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        Room *room = (Room *) obj;

        [[self managedObjectContext] deleteObject:room];
    }];

    // Walk thru matching and for each one - update. Store in list
    DDLogVerbose(@"Updating %lu rooms", (unsigned long) [matched count]);

    NSMutableSet *seen = [[NSMutableSet alloc] init];

    [matched enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        Room *room = (Room *) obj;

        [seen addObject:room.href];

        [self populateRoom:room fromEMS:hrefKeyed[room.href] forConference:conference];
    }];

    // Walk thru any new ones left
    DDLogVerbose(@"Inserting from %lu rooms with %lu seen", (unsigned long) [hrefKeyed count], (unsigned long) [seen count]);

    [hrefKeyed enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if (![seen containsObject:key]) {
            Room *room = [NSEntityDescription
                    insertNewObjectForEntityForName:NSStringFromClass([Room class])
                             inManagedObjectContext:[self managedObjectContext]];

            EMSRoom *ems = (EMSRoom *) obj;

            [self populateRoom:room fromEMS:ems forConference:conference];
        }
    }];

    NSError *saveError = nil;

    if (![[self managedObjectContext] save:&saveError]) {
        DDLogError(@"Failed to save conferences %@ - %@", saveError, [saveError userInfo]);

        *error = saveError;

        return NO;
    }

    return YES;
}

- (BOOL)storeSpeakers:(NSArray *)speakers forHref:(NSString *)href error:(NSError **)error {
    if (speakers == nil || speakers.count == 0) {
        if (error != NULL) {
            NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
            [errorDetail setValue:NSLocalizedString(@"Empty speakers list seen",@"Error message when trying to save an empty speaker list.") forKey:NSLocalizedDescriptionKey];
            *error = [NSError errorWithDomain:@"EMSModel" code:400 userInfo:errorDetail];
        }

        return NO;
    }

    NSArray *sessions = [self
            sessionsForPredicate:[NSPredicate predicateWithFormat:@"(speakerCollection LIKE %@)", href]
                         andSort:nil];

    if (sessions.count == 0) {
        if (error != NULL) {
            NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
            [errorDetail setValue:NSLocalizedString(@"Conference not found in database", @"Error message if conference not found in database when trying to save speaker collection.") forKey:NSLocalizedDescriptionKey];
            *error = [NSError errorWithDomain:@"EMS" code:100 userInfo:errorDetail];
        }
        return NO;
    }

    if (sessions.count > 1) {
        DDLogWarn(@"Found %lu sessions for speaker collection href %@", (unsigned long) sessions.count, href);

        [self analyticsWarningForType:@"sessionsForSpeakerCollection" andHref:href withCount:@(sessions.count)];
    }

    Session *session = sessions[0];

    NSDictionary *hrefKeyed = [self speakersKeyedByHref:speakers];

    NSArray *sortedHrefs = [hrefKeyed.allKeys sortedArrayUsingSelector:@selector(compare:)];

    NSArray *sort = @[[[NSSortDescriptor alloc] initWithKey:@"href" ascending:YES]];

    // Get two lists - all matching - all not matching
    NSArray *matched = [self
            speakersForPredicate:[NSPredicate predicateWithFormat:@"((href IN %@) AND session == %@)", sortedHrefs, session]
                         andSort:sort];

    NSArray *unmatched = [self
            speakersForPredicate:[NSPredicate predicateWithFormat:@"((NOT (href IN %@)) AND session == %@)", sortedHrefs, session]
                         andSort:sort];

    // Walk thru non-matching and delete
    DDLogVerbose(@"Deleting %lu speakers", (unsigned long) [unmatched count]);

    [unmatched enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        Speaker *speaker = (Speaker *) obj;

        [[self managedObjectContext] deleteObject:speaker];
    }];

    // Walk thru matching and for each one - update. Store in list
    DDLogVerbose(@"Updating %lu speakers", (unsigned long) [matched count]);

    NSMutableSet *seen = [[NSMutableSet alloc] init];

    [matched enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        Speaker *speaker = (Speaker *) obj;

        [seen addObject:speaker.href];

        [self populateSpeaker:speaker fromEMS:hrefKeyed[speaker.href] forSession:session];
    }];

    // Walk thru any new ones left
    DDLogVerbose(@"Inserting from %lu speakers with %lu seen", (unsigned long) [hrefKeyed count], (unsigned long) [seen count]);

    [hrefKeyed enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if (![seen containsObject:key]) {
            Speaker *speaker = [NSEntityDescription
                    insertNewObjectForEntityForName:NSStringFromClass([Speaker class])
                             inManagedObjectContext:[self managedObjectContext]];

            EMSSpeaker *ems = (EMSSpeaker *) obj;

            [self populateSpeaker:speaker fromEMS:ems forSession:session];
        }
    }];

    NSError *saveError = nil;

    if (![[self managedObjectContext] save:&saveError]) {
        DDLogError(@"Failed to save conferences %@ - %@", saveError, [saveError userInfo]);

        *error = saveError;

        return NO;
    }

    return YES;
}

- (BOOL)storeSessions:(NSArray *)sessions forHref:(NSString *)href error:(NSError **)error {
    __block NSTimeInterval maxDuration = 0;
    
    if (sessions == nil || sessions.count == 0) {
        if (error != NULL) {
            NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
            [errorDetail setValue:NSLocalizedString(@"Empty sessions list seen", @"Error message if trying to save empty session list.") forKey:NSLocalizedDescriptionKey];
            *error = [NSError errorWithDomain:@"EMSModel" code:500 userInfo:errorDetail];
        }

        return NO;
    }

    NSArray *conferences = [self
            conferencesForPredicate:[NSPredicate predicateWithFormat:@"(sessionCollection LIKE %@)", href]
                            andSort:nil];

    if (conferences.count == 0) {
        NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
        [errorDetail setValue:NSLocalizedString(@"Conference not found in database", @"Error message if conference not found when trying to save session collection.") forKey:NSLocalizedDescriptionKey];
        *error = [NSError errorWithDomain:@"EMS" code:100 userInfo:errorDetail];
        return NO;
    }

    if (conferences.count > 1) {
        DDLogWarn(@"Found %lu conferences for session collection href %@", (unsigned long) conferences.count, href);

        [self analyticsWarningForType:@"conferenceForSessionCollection" andHref:href withCount:@(conferences.count)];
    }

    Conference *conference = conferences[0];

    NSDictionary *hrefKeyed = [self sessionsKeyedByHref:sessions];

    NSArray *sortedHrefs = [hrefKeyed.allKeys sortedArrayUsingSelector:@selector(compare:)];

    NSArray *sort = @[[[NSSortDescriptor alloc] initWithKey:@"href" ascending:YES]];

    // Get two lists - all matching - all not matching
    NSArray *matched = [self
            sessionsForPredicate:[NSPredicate predicateWithFormat:@"((href IN %@) AND conference == %@)", sortedHrefs, conference]
                         andSort:sort];

    NSArray *unmatched = [self
            sessionsForPredicate:[NSPredicate predicateWithFormat:@"((NOT (href IN %@)) AND conference == %@)", sortedHrefs, conference]
                         andSort:sort];


    // Walk thru non-matching and delete
    DDLogVerbose(@"Deleting %lu sessions", (unsigned long) [unmatched count]);

    [unmatched enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        Session *session = (Session *) obj;

        [[self managedObjectContext] deleteObject:session];
    }];

    // Walk thru matching and for each one - update. Store in list
    DDLogVerbose(@"Updating %lu sessions", (unsigned long) [matched count]);

    NSMutableSet *seen = [[NSMutableSet alloc] init];

    [matched enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        Session *session = (Session *) obj;

        [seen addObject:session.href];

        [self populateSession:session fromEMS:hrefKeyed[session.href] forConference:conference];

        if (![session.format isEqualToString:@"workshop"]) {
            maxDuration = fmax(maxDuration, [session duration]);
        }
    }];


    // Walk thru any new ones left
    DDLogVerbose(@"Inserting from %lu sessions with %lu seen", (unsigned long) [hrefKeyed count], (unsigned long) [seen count]);

    [hrefKeyed enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if (![seen containsObject:key]) {
            Session *session = [NSEntityDescription
                    insertNewObjectForEntityForName:NSStringFromClass([Session class])
                             inManagedObjectContext:[self managedObjectContext]];

            // New sessions are not favourites by default.
            session.favourite = @NO;

            EMSSession *ems = (EMSSession *) obj;

            [self populateSession:session fromEMS:ems forConference:conference];

            if (![session.format isEqualToString:@"workshop"]) {
                maxDuration = fmax(maxDuration, [session duration]);
            }
        }
    }];

    // Fixup short sessions
    DDLogVerbose(@"Setting slotName for short sessions");
    NSArray *sessionsWithSlot = [self
                      sessionsForPredicate:[NSPredicate predicateWithFormat:@"format == %@ AND conference == %@ AND slot != nil", @"presentation", conference] andSort:nil];
    
    [sessionsWithSlot enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        Session *session = (Session *)obj;
        
        if (session.duration < maxDuration) {
            [session setSlotName:[self slotNameForStart:session.slot.start toEnd:[NSDate dateWithTimeInterval:maxDuration sinceDate:session.slot.start]]];
        }
    }];
    
    // Fixup lightning sessions
    DDLogVerbose(@"Setting slotName for lightning sessions");
    NSArray *lightning = [self
            sessionsForPredicate:[NSPredicate predicateWithFormat:@"(format == %@ AND conference == %@)", @"lightning-talk", conference]
                         andSort:nil];

    [lightning enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        Session *session = (Session *) obj;

        [session setSlotName:[self getSlotNameForLightningSlot:session.slot forConference:conference withMaxDuration:maxDuration]];
    }];

    if ((conference.start == nil || conference.end == nil) && conference.sessions.count > 0) {
        DDLogVerbose(@"Setting conference dates from session dates for href %@", conference.href);

        NSSortDescriptor *dateDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"slot.start" ascending:YES];
        NSArray *sorted = [self sessionsForPredicate:[NSPredicate predicateWithFormat:@"(format != %@ AND conference == %@)", @"workshop", conference] andSort:@[dateDescriptor]];

        if (conference.start == nil) {
            Session *first = sorted[0];
            DDLogVerbose(@"Setting conference start date from session for href %@ to %@", conference.href, first.slot.start);
            conference.start = first.slot.start;
        }
        if (conference.end == nil) {
            Session *last = [sorted lastObject];
            DDLogVerbose(@"Setting conference end date from session for href %@ to %@", conference.href, last.slot.end);
            conference.end = last.slot.end;
        }
    }

    DDLogVerbose(@"Need to delete conference metafields where none on session");

    // TODO - delete metafields
//    [self deleteAllObjectForPredicate:[NSPredicate predicateWithFormat:@"NONE conference.sessions.keywords == SELF"] andType:@"ConferenceKeyword"];
//    [self deleteAllObjectForPredicate:[NSPredicate predicateWithFormat:@"NONE conference.sessions.levels == SELF"] andType:@"ConferenceLevel"];
//    [self deleteAllObjectForPredicate:[NSPredicate predicateWithFormat:@"NONE conference.sessions.format == SELF"] andType:@"ConferenceType"];

    DDLogVerbose(@"Persisting");
    NSError *saveError = nil;

    if (![[self managedObjectContext] save:&saveError]) {
        DDLogError(@"Failed to save conferences %@ - %@", saveError, [saveError userInfo]);

        *error = saveError;

        return NO;
    }

    return YES;
}

#pragma mark - utility

- (NSString *)getSlotNameForLightningSlot:(Slot *)slot forConference:(Conference *)conference withMaxDuration:(NSTimeInterval) maxDuration {
    if (slot == nil || slot.start == nil || slot.end == nil) {
        DDLogVerbose(@"GSNFLS: Slot data looks strange, %@, %@, %@", slot, slot.start, slot.end);

        return nil;
    }

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(((start <= %@) AND (end >= %@)) AND SELF != %@ AND conference == %@)",
                                                              slot.start,
                                                              slot.end,
                                                              slot,
                                                              conference];

    DDLogVerbose(@"GSNFLS: Getting slot name for %@ - %@", slot.start, slot.end);

    NSArray *slots = [self slotsForPredicate:predicate andSort:nil];

    __block Slot *found = nil;

    DDLogVerbose(@"GSNFLS: Found %lu possible slots for %@ - %@", (unsigned long) slots.count, slot.start, slot.end);

    [slots enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        Slot *s = (Slot *) obj;

        DDLogVerbose(@"GSNFLS: Checking %@ - %@ with %lu possible slots for %@ - %@", s.start, s.end, (unsigned long) s.sessions.count, slot.start, slot.end);

        if ([s.end timeIntervalSinceDate:s.start] == maxDuration) {
            if (s.sessions.count > 0) {
                if (![s.sessions containsObject:slot]) {
                    __block BOOL sawWorkshop = NO;

                    [s.sessions enumerateObjectsUsingBlock:^(id sessionObj, BOOL *sessionStop) {
                        Session *session = (Session *) sessionObj;

                        if ([session.format isEqualToString:@"workshop"]) {
                            sawWorkshop = YES;
                            *sessionStop = YES;
                        }
                    }];

                    if (!sawWorkshop) {
                        DDLogVerbose(@"GSNFLS: Found %@ - %@ for %@ - %@", s.start, s.end, slot.start, slot.end);

                        found = s;
                        *stop = YES;
                    }
                }
            }
        }
    }];

    if (found) {
        DDLogVerbose(@"GSNFLS: Returning %@ - %@ for %@ - %@", found.start, found.end, slot.start, slot.end);

        return [self slotNameForSlot:found];
    }

    DDLogVerbose(@"GSNFLS: Returning self for %@ - %@", slot.start, slot.end);

    // Default to our own name
    return [self slotNameForSlot:slot];
}

- (NSString *)slotNameForSlot:(Slot *)slot {
    if (slot == nil || slot.start == nil || slot.end == nil) {
        DDLogVerbose(@"GSNFS: Slot data looks strange, %@, %@, %@", slot, slot.start, slot.end);

        return nil;
    }

    return [self slotNameForStart:slot.start toEnd:slot.end];
}

- (NSString *)slotNameForStart:(NSDate *)start toEnd:(NSDate *)end {
    static NSDateFormatter *dateFormatterDate;
    static NSDateFormatter *dateFormatterTime;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatterDate = [[NSDateFormatter alloc] init];
        dateFormatterTime = [[NSDateFormatter alloc] init];
        
        [dateFormatterDate setDateFormat:@"yyyy-MM-dd"];
        [dateFormatterTime setDateFormat:@"HH:mm"];
    });
    
    return [NSString stringWithFormat:@"%@ %@ - %@",
            [dateFormatterDate stringFromDate:start],
            [dateFormatterTime stringFromDate:start],
            [dateFormatterTime stringFromDate:end]];
}

- (Session *)toggleFavourite:(Session *)session {
    DDLogVerbose(@"Trying to toggle favourite for %@", session);

    BOOL isFavourite = [session.favourite boolValue];

    if (isFavourite) {
        session.favourite = @NO;
        
        [EMSTracking trackEventWithCategory:@"favourite" action:@"remove" label:session.href];

        if ([EMSFeatureConfig isFeatureEnabled:fRemoteNotifications]) {
            // TODO
        }
    } else {
        session.favourite = @YES;
        
        [EMSTracking trackEventWithCategory:@"favourite" action:@"add" label:session.href];

        if ([EMSFeatureConfig isFeatureEnabled:fRemoteNotifications]) {
            // TODO
        }
    }

    NSError *error;
    if (![[self managedObjectContext] save:&error]) {
        DDLogError(@"Failed to toggle favourite for %@, %@, %@", session, error, [error userInfo]);
    }

    [[EMSAppDelegate sharedAppDelegate] syncManagedObjectContext];

    return session;
}


- (NSDate *)dateForConference:(Conference *)conference andDate:(NSDate *)date {
    NSSortDescriptor *dateDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"slot.start" ascending:YES];
    NSArray *sessions = [self sessionsForPredicate:[NSPredicate predicateWithFormat:@"(format != %@ AND conference == %@)", @"workshop", conference] andSort:@[dateDescriptor]];
    
    Session *firstSession = sessions[0];
    NSDate *conferenceDate = firstSession.slot.start;
    
    if (conferenceDate == nil) {
        return nil;
    }
    
    return [NSDate dateForDate:date fromDate:conferenceDate];
}

- (SpeakerPic *)speakerPicForHref:(NSString *)url {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];

    [fetchRequest setEntity:[NSEntityDescription entityForName:@"SpeakerPic" inManagedObjectContext:[self managedObjectContext]]];

    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"(url LIKE %@)", url]];

    NSError *error;

    NSArray *objects = [[self managedObjectContext] executeFetchRequest:fetchRequest error:&error];

    if (error) {
        DDLogError(@"Failed to fetch speaker pic for url %@, - %@ - %@", url, error, [error userInfo]);
    }

    if ([objects count] > 0) {
        return objects[0];
    }

    return nil;
}

- (NSDate *)dateForSpeakerPic:(NSString *)url {
    SpeakerPic *speakerPic = [self speakerPicForHref:url];

    if (speakerPic) {
        return speakerPic.lastUpdated;
    }

    return nil;
}

- (void)setDate:(NSDate *)date ForSpeakerPic:(NSString *)url {
    SpeakerPic *speakerPic = [self speakerPicForHref:url];

    if (speakerPic == nil) {
        speakerPic = [NSEntityDescription
                insertNewObjectForEntityForName:NSStringFromClass([SpeakerPic class])
                         inManagedObjectContext:[self managedObjectContext]];

        speakerPic.url = url;
    }

    speakerPic.lastUpdated = date;

}


- (void)deleteAllObjectForPredicate:(NSPredicate *)predicate andType:(NSString *)type {
    NSArray *objects = [self objectsForPredicate:predicate
                                         andSort:nil
                                        withType:type];

    [objects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSManagedObject *object = (NSManagedObject *) obj;

        [self.managedObjectContext deleteObject:object];
    }];
}

- (void)analyticsWarningForType:(NSString *)type andHref:(NSString *)href withCount:(NSNumber *)count {
    [EMSTracking trackEventWithCategory:@"warning" action:type label:href value:count];
}

- (void)clearConference:(Conference *)conference {
    [EMSTracking trackEventWithCategory:@"clearing" action:@"deleting" label:conference.href];

    [conference.sessions enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        NSManagedObject *dbObj = (NSManagedObject *) obj;

        [self.managedObjectContext deleteObject:dbObj];
    }];
    [conference.slots enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        NSManagedObject *dbObj = (NSManagedObject *) obj;

        [self.managedObjectContext deleteObject:dbObj];
    }];
    [conference.rooms enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        NSManagedObject *dbObj = (NSManagedObject *) obj;

        [self.managedObjectContext deleteObject:dbObj];
    }];
    [conference.conferenceKeywords enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        NSManagedObject *dbObj = (NSManagedObject *) obj;

        [self.managedObjectContext deleteObject:dbObj];
    }];
    [conference.conferenceLevels enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        NSManagedObject *dbObj = (NSManagedObject *) obj;

        [self.managedObjectContext deleteObject:dbObj];
    }];
    [conference.conferenceTypes enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        NSManagedObject *dbObj = (NSManagedObject *) obj;

        [self.managedObjectContext deleteObject:dbObj];
    }];
    conference.start = nil;
    conference.end = nil;

    NSError *saveError = nil;

    if (![[self managedObjectContext] save:&saveError]) {
        DDLogError(@"Failed to save conference after clearing %@ - %@", saveError, [saveError userInfo]);
    }
}

- (Rating *)ratingForSession:(Session *)session {
    RatingApi *api = [[RatingApi alloc] initWithServer: [[EMSConfig ratingUrl] absoluteString]];
    
    NSURL *url = [api urlFromSession:session];
    
    if (url != nil) {
        
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        
        [fetchRequest setEntity:[NSEntityDescription entityForName:@"Rating" inManagedObjectContext:[self managedObjectContext]]];
        
        [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"(href LIKE %@)", [url absoluteString]]];
        
        NSError *error;
        
        NSArray *objects = [[self managedObjectContext] executeFetchRequest:fetchRequest error:&error];
        
        if (error) {
            DDLogError(@"Failed to fetch rating for url %@, - %@ - %@", url, error, [error userInfo]);
        }
        
        if ([objects count] > 0) {
            return objects[0];
        }
    }
    
    return nil;
}

- (BOOL)setRatingOverall:(int)overall content:(int)content quality:(int)quality relevance:(int)relevance comments:(NSString *)comments forSession:(Session *)session  error:(NSError **)error {
    Rating *rating = [self ratingForSession:session];
    
    if (rating == nil) {
        RatingApi *api = [[RatingApi alloc] initWithServer: [[EMSConfig ratingUrl] absoluteString]];
        
        NSURL *url = [api urlFromSession:session];

        if (url != nil) {
            rating = [NSEntityDescription
                                insertNewObjectForEntityForName:@"Rating"
                                inManagedObjectContext:[self managedObjectContext]];

            rating.href = [url absoluteString];
        } else {
            NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
            [errorDetail setValue:NSLocalizedString(@"Unable to generate rating href from session", @"Error message when trying to store rating.") forKey:NSLocalizedDescriptionKey];
            if (error != NULL) {
                *error = [NSError errorWithDomain:@"EMSModel" code:100 userInfo:errorDetail];
            }
            
            return NO;
        }
    }
    
    if (rating != nil) {
        rating.overall = [NSNumber numberWithInt:overall];
        rating.content = [NSNumber numberWithInt:content];
        rating.quality = [NSNumber numberWithInt:quality];
        rating.relevance = [NSNumber numberWithInt:relevance];
        rating.comments = comments;
    }
    
    NSError *saveError = nil;
    
    if (![[self managedObjectContext] save:&saveError]) {
        DDLogError(@"Failed to save rating %@ - %@", saveError, [saveError userInfo]);
        
        *error = saveError;
        
        return NO;
    }
    
    return YES;
}


@end
