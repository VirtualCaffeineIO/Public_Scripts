if (Test-Path "C:\ProgramData\Win11Assistant\IME-Just-Ran.txt") {
    exit 0
} else {
    exit 1
}