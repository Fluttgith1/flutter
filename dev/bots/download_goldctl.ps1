$url= "https://storage.googleapis.com/chrome-infra/depot_tools.zip"
#"https://chrome-infra-packages.appspot.com/p/skia/tools/goldctl/windows-amd64/+/"
$path = "c:\Windows\Temp\flutter sdk\depot_tools.zip"
#"c:\Windows\Temp\flutter sdk\goldctl.zip"

(New-Object System.Net.WebClient).DownloadFile($url, $path)
Expand-Archive -LiteralPath $path -DestinationPath "C:\Windows\Temp\depot_tools"
