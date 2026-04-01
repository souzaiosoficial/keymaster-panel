// Tweak.xm — KeyMaster License Check
// Compatível com: GBox, ESign, Sideloadly (sem jailbreak)
// Linguagem: Logos (Objective-C via Theos)

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

// ─────────────────────────────────────────────────────────────
//  CONFIGURE AQUI ▼
// ─────────────────────────────────────────────────────────────
static NSString *const kServerURL   = @"https://SEU_DOMINIO_RAILWAY.up.railway.app";
static NSString *const kKeyStored   = @"KM_LicenseKey";
static NSString *const kKeyValid    = @"KM_LicenseValid";
static NSString *const kKeyExpiry   = @"KM_LicenseExpiry";
// ─────────────────────────────────────────────────────────────

// ── Forward declarations ───────────────────────────────────────
@interface KMLicenseWindow : UIWindow
@end
@interface KMLicenseViewController : UIViewController
@end

// ─────────────────────────────────────────────────────────────
// MARK: - Helpers
// ─────────────────────────────────────────────────────────────

static NSString *getUDID() {
    // GBox/ESign não expõem UDID real — usamos identifierForVendor + keychain persist
    NSString *stored = [[NSUserDefaults standardUserDefaults] stringForKey:@"KM_DeviceID"];
    if (!stored) {
        stored = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
        [[NSUserDefaults standardUserDefaults] setObject:stored forKey:@"KM_DeviceID"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    return stored ?: @"UNKNOWN";
}

static NSString *getDeviceName() {
    return [[UIDevice currentDevice] name] ?: @"iPhone";
}

static BOOL isLicenseValid() {
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    if (![d boolForKey:kKeyValid]) return NO;
    NSString *exp = [d stringForKey:kKeyExpiry];
    if (!exp || [exp isEqualToString:@""]) return YES; // permanente
    NSDateFormatter *f = [[NSDateFormatter alloc] init];
    f.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    NSDate *expDate = [f dateFromString:exp];
    return expDate && [[NSDate date] compare:expDate] == NSOrderedAscending;
}

// ─────────────────────────────────────────────────────────────
// MARK: - License View Controller
// ─────────────────────────────────────────────────────────────

@interface KMLicenseViewController ()
@property (nonatomic, strong) UIView     *cardView;
@property (nonatomic, strong) UITextField *keyField;
@property (nonatomic, strong) UIButton   *activateBtn;
@property (nonatomic, strong) UILabel    *statusLabel;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@end

@implementation KMLicenseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithWhite:0 alpha:0.55];
    [self buildUI];
}

- (void)buildUI {
    CGFloat sw = [UIScreen mainScreen].bounds.size.width;

    // ── Card (rounded rect — idêntico ao print) ─────────────────
    UIView *card = [[UIView alloc] init];
    card.backgroundColor    = [UIColor whiteColor];
    card.layer.cornerRadius = 18;
    card.layer.borderWidth  = 3;
    card.layer.borderColor  = [UIColor blackColor].CGColor;
    card.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:card];
    self.cardView = card;

    [NSLayoutConstraint activateConstraints:@[
        [card.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [card.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [card.widthAnchor  constraintEqualToConstant:MIN(sw - 48, 340)],
    ]];

    // ── "COLOQUE SUA KEY" label ─────────────────────────────────
    UILabel *title = [[UILabel alloc] init];
    title.text          = @"COLOQUE SUA KEY";
    title.textAlignment = NSTextAlignmentCenter;
    title.font          = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    title.textColor     = [UIColor colorWithRed:.13 green:.13 blue:.13 alpha:1];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:title];

    // ── Text field (pill shape — igual ao print) ────────────────
    UITextField *tf = [[UITextField alloc] init];
    tf.placeholder     = @"key";
    tf.textAlignment   = NSTextAlignmentCenter;
    tf.font            = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
    tf.textColor       = [UIColor darkGrayColor];
    tf.backgroundColor = [UIColor whiteColor];
    tf.layer.borderWidth  = 1.5;
    tf.layer.borderColor  = [UIColor blackColor].CGColor;
    tf.layer.cornerRadius = 10;
    tf.autocorrectionType = UITextAutocorrectionTypeNo;
    tf.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
    tf.returnKeyType   = UIReturnKeyDone;
    tf.translatesAutoresizingMaskIntoConstraints = NO;
    [tf addTarget:self action:@selector(tfReturn:) forControlEvents:UIControlEventEditingDidEndOnExit];
    [card addSubview:tf];
    self.keyField = tf;

    // ── Activate button (hidden pill under field) ───────────────
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    [btn setTitle:@"ATIVAR" forState:UIControlStateNormal];
    btn.backgroundColor    = [UIColor blackColor];
    btn.layer.cornerRadius = 10;
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightBold];
    btn.translatesAutoresizingMaskIntoConstraints = NO;
    [btn addTarget:self action:@selector(activate) forControlEvents:UIControlEventTouchUpInside];
    [card addSubview:btn];
    self.activateBtn = btn;

    // ── Status label ────────────────────────────────────────────
    UILabel *status = [[UILabel alloc] init];
    status.text          = @"";
    status.textAlignment = NSTextAlignmentCenter;
    status.font          = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
    status.numberOfLines = 2;
    status.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:status];
    self.statusLabel = status;

    // ── Spinner ─────────────────────────────────────────────────
    UIActivityIndicatorView *spin = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    spin.hidesWhenStopped = YES;
    spin.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:spin];
    self.spinner = spin;

    // ── Layout constraints ──────────────────────────────────────
    [NSLayoutConstraint activateConstraints:@[
        // title
        [title.topAnchor    constraintEqualToAnchor:card.topAnchor    constant:22],
        [title.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:20],
        [title.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-20],

        // text field
        [tf.topAnchor    constraintEqualToAnchor:title.bottomAnchor constant:14],
        [tf.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:20],
        [tf.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-20],
        [tf.heightAnchor constraintEqualToConstant:40],

        // activate btn
        [btn.topAnchor    constraintEqualToAnchor:tf.bottomAnchor constant:12],
        [btn.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:20],
        [btn.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-20],
        [btn.heightAnchor constraintEqualToConstant:38],

        // status
        [status.topAnchor    constraintEqualToAnchor:btn.bottomAnchor constant:10],
        [status.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:20],
        [status.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-20],

        // spinner
        [spin.topAnchor    constraintEqualToAnchor:status.bottomAnchor constant:6],
        [spin.centerXAnchor constraintEqualToAnchor:card.centerXAnchor],

        // card bottom
        [card.bottomAnchor constraintEqualToAnchor:spin.bottomAnchor constant:22],
    ]];
}

