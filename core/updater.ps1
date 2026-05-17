$remote = irm https://raw.githubusercontent.com/SEU_USUARIO/ADF-Kit/main/config/version.json
Write-Host "Versão remota:" $remote.version