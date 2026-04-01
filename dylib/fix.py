import re

with open('Tweak.xm', 'r') as f:
    content = f.read()

old = '''- (void)showLoadingWithMessages:(NSArray *)msgs completion:(void(^)(void))completion {
    self.activateBtn.hidden = YES;
    self.keyField.hidden    = YES;
    [self.spinner startAnimating];
    __block NSInteger idx = 0;
    void (^__block next)(void);
    next = ^{
        if (idx < msgs.count) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.statusLabel.text      = msgs[idx];
                self.statusLabel.textColor = [UIColor colorWithWhite:.7 alpha:1];
                idx++;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), next);
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{ completion(); });
        }
    };
    next();
}'''

new = '''- (void)showLoadingWithMessages:(NSArray *)msgs completion:(void(^)(void))completion {
    self.activateBtn.hidden = YES;
    self.keyField.hidden    = YES;
    [self.spinner startAnimating];
    NSArray *messages = [msgs copy];
    // Show first message immediately
    if (messages.count > 0) {
        self.statusLabel.text      = messages[0];
        self.statusLabel.textColor = [UIColor colorWithWhite:.7 alpha:1];
    }
    // Show second message after 2s
    if (messages.count > 1) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.statusLabel.text = messages[1];
            // Call completion after another 2s
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                completion();
            });
        });
    } else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            completion();
        });
    }
}'''

content = content.replace(old, new)
with open('Tweak.xm', 'w') as f:
    f.write(content)
print("OK")
