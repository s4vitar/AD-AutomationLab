<#
.SYNOPSIS
    AD-AutomationLab: PowerShell script for automated deployment of a vulnerable AD environment.
.DESCRIPTION
    This script automates the deployment of a vulnerable Active Directory (AD) environment for educational and testing purposes.
    It configures various attacks such as Kerberoasting, ASRepRoast, SMB Relay, and abuse of dnsAdmins.
    The script guides the user through the necessary steps, including domain services installation, user creation, and attack configuration.
    It is designed to be used on Windows Server 2016.
.NOTES
    Author: Marcelo Vazquez (aka S4vitar)
    GitHub Repository: https://github.com/s4vitar/AD-AutomationLab
    YouTube Channel: https://www.youtube.com/c/MarceloVazquez
    Video Tutorials: https://www.youtube.com/playlist?list=PLID1WJKc9CH5OuYxKAaQaEiOJ_2RbyFAT
#>

# Banner
function Show-Banner {
    $banner = @(
        '*******                          **     *******',
        '/**////**                        ****   /**////**',
        '/**   /** ***     ** *******    **//**  /**    /**',
        '/******* //**  * /**//**///**  **  //** /**    /**     [By Marcelo Vazquez (aka S4vitar)]',
        '/**////   /** ***/** /**  /** **********/**    /**',
        '/**       /****/**** /**  /**/**//////**/**    **',
        '/**       ***/ ///** ***  /**/**     /**/*******',
        '//       ///    /// ///   // //      // ///////'
    )

    $banner | ForEach-Object {
        Write-Host $_ -ForegroundColor (Get-Random -Input @('Green','Cyan','Yellow','gray','white'))
    }

    Start-Sleep -Seconds 3
    Clear-Host
}

# Global Variables
$Global:ADUsers = @('mvazquez', 'vgarcia', 'SVC_SQLService')
$Global:ADPasswords = @('Password1', 'Password2', 'MYpassword123#')
$Global:ADUserNames = @('Marcelo Vazquez', 'Victor Garcia', 'SQL Service')

# Help Panel
function Show-HelpPanel {
    Write-Output ''
    Write-Host "1. After importing the module, run the 'domainServicesInstallation' command." -ForegroundColor "yellow"
    Write-Output ''
    Write-Output "2. After the first reboot, run the 'domainServicesInstallation' command again." -ForegroundColor "yellow"
    Write-Output ''
    Write-Host "3. Once the machine is configured as a DC, run the 'createUsers' command." -ForegroundColor "yellow"
    Write-Output ''
    Write-Host "4. Depending on the type of attack you want to deploy, run one of the following commands:" -ForegroundColor "yellow"
    Write-Output ''
    Write-Host "    - createKerberoast" -Foreground "yellow"
    Write-Host "    - createASRepRoast" -Foreground "yellow"
    Write-Host "    - createSMBRelay" -Foreground "yellow"
    Write-Host "    - createDNSAdmins" -Foreground "yellow"
    Write-Host "    - createAll" -Foreground "yellow"
    Write-Output ''
}

# Domain Services Installation
function Install-DomainServices {
    Show-Banner
    Write-Output ''
    Write-Host "[*] Installing domain services and configuring the domain" -ForegroundColor "yellow"
    Write-Output ''

    Add-WindowsFeature RSAT-ADDS
    Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

    Import-Module ServerManager
    Import-Module ADDSDeployment

    $domainName = "s4vicorp.local"

    Write-Output ''
    Write-Host "[*] Uninstalling Windows Defender" -ForegroundColor "yellow"
    Write-Output ''

    try {
        $defenderOptions = Get-MpComputerStatus

        if ($defenderOptions) {
            Write-host "Windows Defender is active on the server:" $env:computername -foregroundcolor "Cyan"
            Write-Output ''
            Write-host '    Is Windows Defender enabled?' $defenderOptions.AntivirusEnabled
            Write-host '    Is Windows Defender service enabled?' $defenderOptions.AMServiceEnabled
            Write-host '    Is Windows Defender Antispyware enabled?' $defenderOptions.AntispywareEnabled
            Write-host '    Is Windows Defender OnAccessProtection enabled?' $defenderOptions.OnAccessProtectionEnabled
            Write-host '    Is Windows Defender RealTimeProtection enabled?' $defenderOptions.RealTimeProtectionEnabled

            Write-Output ''
            Write-Host "[*] Changing the computer name to DC-Company" -ForegroundColor "yellow"
            Write-Output ''

            Rename-Computer -NewName "DC-Company"

            Write-Output ''
            Write-Host "[V] Computer name changed successfully" -ForegroundColor "green"
            Write-Output ''

            Write-Host "[!] After finishing, a system restart may be necessary for the changes to take effect" -ForegroundColor "red"

            Write-Output ''
            Write-Host "[*] Uninstalling Windows-Defender..." -ForegroundColor "yellow"

            Uninstall-WindowsFeature -Name Windows-Defender

            Write-Output ''
            Write-Host "[V] Windows Defender has been uninstalled. Restarting the system" -ForegroundColor "green"
            Write-Output ''

            Start-Sleep -Seconds 5

            Restart-Computer

            Start-Sleep -Seconds 10 # Margin of time for the system to restart and prevent the script from continuing to the next steps
        }
        else {
            Write-host "Windows Defender is not running on the server:" $env:computername -foregroundcolor "Green"
        }
    }
    catch {
        Write-host "Windows Defender is uninstalled on the server:" $env:computername -foregroundcolor "Green"
    }

    Write-Output ''
    Write-Host "[*] Please provide the password for the domain Administrator user" -ForegroundColor "yellow"
    Write-Output ''

    try {
        Install-ADDSForest -CreateDnsDelegation:$false -DatabasePath "C:\\Windows\\NTDS" -DomainMode "7" -DomainName $domainName -DomainNetbiosName "s4vicorp" -ForestMode "7" -InstallDns:$true -LogPath "C:\\Windows\\NTDS" -NoRebootOnCompletion:$false -SysvolPath "C:\\Windows\\SYSVOL" -Force:$true
    }
    catch {
        Restart-Computer
    }

    Write-Output ''
    Write-Host "[!] The system will restart. Log in as the domain Administrator user after the restart" -ForegroundColor "red"
    Write-Output ''
}

