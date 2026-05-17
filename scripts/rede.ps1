Write-Host "Resetando configurações de rede..."

ipconfig /flushdns
netsh winsock reset
netsh int ip reset

Write-Host "Concluído! Reinicie o computador."
pause