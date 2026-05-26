<#
Configurações do Sistema
- Força execução como Administrador
- Apenas avisa SUCESSO ou FALHA
#>

# Verifica e solicita elevação de privilégio
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process pwsh -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$sucesso = $true

try {
    # POWER SETTINGS
    & "$env:SystemRoot\System32\powercfg.exe" -setactive SCHEME_MINIMUM

    # GROUP POLICY
    & "$env:SystemRoot\System32\gpupdate.exe" /force

    # Telemetria
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Force | Out-Null
    New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0 -PropertyType DWord -Force | Out-Null

    # Consumer Features
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Force | Out-Null
    New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsConsumerFeatures" -Value 1 -PropertyType DWord -Force | Out-Null

    # Copilot
    New-Item -Path "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot" -Force | Out-Null
    New-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot" -Name "TurnOffWindowsCopilot" -Value 1 -PropertyType DWord -Force | Out-Null
}
catch {
    $sucesso = $false
}

# Resultado final
if ($sucesso) {
    Write-Host "SUCESSO: Todas as configurações foram aplicadas." -ForegroundColor Green
}
else {
    Write-Host "FALHA: Ocorreu um erro ao aplicar as configurações." -ForegroundColor Red
}

pause