# Create Users in AD
function Create-ADUsers {
    $counter = 0

    Foreach ($user in $ADUsers) {
        Write-Output ''
        Write-Host "[*] Creating user $user" -ForegroundColor "gray"
        Write-Output ''

        $givenName = $ADUserNames[$counter] | ForEach-Object { $_.Split(' ')[0]; }
        $surName = $ADUserNames[$counter] | ForEach-Object { $_.Split(' ')[1]; }
        $username = $ADUsers[$counter]
        $userPassword = $ADPasswords[$counter]
        $secpasswd = ConvertTo-SecureString -String $userPassword -AsPlainText -Force

        Try {
            New-ADUser -Name $ADUsers[$counter] -GivenName $givenName -Surname $surName -SamAccountName $ADUsers[$counter] -AccountPassword $secpasswd -ChangePasswordAtLogon $False -DisplayName $ADUserNames[$counter] -Enabled $True
        }
        Catch {}

        $counter += 1
    }

    Write-Output ''
    Write-Host "[V] All users have been created" -ForegroundColor "green"
    Write-Output ''
}

# Configure Kerberoast Attack
function Configure-Kerberoast {
    Write-Output ''
    Write-Host "[*] Configuring Kerberoast attack" -ForegroundColor "yellow"
    Write-Output ''

    net localgroup Administradores s4vicorp\SVC_SQLService /add
    setspn -s http/s4vicorp.local:80 SVC_SQLService

    Write-Output ''
    Write-Host "[V] Lab configured for deploying Kerberoast attack" -ForegroundColor "green"
    Write-Output ''
}

# Configure ASRepRoast Attack
function Configure-ASRepRoast {
    Write-Output ''
    Write-Host "[*] Configuring ASRepRoast attack" -ForegroundColor "yellow"
    Write-Output ''

    # To alter any other attribute if needed: Get-ADUser -Identity SVC_SQLService -Properties *
    Set-ADAccountControl SVC_SQLService -DoesNotRequirePreAuth $True

    Write-Output ''
    Write-Host "[V] Lab configured for deploying ASRepRoast attack" -ForegroundColor "green"
    Write-Output ''
}

# Configure SMB Relay Attack
function Configure-SMBRelay {
    Write-Output ''
    Write-Host "[*] Configuring environment for SMB Relay attack" -ForegroundColor "yellow"
    Write-Output ''

    Set-SmbClientConfiguration -RequireSecuritySignature 0 -EnableSecuritySignature 0 -Confirm -Force

    Write-Output ''
    Write-Host "[V] Lab configured for deploying SMB Relay attack" -ForegroundColor "green"
    Write-Output ''
}

# Configure DNSAdmins Attack
function Configure-DNSAdmins {
    Write-Output ''
    Write-Host "[*] Configuring environment for DNSAdmins attack" -ForegroundColor "yellow"
    Write-Output ''

    net localgroup "DnsAdmins" mvazquez /add

    Write-Output ''
    Write-Host "[V] Lab configured for deploying DNSAdmins attack" -ForegroundColor "green"
    Write-Output ''
}

# Configure All Attacks
function Configure-AllAttacks {
    Configure-Kerberoast
    Configure-ASRepRoast
    Configure-SMBRelay
    Configure-DNSAdmins
}

