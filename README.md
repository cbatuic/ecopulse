# ecopulse

A new Flutter project.

### Run
```
flutter run -d web-server --web-host=0.0.0.0 --web-port=8080

flutter build web
cd build/web
python -m http.server 8080 --bind 0.0.0.0

# if PermissionError: [WinError 10013] An attempt was made to access a socket in a way forbidden by its access permissions
netstat -ano | findstr :8080
taskkill /PID <PID> /F

```

### Desktop
```
flutter config --enable-windows-desktop
flutter devices
flutter run -d windows

flutter build windows --release
# build\windows\x64\runner\Release\
# ecopulse.exe
```

### Browser
```
flutter run -d chrome
flutter run -d chrome --web-port=8080
```