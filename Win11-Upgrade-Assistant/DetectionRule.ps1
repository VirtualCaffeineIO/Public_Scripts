# Detection script for Intune
if (Test-Path "C:\ProgramData\Win11Assistant\IME-Just-Ran.txt") {
    exit 0
}
exit 1
