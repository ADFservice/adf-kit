$apps = @(
    "Microsoft.XboxApp",
    "Microsoft.SkypeApp",
    "Microsoft.ZuneMusic"
)

foreach ($app in $apps) {
    Get-AppxPackage -Name $app -AllUsers | Remove-AppxPackage
}