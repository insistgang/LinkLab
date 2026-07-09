@echo off
echo 修复Flutter项目编译错误...
echo.

:: 1. 修复IconData类型错误 - 将 IconData 转换为 Icon Widget
powershell -Command "(Get-Content lib/screens/security/emergency_contacts_screen.dart) -replace 'prefixIcon: Icons\.', 'prefixIcon: const Icon(Icons.' | Set-Content lib/screens/security/emergency_contacts_screen.dart"

:: 2. 修复tooltipBgColor
powershell -Command "(Get-Content lib/admin/screens/statistics_page.dart) -replace 'tooltipBgColor:.*?,', 'getTooltipColor: (group) => Colors.grey[800]!,' | Set-Content lib/admin/screens/statistics_page.dart"

echo 修复完成！
pause
