with open('Tweak.xm', 'r') as f:
    c = f.read()

# Fix 1: dismiss keyboard on activate
old1 = '''    if (key.length < 5) {
        self.statusLabel.text      = @"⚠ Insira uma key válida.";
        self.statusLabel.textColor = [UIColor colorWithRed:0.96f green:0.45f blue:0.09f alpha:1.0f];
        return;
    }

    self.activateBtn.enabled = NO;'''

new1 = '''    if (key.length < 5) {
        self.statusLabel.text      = @"⚠ Insira uma key válida.";
        self.statusLabel.textColor = [UIColor colorWithRed:0.96f green:0.45f blue:0.09f alpha:1.0f];
        return;
    }

    [self.keyField resignFirstResponder];
    self.activateBtn.enabled = NO;'''

# Fix 2: safe dismiss (retain window strongly)
old2 = '''                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        // Save and dismiss
                        NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
                        [ud setObject:key forKey:kKeyStored];
                        [ud setBool:YES   forKey:kKeyValid];
                        [ud setObject:json[@"expires_at"] ?: @"" forKey:kKeyExpiry];
                        [ud synchronize];
                        gLicenseWindow.hidden = YES;
                        gLicenseWindow        = nil;
                        gBlurWindow.hidden    = YES;
                        gBlurWindow           = nil;
                    });'''

new2 = '''                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        // Save license
                        NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
                        [ud setObject:key forKey:kKeyStored];
                        [ud setBool:YES   forKey:kKeyValid];
                        [ud setObject:json[@"expires_at"] ?: @"" forKey:kKeyExpiry];
                        [ud synchronize];
                        // Safe dismiss - keep strong ref until hidden
                        UIWindow *lw = gLicenseWindow;
                        UIWindow *bw = gBlurWindow;
                        gLicenseWindow = nil;
                        gBlurWindow    = nil;
                        [UIView animateWithDuration:0.3 animations:^{
                            lw.alpha = 0;
                            bw.alpha = 0;
                        } completion:^(BOOL done) {
                            lw.hidden = YES;
                            bw.hidden = YES;
                        }];
                    });'''

c = c.replace(old1, new1)
c = c.replace(old2, new2)

with open('Tweak.xm', 'w') as f:
    f.write(c)
print("OK" if old1 in open('Tweak.xm').read() == False else "replaced")
