# ================================================
# Automate your VM creation process in VirtualBox
# Created By : Mr. Sup3rN0va || 22-Oct-2020      
# -----------------------------------------------
# Usage :                                        
#                                                
# Import-Module Manage-VBox.ps1                 
# OR                                             
# . .\Manage-VBox.ps1                
# ===============================================

Function Manage-VBox
{
    <#
    .SYNOPSIS
        Create VM's in VirtualBox unattended

    .DESCRIPTION
        This powershell script will assist in unattended installation of VMs in virtualbox.

    .EXAMPLE
        _
        # Get Help
        PS C:\>Get-Help New-VBox -Detailed
        PS C:\>Get-Help Get-VBoxDetails -Detailed
        PS C:\>Get-Help Get-VBoxSettings -Detailed
    #>
}

Function New-VBox
{
    <#
    .SYNOPSIS
        Create new virtual machine in virtualbox.

    .DESCRIPTION
        Script to create virtual machines in virtual box without intervention.
        NOTE : Make sure you have installed Virtual Box at default installation location.

    .PARAMETER vm_name
        Name of the Virtual Machine (Mandatory)

    .PARAMETER ram
        Amount of RAM(GB) (Mandatory)

    .PARAMETER vproc
        Count of virtual CPU's to allocate (Mandatory)

    .PARAMETER hddsize
        Size of HardDisk in GB (Mandatory)

    .PARAMETER ostype
        Type of OS (Mandatory)
        Options : Debian_64, Ubuntu_64, Debian_32, Ubuntu_32

    .PARAMETER distrotype
        Type of Distro (Mandatory)
        Options : Desktop, Server, Mini

    .PARAMETER iso_image
        Path to OS ISO Image (Mandatory)

    .PARAMETER username
        Username to Login (Optional)
        Only needed if distrotype="Desktop"

    .PARAMETER password
        Password to Login (Optional)
        Only needed if distrotype="Desktop"

    .PARAMETER fullusername
        Display Username (Optional)
        Only needed if distrotype="Desktop"

    .EXAMPLE
        _
        # Creating Virtual Machine for Server/Mini ISO Image
        # Make sure you have preseeded ISO for this
        PS C:\> New-VBox -vm_name "TestBox" -ram 2 -vproc 1 -hddsize 10 -ostype Ubuntu_64 -distrotype Server
        -iso_image "AutoInstall-Ubuntu.iso"

        # Creating Virtual Machine for Destop based ISO Image
        PS C:\> New-VBox -vm_name "TestBox" -ram 2 -vproc 1 -hddsize 10 -ostype Ubuntu_64 -distrotype Desktop
        -iso_image "Ubuntu.iso" -username "<username>" -password "<password>" -fullusername "<FullUserName>"
    #>

    Param 
    (
        [Parameter(Mandatory=$True,
        HelpMessage="Name of the Virtual Machine (Mandatory)")]
        [String]
            $vm_name,
        [Parameter(Mandatory=$True,
        HelpMessage="Amount of RAM(GB) (Mandatory)")]
        [int]
            $ram,
        [Parameter(Mandatory=$True,
        HelpMessage="Count of virtual CPU's to allocate (Mandatory)")]
        [int]
            $vproc,
        [Parameter(Mandatory=$True,
        HelpMessage="Size of HardDisk in GB (Mandatory)")]
        [int]
            $hddsize,
        [Parameter(Mandatory=$True,
        HelpMessage="Type of Linux Flavor (Mandatory)")]
        [ValidateSet('Ubuntu_64', 'Debian_64')]
        [String]
            $ostype,
        [Parameter(Mandatory=$True,
        HelpMessage="Type of Distro (Mandatory)")]
        [ValidateSet('Desktop', 'Server', 'Mini')]
        [String]
            $distrotype,
        [Parameter(Mandatory=$True,
        HelpMessage="Path of OS ISO Image (Mandatory)")]
        [String]
            $iso_image,
        [Parameter(Mandatory=$False,
        HelpMessage="Login User Name (Optional)")]
        [String]
            $username,
        [Parameter(Mandatory=$False,
        HelpMessage="Login Password (Optional)")]
        [String]
            $password,
        [Parameter(Mandatory=$False,
        HelpMessage="Full User Name (Optional)")]
        [String]
            $fullusername
    )

    $guestiso_image = "C:\Program Files\Oracle\VirtualBox\VBoxGuestAdditions.iso"
    
    # Convert GB to MB
    $disksize = $hddsize * 1024
    $memory = $ram * 1024

    # Create New VM
    ."C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" --nologo createvm --name "$vm_name" --register

    # Add RAM and CPU to VM
    ."C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" --nologo modifyvm "$vm_name" --memory $memory --acpi on --boot1 dvd --cpus $vproc
    ."C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" --nologo modifyvm "$vm_name" --ostype "$ostype"
    ."C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" --nologo modifyvm "$vm_name" --graphicscontroller vmsvga --audio none --clipboard-mode bidirectional `
        --draganddrop bidirectional --vram 128

    # Add NIC's to VM
    ."C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" --nologo modifyvm "$vm_name" --nic1 nat --nictype1 82540EM --cableconnected1 on --nat-network1 NatNetwork

    # Create Storage
    $hddfile = "D:\VM\$vm_name\$vm_name.vdi"
    ."C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" --nologo createmedium disk --filename "$hddfile" --size $disksize --format VDI

    # Attach Storage - Need IDE to mount Unattended ISO which is preseeded ISO
    ."C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" --nologo storagectl "$vm_name" --name "IDE Controller" --add ide
    ."C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" --nologo storagectl "$vm_name" --add sata --controller IntelAHCI --name "SATA Controller"
    ."C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" --nologo storageattach "$vm_name" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium "$hddfile"
    ."C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" --nologo storageattach "$vm_name" --storagectl "IDE Controller" --port 0 --device 0 --type dvddrive --medium "$iso_image"

    Start-Sleep 3

    if ("$distrotype" -eq "Desktop")
    {
        # Final Set for Installation - Unattended
        ."C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" --nologo unattended install "$vm_name" --iso="$iso_image" --user="$username" --password="$password" `
            --full-user-name="$fullusername" --install-additions --additions-iso="$guestiso_image" --start-vm=gui --package-selection-adjustment="minimal"
        Start-Sleep 2
    }
    else 
    {
        # Create VM
        Write-Host
        Write-Host "============================================================================="
        Write-Host "ISO Image should be pre-seeded with 'preseed.cfg' for unattended installation"
        $answer = Read-Host "Please confirm that the ISO is pre-seeded, else installation needs intervention (Y/N): "

        if (($answer -eq "Y") -or ($answer -eq 'y'))
        {
            ."C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" --nologo startvm "$vm_name" --type gui
            Start-Sleep 3
            ."C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" --nologo controlvm "$vm_name" keyboardputscancode 1c
        }
        else 
        {
            Write-Host "Initiating Manual Installation"
            ."C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" --nologo startvm "$vm_name" --type gui
        }

        Write-Host
        Write-Host "============================================================================="
        Write-Host "Run Next : Get-VBoxSettings (Mandatory)"
        Write-Host "NOTE : Make sure to run this before getting shell everytime"
    }

}

