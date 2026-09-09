# Set-Win11-Defaults-Package

This folder contains an Intune Win32 app deployment package for configuring Windows 11 UI preferences for both current and future users.

## 🔧 What It Does

- Sets Start Menu alignment to left
- Shows file extensions
- Hides Task View button
- Sets Search box to icon only
- Enables classic right-click menu
- Prevents Start Menu from showing on upgrade
- Hides "Learn more about this picture"
- Disables Windows Spotlight on desktop
- Applies changes to both HKCU and C:\Users\Default

---

## 📤 Deploying via Intune (Win32 App)

1. Use the [IntuneWinAppUtil](https://learn.microsoft.com/en-us/mem/intune/apps/apps-win32-app-management) to package this folder:
   ```bash
   IntuneWinAppUtil.exe -c . -s Install.cmd -o .
   ```

2. In Intune Admin Center:
   - Go to **Apps** > **Windows** > **Add**
   - Choose **App type**: `Windows app (Win32)`

3. Configure the app:
   - **Install command**: `Install.cmd`
   - **Uninstall command**: *(leave blank or use a no-op placeholder like `exit 0`)*
   - **Install behavior**: `System`
   - **Run script in 64-bit process**: Yes

4. **Detection rules**:
   - Use a **custom script**
   - Upload `Detect-DefaultUserUISettings.ps1`

5. Assign the app to a device group (Autopilot or All Devices)

---

## 📝 Logs

Outputs to:
```
C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\Set-Win11Defaults.log
```

## ✍️ Author

**Virtual Caffeine IO**  
[https://virtualcaffeine.io](https://virtualcaffeine.io)
