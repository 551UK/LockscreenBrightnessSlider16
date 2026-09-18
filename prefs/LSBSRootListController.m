#import "LSBSRootListController.h"
#import <Preferences/PSSpecifier.h>
#import <UIKit/UIKit.h>
#import <CoreFoundation/CoreFoundation.h>
#import <spawn.h>
#import <unistd.h>

extern char **environ;

static NSString * const LSBSPrefsDomain = @"com.551.lockscreenbrightnessslider16";
static NSString * const LSBSPrefsChanged = @"com.551.lockscreenbrightnessslider16/preferences.changed";

static BOOL LSBSSpawnTool(const char *tool, char * const argv[]) {
    if (!tool || access(tool, X_OK) != 0) return NO;
    pid_t pid = 0;
    return posix_spawn(&pid, tool, NULL, NULL, argv, environ) == 0;
}

@implementation LSBSRootListController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Lockscreen Brightness Slider 16";
}

- (PSSpecifier *)preferenceSpecifierNamed:(NSString *)name
                                      key:(NSString *)key
                             defaultValue:(id)defaultValue
                                     cell:(PSCellType)cell {
    PSSpecifier *specifier = [PSSpecifier preferenceSpecifierNamed:name
                                                            target:self
                                                               set:@selector(setPreferenceValue:specifier:)
                                                               get:@selector(readPreferenceValue:)
                                                            detail:nil
                                                              cell:cell
                                                              edit:nil];
    [specifier setProperty:LSBSPrefsDomain forKey:@"defaults"];
    [specifier setProperty:key forKey:@"key"];
    [specifier setProperty:defaultValue forKey:@"default"];
    [specifier setProperty:LSBSPrefsChanged forKey:@"PostNotification"];
    return specifier;
}

- (NSArray *)specifiers {
    if (_specifiers) return _specifiers;

    NSMutableArray *specifiers = [NSMutableArray array];

    PSSpecifier *mainGroup = [PSSpecifier groupSpecifierWithName:@"Lockscreen Brightness Slider 16"];
    [mainGroup setProperty:@"Adds a brightness slider between the Lock Screen flashlight and camera quick actions." forKey:@"footerText"];
    [specifiers addObject:mainGroup];

    [specifiers addObject:[self preferenceSpecifierNamed:@"Enable Tweak"
                                                     key:@"enabled"
                                            defaultValue:@YES
                                                    cell:PSSwitchCell]];

    PSSpecifier *focusGroup = [PSSpecifier groupSpecifierWithName:@"Lock Screen DND Text"];
    [focusGroup setProperty:@"Hides the temporary “Do Not Disturb” Lock Screen indicator shown between the flashlight and camera quick actions. Do Not Disturb itself still turns on and off normally." forKey:@"footerText"];
    [specifiers addObject:focusGroup];

    [specifiers addObject:[self preferenceSpecifierNamed:@"Hide Do Not Disturb Text"
                                                     key:@"hideDNDText"
                                            defaultValue:@YES
                                                    cell:PSSwitchCell]];

    PSSpecifier *linksGroup = [PSSpecifier groupSpecifierWithName:@"Links"];
    [specifiers addObject:linksGroup];

    PSSpecifier *repo = [PSSpecifier preferenceSpecifierNamed:@"GitHub Repo"
                                                        target:self
                                                           set:nil
                                                           get:nil
                                                        detail:nil
                                                          cell:PSButtonCell
                                                          edit:nil];
    [repo setButtonAction:@selector(openRepo)];
    [repo setProperty:NSStringFromSelector(@selector(openRepo)) forKey:@"action"];
    [specifiers addObject:repo];

    PSSpecifier *actionsGroup = [PSSpecifier groupSpecifierWithName:@"Actions"];
    [actionsGroup setProperty:@"Settings apply immediately. Respring is included for troubleshooting." forKey:@"footerText"];
    [specifiers addObject:actionsGroup];

    PSSpecifier *respring = [PSSpecifier preferenceSpecifierNamed:@"Respring"
                                                            target:self
                                                               set:nil
                                                               get:nil
                                                            detail:nil
                                                              cell:PSButtonCell
                                                              edit:nil];
    [respring setButtonAction:@selector(respring)];
    [respring setProperty:NSStringFromSelector(@selector(respring)) forKey:@"action"];
    [specifiers addObject:respring];

    _specifiers = [specifiers copy];
    return _specifiers;
}

- (id)readPreferenceValue:(PSSpecifier *)specifier {
    NSString *key = [specifier propertyForKey:@"key"];
    id fallback = [specifier propertyForKey:@"default"];
    if (!key) return fallback;

    CFPreferencesAppSynchronize((__bridge CFStringRef)LSBSPrefsDomain);
    CFPropertyListRef value = CFPreferencesCopyAppValue((__bridge CFStringRef)key,
                                                        (__bridge CFStringRef)LSBSPrefsDomain);
    return value ? CFBridgingRelease(value) : fallback;
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
    NSString *key = [specifier propertyForKey:@"key"];
    if (!key) return;

    CFPreferencesSetAppValue((__bridge CFStringRef)key,
                             (__bridge CFPropertyListRef)value,
                             (__bridge CFStringRef)LSBSPrefsDomain);
    CFPreferencesAppSynchronize((__bridge CFStringRef)LSBSPrefsDomain);

    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
                                         (__bridge CFStringRef)LSBSPrefsChanged,
                                         NULL,
                                         NULL,
                                         true);
}

- (void)openRepo {
    NSURL *url = [NSURL URLWithString:@"https://github.com/551UK/LockscreenBrightnessSlider16"];
    if (!url) return;

    UIApplication *application = UIApplication.sharedApplication;
    if ([application respondsToSelector:@selector(openURL:options:completionHandler:)]) {
        [application openURL:url options:@{} completionHandler:nil];
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        [application openURL:url];
#pragma clang diagnostic pop
    }
}

- (void)openRepo:(id)sender {
    (void)sender;
    [self openRepo];
}

- (void)respring {
    const char *sbreload = "/var/jb/usr/bin/sbreload";
    if (access(sbreload, X_OK) == 0) {
        char *args[] = {(char *)sbreload, NULL};
        if (LSBSSpawnTool(sbreload, args)) return;
    }

    const char *rootlessKillall = "/var/jb/usr/bin/killall";
    if (access(rootlessKillall, X_OK) == 0) {
        char *args[] = {(char *)rootlessKillall, (char *)"-9", (char *)"SpringBoard", NULL};
        if (LSBSSpawnTool(rootlessKillall, args)) return;
    }

    const char *systemKillall = "/usr/bin/killall";
    char *args[] = {(char *)systemKillall, (char *)"-9", (char *)"SpringBoard", NULL};
    LSBSSpawnTool(systemKillall, args);
}

- (void)respring:(id)sender {
    (void)sender;
    [self respring];
}

@end
