#!/bin/bash
echo "=== Project Structure Test ==="
echo ""

echo "Checking required files..."
echo "1. README.md: $( [ -f "README.md" ] && echo "✅" || echo "❌" )"
echo "2. LICENSE: $( [ -f "LICENSE" ] && echo "✅" || echo "❌" )"
echo "3. install.sh: $( [ -f "install.sh" ] && echo "✅" || echo "❌" )"
echo "4. docs/TROUBLESHOOTING.md: $( [ -f "docs/TROUBLESHOOTING.md" ] && echo "✅" || echo "❌" )"
echo "5. src/wifi_scanner_fixed.sh: $( [ -f "src/wifi_scanner_fixed.sh" ] && echo "✅" || echo "❌" )"
echo "6. scripts/diagnostic.sh: $( [ -f "scripts/diagnostic.sh" ] && echo "✅" || echo "❌" )"
echo "7. examples/quick_scan.sh: $( [ -f "examples/quick_scan.sh" ] && echo "✅" || echo "❌" )"
echo "8. .gitignore: $( [ -f ".gitignore" ] && echo "✅" || echo "❌" )"

echo ""
echo "Checking file permissions..."
echo "install.sh executable: $( [ -x "install.sh" ] && echo "✅" || echo "❌" )"
echo "diagnostic.sh executable: $( [ -x "scripts/diagnostic.sh" ] && echo "✅" || echo "❌" )"
echo "quick_scan.sh executable: $( [ -x "examples/quick_scan.sh" ] && echo "✅" || echo "❌" )"

echo ""
echo "=== Project Structure ==="
find . -type f -name "*.sh" -o -name "*.md" -o -name "LICENSE" -o -name ".gitignore" | sort

echo ""
echo "=== All done! ==="
echo "Your WiFi Scanner Tool project is ready!"
