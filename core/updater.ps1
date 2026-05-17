$remote = irm https://raw.githubusercontent.com/ADFservice/adf-kit/main/config/version.json
Write-Host "Versão remota:" $remote.version