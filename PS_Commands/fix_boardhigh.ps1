$p = "$env:USERPROFILE\Desktop\AssetManagement\AssetManagement.Web\Controllers\AssetController.cs"
$enc = [System.Text.Encoding]::UTF8
$c = [System.IO.File]::ReadAllText($p, $enc)
$old = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("ICAgICAgICAgICAgSUVudW1lcmFibGU8QXNzZXQ+IGFzc2V0cyA9IHJvbGVzLkNvbnRhaW5zKCJTdXBlckFkbWluIikKICAgICAgICAgICAgICAgID8gYXdhaXQgX3JlcG8uR2V0QWxsQXN5bmMoKQogICAgICAgICAgICAgICAgOiBhd2FpdCBfd29ya2Zsb3cuR2V0QXNzZXRzQnlSb2xlQXN5bmModXNlciEuSWQsIHJvbGVzKTs="))
$new = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("ICAgICAgICAgICAgSUVudW1lcmFibGU8QXNzZXQ+IGFzc2V0cyA9IChyb2xlcy5Db250YWlucygiU3VwZXJBZG1pbiIpIHx8IHJvbGVzLkNvbnRhaW5zKCJCb2FyZF9IaWdoIikpCiAgICAgICAgICAgICAgICA/IGF3YWl0IF9yZXBvLkdldEFsbEFzeW5jKCkKICAgICAgICAgICAgICAgIDogYXdhaXQgX3dvcmtmbG93LkdldEFzc2V0c0J5Um9sZUFzeW5jKHVzZXIhLklkLCByb2xlcyk7"))
if ($c.Contains($old)) {
    $c = $c.Replace($old, $new)
    [System.IO.File]::WriteAllText($p, $c, $enc)
    Write-Host "OK!" -ForegroundColor Green
} else {
    Write-Host "Not found" -ForegroundColor Red
}
dotnet build "$env:USERPROFILE\Desktop\AssetManagement" 2>&1 | Select-Object -Last 3