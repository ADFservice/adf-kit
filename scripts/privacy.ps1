# Telemetria
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Force | Out-Null

New-ItemProperty `
    -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" `
    -Name "AllowTelemetry" `
    -Value 0 `
    -PropertyType DWord `
    -Force | Out-Null

# Consumer Features
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Force | Out-Null

New-ItemProperty `
    -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" `
    -Name "DisableWindowsConsumerFeatures" `
    -Value 1 `
    -PropertyType DWord `
    -Force | Out-Null

# Copilot
New-Item -Path "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot" -Force | Out-Null

New-ItemProperty `
    -Path "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot" `
    -Name "TurnOffWindowsCopilot" `
    -Value 1 `
    -PropertyType DWord `
    -Force | Out-Null