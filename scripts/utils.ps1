function Generate-SystemReport {
    Write-Host "[SysBot] Gerando relatório do sistema..." -ForegroundColor Cyan

    $cpu = Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average | Select-Object -ExpandProperty Average
    $memory = Get-CimInstance Win32_OperatingSystem
    $usedMemory = [math]::Round(($memory.TotalVisibleMemorySize - $memory.FreePhysicalMemory) / 1MB, 2)
    $totalMemory = [math]::Round($memory.TotalVisibleMemorySize / 1MB, 2)
    $uptime = (Get-Date) - $memory.LastBootUpTime
    $disk = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3"
    $diskInfo = @()
    foreach ($d in $disk) {
        $diskInfo += @{
            Device = $d.DeviceID
            Free = [math]::Round($d.FreeSpace / 1GB, 2)
            Size = [math]::Round($d.Size / 1GB, 2)
        }
    }

    # Gerar HTML com gráfico (Chart.js)
    $htmlPath = "$env:TEMP\sysbot_report.html"
    $chartData = @"
<!DOCTYPE html>
<html>
<head>
  <title>SysBot Relatório</title>
  <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body style="font-family:sans-serif">
  <h2>Relatório do Sistema (SysBot)</h2>
  <p><strong>Uso de CPU:</strong> $cpu%</p>
  <p><strong>Uso de Memória:</strong> $usedMemory MB / $totalMemory MB</p>
  <p><strong>Tempo de atividade:</strong> $($uptime.Days) dias, $($uptime.Hours)h:$($uptime.Minutes)m</p>
  <canvas id="diskChart" width="600" height="300"></canvas>
  <script>
    const ctx = document.getElementById('diskChart').getContext('2d');
    const chart = new Chart(ctx, {
      type: 'bar',
      data: {
        labels: [$(($diskInfo | ForEach-Object { "'$($_.Device)'" }) -join ", ")],
        datasets: [
          {
            label: 'Espaço Livre (GB)',
            data: [$(($diskInfo | ForEach-Object { $_.Free }) -join ", ")],
            backgroundColor: 'rgba(75, 192, 192, 0.6)'
          },
          {
            label: 'Tamanho Total (GB)',
            data: [$(($diskInfo | ForEach-Object { $_.Size }) -join ", ")],
            backgroundColor: 'rgba(192, 75, 192, 0.6)'
          }
        ]
      }
    });
  </script>
</body>
</html>
"@

    $chartData | Out-File -Encoding UTF8 -FilePath $htmlPath
    Start-Process $htmlPath
}
