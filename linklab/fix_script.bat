@echo off
echo 修復Flutter項目編譯錯誤...
echo.

:: 1. 修復IconData類型錯誤 - 將 IconData 轉換爲 Icon Widget
powershell -Command "(Get-Content lib/screens/security/emergency_contacts_screen.dart) -replace 'prefixIcon: Icons\.', 'prefixIcon: const Icon(Icons.' | Set-Content lib/screens/security/emergency_contacts_screen.dart"

:: 2. 修復tooltipBgColor
powershell -Command "(Get-Content lib/admin/screens/statistics_page.dart) -replace 'tooltipBgColor:.*?,', 'getTooltipColor: (group) => Colors.grey[800]!,' | Set-Content lib/admin/screens/statistics_page.dart"

echo 修復完成！
pause