Function Get-VBoxDetails
{
    <#
    .SYNOPSIS
        Get's the list of created VMs.
        Also, get details about individual VM in machine readable format.

    .EXAMPLE
        _
        # Get List of VMs
        PS C:\>Get-VBox

        # Get VM Info
        PS C:\>Get-VBoxDetails -showinfo "vm_name"
    #>

    $vm_name = $args[1]

    if ($args[0] -eq "-showinfo")
    {
        ."C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" --nologo showvminfo "$vm_name" --machinereadable
    }
    else
    {
        ."C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" --nologo list vms
    }
}

Function Get-VBoxSettings
{
    <#
    .SYNOPSIS
        Get settings of virtual machine

    .DESCRIPTION
        Get settings of virtual machine
        Basically defines Credentials and port to connect to

    .PARAMETER vm_name
        Name of the Virtual Machine (Mandatory)

    .EXAMPLE
        _
        # Get VBox Settings
        PS C:\>Get-VBoxSettings -vm_name "vm_name"
    #>

    Param 
    (
        [Parameter(Mandatory=$True,
        HelpMessage="Name of the Virtual Machine (Mandatory)")]
        [String]
            $vm_name
    )

    $port = Get-Random -Minimum 1024 -Maximum 65535

    Clear-Host
    
    $pf = ."C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" --nologo showvminfo "$vm_name" --machinereadable | findstr "Forwarding"

    if ($null -eq $pf)
    {
        ."C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" --nologo modifyvm "$vm_name" --boot1 disk
        ."C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" --nologo modifyvm "$vm_name" --natpf1 "GuestSSH, TCP,,$port,,22"
    }
    else
    {
        $port = ($pf -split ",")[-3]
    }

    Write-Host
    Write-Host "To connect, do SSH: "
    Write-Host "IP: 127.0.0.1"
    Write-Host "Port: $port"
    Write-Host "Username: vboxuser"
    Write-Host "Password: vboxuser"
}
