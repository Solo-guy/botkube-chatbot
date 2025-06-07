@echo off
echo Đang dừng dịch vụ flutter-executor...
taskkill /f /im flutter-executor.exe 2>nul
timeout /t 2 /nobreak >nul

echo Đang khởi động lại dịch vụ...
start "" "flutter-executor.exe"
echo Dịch vụ đã được khởi động lại!
echo.
echo Lưu ý: Đảm bảo bạn đã thực hiện cập nhật cơ sở dữ liệu trước khi khởi động lại dịch vụ. 