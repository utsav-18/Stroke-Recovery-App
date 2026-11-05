Write-Host "Starting Doctor App on Chrome (http://localhost:3000)..." -ForegroundColor Cyan
Push-Location doctor_app
try {
    flutter run -d chrome --web-port 3000
} finally {
    Pop-Location
}

