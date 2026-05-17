# POWER SETTINGS (corrigido)
try {
    & "$env:SystemRoot\System32\powercfg.exe" -setactive SCHEME_MINIMUM
    Write-Log "Power plan mínimo ativado" "SUCCESS"
} catch {
    Write-Log "Powercfg não disponível (Server)" "WARNING"
}

# GROUP POLICY (corrigido)
try {
    & "$env:SystemRoot\System32\gpupdate.exe" /force
    Write-Log "GPO atualizado" "SUCCESS"
} catch {
    Write-Log "gpupdate não disponível" "WARNING"
}

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