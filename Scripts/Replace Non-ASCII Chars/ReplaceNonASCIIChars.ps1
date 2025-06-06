Get-ChildItem -LiteralPath "\\?\{location}" |? {$_.Name -match '^.*\s+$|^\s+.*$|^.*\.+$'} |Rename-Item -LiteralPath {$_.FullName} -NewName {$_.Name -replace '\s+$|^\s+|\.+$',''} -PassThru
