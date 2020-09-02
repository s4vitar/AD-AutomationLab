
# Banner
function banner {
	$banner = @()
	$banner+= $Global:Spacing + ''
	$banner+= $Global:Spacing + '*******                          **     *******'
	$banner+= $Global:Spacing + '/**////**                        ****   /**////**'
	$banner+= $Global:Spacing + '/**   /** ***     ** *******    **//**  /**    /**'
	$banner+= $Global:Spacing + '/******* //**  * /**//**///**  **  //** /**    /**     [By Marcelo Vazquez (aka S4vitar)]'
	$banner+= $Global:Spacing + '/**////   /** ***/** /**  /** **********/**    /**'
	$banner+= $Global:Spacing + '/**       /****/**** /**  /**/**//////**/**    **'
	$banner+= $Global:Spacing + '/**       ***/ ///** ***  /**/**     /**/*******'
	$banner+= $Global:Spacing + '//       ///    /// ///   // //      // ///////'
	$banner+= $Global:Spacing + ''
	$banner | foreach-object {
		Write-Host $_ -ForegroundColor (Get-Random -Input @('Green','Cyan','Yellow','gray','white'))
	}

	Start-Sleep -Seconds 3
	Clear-Host
}

# Panel de ayuda
function helpPanel {
	Write-Output ''
	Write-Host "1. Una vez importado el modulo, ejecuta el comando domainServicesInstallation" -ForegroundColor "yellow"
	Write-Output ''
}

# Instalacion de los servicios de dominio y configuracion del dominio
function domainServicesInstallation(){

	banner

	Write-Output ''
	Write-Host "[*] Instalando los servicios de dominio y configurando el dominio" -ForegroundColor "yellow"
	Write-Output ''

	Add-WindowsFeature RSAT-ADDS
	Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

	Import-Module ServerManager
	Import-Module ADDSDeployment

	$domainName = "s4vicorp.local"

	Write-Output ''
	Install-ADDSForest -CreateDnsDelegation:$false -DatabasePath "C:\\Windows\\NTDS" -DomainMode "7" -DomainName $domainName -DomainNetbiosName "s4vicorp" -ForestMode "7" -InstallDns:$true -LogPath "C:\\Windows\\NTDS" -NoRebootOnCompletion:$false -SysvolPath "C:\\Windows\\SYSVOL" -Force:$true

	Write-Output ''
	Write-Host "[V] Finalizado, se va a reiniciar el equipo para que los cambios surgan efecto" -ForegroundColor "green"
	Write-Output ''
}
