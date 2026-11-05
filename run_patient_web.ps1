Write-Host "Starting Patient App on Chrome (http://localhost:3001)..." -ForegroundColor Cyan
Push-Location flutter_app
try {
    flutter run -d chrome --web-port 3001
} finally {
    Pop-Location
}

