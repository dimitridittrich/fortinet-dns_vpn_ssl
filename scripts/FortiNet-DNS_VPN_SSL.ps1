<#
Script PowerShell by Dimitri Dittrich - dimitri.dittrich
Date: 29/05/2020

---------------------------
1 - Verifica se tem mais de um registro com o mesmo IP na rede VPN SSL, cria uma nova lista com esses objetos duplicados apenas
2 - Compara as datas/horário do Timestamp desses registro e apaga todos os antigos, mantendo apenas o mais atual
PS: Registros com o timestamp no mesmo horário não são tratados, nesse caso não há o que fazer pois o Timestamp registra somente a hora, não registra
minutos. Desse modo se duas ou mais pessoas conectarem/desconectarem da VPN dentro da mesma hora (o que é bem comum, já vi vários casos no DNS) ele registra o Timestamp com o mesmo horário/data.

Um detalhe importante é que o nosso problema é apenas vários hosts para o mesmo IP.
Não temos o problema de vários IPs para o mesmo Host, pois o DNS Windows não permite isso dentro da mesma subnet.

- Se é menor, apaga ele mesmo e segue pro proximo registro (exit ou outro comando)
- Se é maior, apaga o segundo registro e continua a verificação pro próximo
- Se for igual, não faz nada
- É gerado log do Script na mesma pasta do Script

#>


#------------AUTOMATIC-PATH--------------
$completo = $MyInvocation.MyCommand.Path
$scremailtname = $MyInvocation.MyCommand.Name
$caminho = $completo -replace $scremailtname, ""
#----------------------------------------
cls

function Clean-DNSRegisters-VPNSSL
{
	                    ###########################ScriptDirectory###########################
	                    function Get-ScriptDirectory
	                    {
		                    [OutputType([string])]
		                    param ()
		                    if ($null -ne $hostinvocation)
		                    {
			                    Split-Path $hostinvocation.MyCommand.path
		                    }
		                    else
		                    {
			                    Split-Path $script:MyInvocation.MyCommand.Path
		                    }
	                    }
	                    $scriptPath = Get-ScriptDirectory
	                    ###########################ScriptDirectory###########################
	                    $pathlog = "$scriptPath.\logDNSClean.txt"
	                    $log = ""
#=============================================================================================================================
#=============================================================================================================================
$zonename = "domain.local"
$dnsserver = "serverdc01"
$netscope = "172.30*"
$excludeip = ""

cls
$registers = Get-DnsServerResourceRecord -ComputerName hb-vw16dc02 -ZoneName $zonename -RRType "A" | select-object -Property Hostname,Timestamp, @{Name='RecordData';Expression={$_.RecordData.IPv4Address}} | ?{$_.RecordData -like $netscope} |?{$_.RecordData -notlike $excludeip}
#[array]$log = @()



$registrostratados = @()
foreach ($item in $registers){
 $count=0
 $registers | %{
					if ($item.RecordData.IPAddressToString -like $_.RecordData.IPAddressToString)
					{
					$count++     
					}   
 			   }
	
	if ($count -gt 1)
	{
	#write-host "TEM MAIS DE UM"
	$registrostratados+= $item
	}
}
#$registrostratados | Export-Csv -NoTypeInformation -Encoding UTF8 -UseCulture -Path C:\Users\adm.dimitri.dittrich\Desktop\teste.csv

#=============================================================================================================================
#=============================================================================================================================
foreach ($tratadoitem in $registrostratados){
 $count=0

 $registrostratados | %{
                            if ($tratadoitem.RecordData.IPAddressToString -like $_.RecordData.IPAddressToString -and $tratadoitem.Hostname -notlike $_.Hostname)
                            {
                            $count++
                            [datetime]$tratadoitemdate = $tratadoitem.Timestamp
                            [datetime]$item2date = $_.Timestamp
                                if ($tratadoitemdate -lt $item2date)
                                {
                                Write-Host "======================================================================================================================"
                                Write-Host "$tratadoitem é menor que $_"
                                Write-Host "#####$tratadoitem será APAGADO!"
                                $log = "================================================================================================================="
                                $log += "`r`n$(Get-Date) --- $tratadoitem é menor que $_"
                                $log += "`r`n$(Get-Date) --- $tratadoitem será APAGADO!"
		                        Remove-DnsServerResourceRecord -ComputerName hb-vw16dc02 -ZoneName $zonename -RRType "A" -Name $tratadoitem.Hostname -RecordData $tratadoitem.RecordData.IPAddressToString -Force
                                Add-Content -Path $pathlog -Value $log -Encoding UTF8
                                }elseif ($tratadoitemdate -gt $item2date)
                                        {
                                        Write-Host "======================================================================================================================"
                                        Write-Host "$tratadoitem é maior que $_"
                                        Write-Host "#####$_ será APAGADO!"
                                        $log = "================================================================================================================="
                                        $log += "`r`n$(Get-Date) --- $tratadoitem é maior que $_"
                                        $log += "`r`n$(Get-Date) --- $_ será APAGADO!"
                                        Remove-DnsServerResourceRecord -ComputerName hb-vw16dc02 -ZoneName $zonename -RRType "A" -Name $_.Hostname -RecordData $_.RecordData.IPAddressToString -Force
                                        Add-Content -Path $pathlog -Value $log -Encoding UTF8
                                        }else
                                            {
                                            Write-Host "======================================================================================================================"
                                            Write-Host "$tratadoitem é IGUAL ao $_"
                                            Write-Host "Nenhum dos dois registros será apagado pois tem Timestamp igual!"
                                            $log = "================================================================================================================="
                                            $log += "`r`n$(Get-Date) --- $tratadoitem é IGUAL ao $_"
                                            $log += "`r`n$(Get-Date) --- Nenhum dos dois registros será apagado pois tem Timestamp igual!"
                                            Add-Content -Path $pathlog -Value $log -Encoding UTF8
                                            }  
                            
                            }
                      }
        }
#=============================================================================================================================
#=============================================================================================================================


}

Clean-DNSRegisters-VPNSSL