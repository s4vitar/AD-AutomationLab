
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
	Write-Host "2. Una vez el equipo quede configurado como DC, ejecuta el comando createUsers" -ForegroundColor "yellow"
	Write-Output ''
	Write-Host "3. En funcion del tipo de ataque que quieras desplegar, ejecuta cualquiera de los siguientes comandos:" -ForegroundColor "yellow"
	Write-Output ''
	Write-Host "	- createKerberoast" -Foreground "yellow"
	Write-Host "	- createASRepRoast" -Foreground "yellow"
	Write-Host "	- createSMBRelay" -Foreground "yellow"
	Write-Host "    - createDNSAdmins" -Foreground "yellow"
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

# Configuracion para el despliegue del Kerberoasting Attack
function createKerberoast {

	Write-Output ''
    Write-Host "[*] Configurando ataque Kerberoasting" -ForegroundColor "yellow"
    Write-Output ''

    net localgroup Administradores s4vicorp\SVC_SQLService /add
    setspn -s http/s4vicorp.local:80 SVC_SQLService

    Write-Output ''
    Write-Host "[V] Laboratorio configurado para desplegar ataque Kerberoast" -ForegroundColor "green"
    Write-Output ''
}

# Configuracion para el despliegue del ASREPRoast Attack
function createASRepRoast {

	Write-Output ''
    Write-Host "[*] Configurando ataque ASREPRoast" -ForegroundColor "yellow"
    Write-Output ''

    # En caso de querer alterar algun otro atributo: Get-ADUser -Identity SVC_SQLService -Properties *
    Set-ADAccountControl SVC_SQLService -DoesNotRequirePreAuth $True

    Write-Output ''
    Write-Host "[V] Laboratorio configurado para desplegar ataque ASREPRoast" -ForegroundColor "green"
    Write-Output ''
}

# Configuracion para el despliegue del SMB Relay
function createSMBRelay {

    Write-Output ''
    Write-Host "[*] Configurando entorno para hacer posible el SMB Relay" -ForegroundColor "yellow"
    Write-Output ''

	Set-SmbClientConfiguration -RequireSecuritySignature 0 -EnableSecuritySignature 0 -Confirm -Force

    Write-Output ''
    Write-Host "[V] Laboratorio configurado para desplegar ataque SMB Relay" -ForegroundColor "green"
    Write-Output ''
}

# Configuracion para el despliegue del ataque contra dnsAdmins
function createDNSAdmins {

    Write-Output ''
    Write-Host "[*] Configurando entorno para hacer posible el ataque contra dnsAdmins" -ForegroundColor "yellow"
    Write-Output ''

	net localgroup "DnsAdmins" mvazquez /add

    Write-Output ''
    Write-Host "[V] Laboratorio configurado para desplegar ataque contra dnsAdmins" -ForegroundColor "green"
    Write-Output ''
}
