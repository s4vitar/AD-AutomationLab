
# Banner
function banner {
	$banner = @()
	$banner += ''
	$banner += '*******                          **     *******'
	$banner += '/**////**                        ****   /**////**'
	$banner += '/**   /** ***     ** *******    **//**  /**    /**'
	$banner += '/******* //**  * /**//**///**  **  //** /**    /**     [By Marcelo Vazquez (aka S4vitar)]'
	$banner += '/**////   /** ***/** /**  /** **********/**    /**'
	$banner += '/**       /****/**** /**  /**/**//////**/**    **'
	$banner += '/**       ***/ ///** ***  /**/**     /**/*******'
	$banner += '//       ///    /// ///   // //      // ///////'
	$banner += ''
	$banner | foreach-object {
		Write-Host $_ -ForegroundColor (Get-Random -Input @('Green','Cyan','Yellow','gray','white'))
	}

	Start-Sleep -Seconds 3
	Clear-Host
}

# Declaracion de variables
$Global:ADUsers = @('mvazquez', 'vgarcia', 'SVC_SQLService')
$Global:ADPasswords = @('Password1', 'Password2', 'MYpassword123#')
$Global:ADUserNames = @('Marcelo Vazquez', 'Victor Garcia', 'SQL Service')

# Panel de ayuda
function helpPanel {
	Write-Output ''
	Write-Host "1. Una vez importado el modulo, ejecuta el comando domainServicesInstallation" -ForegroundColor "yellow"
	Write-Output ''
}

# Instalacion de los servicios de dominio y configuracion del dominio
function domainServicesInstallation {

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
    Write-Host "[*] Es probable que tras finalizar, sea necesario reiniciar el equipo para que los cambios tengan efecto." -ForegroundColor "red"
    Write-Output ''

    Install-ADDSForest -CreateDnsDelegation:$false -DatabasePath "C:\\Windows\\NTDS" -DomainMode "7" -DomainName $domainName -DomainNetbiosName "s4vicorp" -ForestMode "7" -InstallDns:$true -LogPath "C:\\Windows\\NTDS" -NoRebootOnCompletion:$false -SysvolPath "C:\\Windows\\SYSVOL" -Force:$true
}

# Creacion de usuarios a nivel de dominio
function createUsers {

	$counter = 0

	Foreach ($user in $ADUsers) {
		Write-Output ''
		Write-Host "[*] Creando usuario $user" -ForegroundColor "gray"
		Write-Output ''

		$givenName = $ADUserNames[$counter] | %{ $_.Split(' ')[0]; }
		$surName = $ADUserNames[$counter] | %{ $_.Split(' ')[1]; }
		$username = $ADUsers[$counter]
		$userPassword = $ADPasswords[$counter]
		$secpasswd = ConvertTo-SecureString -String $userPassword -AsPlainText -Force

		Try { New-ADUser -Name $ADUsers[$counter] -GivenName $givenName -Surname $surName -SamAccountName $ADUsers[$counter] -AccountPassword $secpasswd -ChangePasswordAtLogon $False -DisplayName $ADUserNames[$counter] -Enabled $True } Catch {}

		$counter += 1
	}

	Write-Output ''
	Write-Host "[V] Todos los usuarios han sido creados" -ForegroundColor "green"
	Write-Output ''
}