- (void)tfReturn:(id)sender { [self activate]; }

- (void)activate {
    NSString *key = [self.keyField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (key.length < 5) {
        [self showStatus:@"Insira uma key válida." color:[UIColor redColor]];
        return;
    }
    [self setLoading:YES];
    [self validateKey:key];
}

- (void)validateKey:(NSString *)key {
    NSURL *url = [NSURL URLWithString:[kServerURL stringByAppendingString:@"/api/validate"]];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    req.HTTPMethod = @"POST";
    [req setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    NSDictionary *body = @{
        @"key":         key,
        @"udid":        getUDID(),
        @"device_name": getDeviceName()
    };
    req.HTTPBody = [NSJSONSerialization dataWithJSONObject:body options:0 error:nil];
    req.timeoutInterval = 15;

    NSURLSession *session = [NSURLSession sharedSession];
    [[session dataTaskWithRequest:req completionHandler:^(NSData *data, NSURLResponse *resp, NSError *err) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setLoading:NO];
            if (err || !data) {
                [self showStatus:@"Sem conexão. Tente novamente." color:[UIColor redColor]];
                return;
            }
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            BOOL valid = [json[@"valid"] boolValue];
            if (valid) {
                // Salvar localmente
                NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
                [d setObject:key         forKey:kKeyStored];
                [d setBool:YES           forKey:kKeyValid];
                [d setObject:json[@"expires_at"] ?: @"" forKey:kKeyExpiry];
                [d synchronize];
                [self showStatus:@"✓ Licença ativada!" color:[UIColor colorWithRed:.1 green:.7 blue:.3 alpha:1]];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self dismiss];
                });
            } else {
                NSString *msg = json[@"message"] ?: @"Key inválida.";
                [self showStatus:msg color:[UIColor redColor]];
            }
        });
    }] resume];
}

- (void)showStatus:(NSString *)msg color:(UIColor *)color {
    self.statusLabel.text      = msg;
    self.statusLabel.textColor = color;
}

- (void)setLoading:(BOOL)loading {
    self.activateBtn.enabled = !loading;
    self.keyField.enabled    = !loading;
    loading ? [self.spinner startAnimating] : [self.spinner stopAnimating];
    [self.activateBtn setTitle:loading ? @"Verificando…" : @"ATIVAR" forState:UIControlStateNormal];
}

- (void)dismiss {
    // Remove a window de licença e libera o app normalmente
    UIWindow *w = self.view.window;
    w.hidden = YES;
}

@end

// ─────────────────────────────────────────────────────────────
// MARK: - Hook no UIApplicationDelegate
// ─────────────────────────────────────────────────────────────

static UIWindow *licenseWindow = nil;

static void showLicenseWindow() {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (licenseWindow) return;

        UIWindowScene *scene = nil;
        for (UIScene *s in [UIApplication sharedApplication].connectedScenes) {
            if ([s isKindOfClass:[UIWindowScene class]] && s.activationState == UISceneActivationStateForegroundActive) {
                scene = (UIWindowScene *)s;
                break;
            }
        }

        UIWindow *w = scene
            ? [[UIWindow alloc] initWithWindowScene:scene]
            : [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];

        w.windowLevel = UIWindowLevelAlert + 200;
        w.backgroundColor = [UIColor clearColor];
        w.rootViewController = [[KMLicenseViewController alloc] init];
        w.hidden = NO;
        [w makeKeyAndVisible];
        licenseWindow = w;
    });
}

%hook UIApplication

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)options {
    BOOL result = %orig;
    if (!isLicenseValid()) {
        showLicenseWindow();
    }
    return result;
}

%end

// Re-verifica ao voltar do background (anti-bypass)
%hook UIApplicationDelegate

- (void)applicationDidBecomeActive:(UIApplication *)application {
    %orig;
    if (!isLicenseValid()) {
        showLicenseWindow();
    }
}

%end
