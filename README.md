<h2><b>Unattended OS Installation<b></h1>

> **Owner** : Mr. Sup3rN0va | 28-October-2020

> **Tags** : #virtualbox, #virtualization, #tool

---

<h2><b>Table Of Contents</b></h2>

- [**Introduction**](#introduction)
- [**Preseeding Debian ISO**](#preseeding-debian-iso)
  - [**Initrd Method**](#initrd-method)
  - [**Network Method**](#network-method)
  - [**File Method**](#file-method)
- [**Generating Final ISO**](#generating-final-iso)
- [**REFERENCES**](#references)


---

## **Introduction**

---

- There are times when you want to install OS in virtualbox and wanted to skip questions from the installer (unattended installation)
- This script assists you in achieving that task
- Two Scripts:
  - **VBoxManager for Windows**
  - **VBoxManager for Linux** (Under Contruction 🔨😜)
- **VBoxManager for Windows**
  - This will install **"Ubuntu"** and **"Debian"** flavours
  - If the **"ISO"**, is a **"Desktop"** version, then virtual box has inbuild mechanism to do unattended installation which is covered in this script
  - If you have a **"Server"** or **"Mini"** **"ISO"**, then it's better to **"preseed"** the iso and then install the OS
  - Usage

    ```ps
    Import-Module Manage-VBox.ps1

    # OR

    . .\Manage-VBox.ps1

    # Get Help
    PS C:\> Get-Help Manage-VBox -Detailed
    PS C:\> Get-Help Manage-VBox -Examples
    ```

- **VBoxManager for Linux** (Under Contruction 🔨😜)
  - Will update this soon

---

## **Preseeding Debian ISO**

---

- There are three methods to do **"preseeding"** for debian based flavours
- Best to do preseeding by mounting the **"ISO"** in linux distro

---

### **Initrd Method**

---

- Steps **"(Tested for mini.iso)"**
  - Create two directories : **'isofiles'** and **'customiso'**
  - Mount the iso as `sudo mount -o loop mini.iso isofiles`
  - Copy all the contents as `sudo cp -rT isofiles/ customiso/`
  - Get inside **"customiso"** folder as `cd customiso/`

    ```sh
    sudo chmod +w -R initrd.gz
    gunzip initrd.gz
    echo preseed.cfg | cpio -H newc -o -A -F initrd
    gzip initrd
    sudo chmod -w -R initrd.gz
    ```

  - By this point we can create the iso and it will work but let's make the boot menu more clean
  - Editing **grub.cfg** file as `sudo nano boot/grub/grub.cfg`
  - Delete from last line till the first menu entry
  - Final config will be like :

    ```grub.cfg
    if loadfont /boot/grub/font.pf2 ; then
        set gfxmode=auto
        insmod efi_gop
        insmod efi_uga
        insmod gfxterm
        terminal_output gfxterm
    fi

    set menu_color_normal=white/black
    set menu_color_highlight=black/light-gray

    set timeout=0
    set default=0

    menuentry "AutoInstall" {
        set gfxpayload=keep
        linux   /linux auto=true priority=critical locale=en_US quiet splash noprompt noshell ---
        initrd  /initrd.gz
    }
    ```

  - Editing **"txt.cfg"** as `sudo nano txt.cfg`
  - Delete all entry except the first label
  - Final config will be like :

    ```txt.cfg
    default auto-install
    label auto-install
            menu label ^AutoInstall
            kernel linux
            append vga=788 initrd=initrd.gz auto=true priority=critical quiet splash noprompt noshell ---
    ```

  - **"REF"** : [**Modify Installation ISO for Preseeding**](https://wiki.debian.org/DebianInstaller/Preseed/EditIso)

---

### **Network Method**

---

- For ubuntu, once the boot-menu opens we need to hit **"tab"** to **"Install"** and edit the text in background
- Once you hit enter, it will read preseed file and configure the device

    ```txt
        # grub boot-menu for Ubuntu - Hit tab and edit
        Boot Options ksdevice=ens3 locale=en_US.UTF-8 keyboard-configuration/layout=us hostname=myb0x interface=ens3 url=tftp://IP/preseed.cfg quiet ---
    ```

- Hardcoding this inside the iso

    ```txt
    # grub.cfg

    if loadfont /boot/grub/font.pf2 ; then
    set gfxmode=auto
    insmod efi_gop
    insmod efi_uga
    insmod gfxterm
    terminal_output gfxterm
    fi

    set menu_color_normal=white/black
    set menu_color_highlight=black/light-gray

    set timeout=0

    menuentry "AutoInstall" {
            set gfxpayload=keep
            linux   /linux ksdevice=ens3 locale=en_US.UTF-8 keyboard-configuration/layout=us hostname=myb0x interface=ens3 url=tftp://IP/preseed.cfg auto=true priority=critical quiet splash noprompt noshell ---
            initrd  /initrd.gz
    }
    ```

- Also the **"txt.cfg"** file

  ```txt
  # txt.cfg
  
  default auto-install
  label auto-install
          menu label ^AutoInstall
          kernel linux
          append vga=788 ksdevice=ens3 locale=en_US.UTF-8 keyboard-configuration/layout=us hostname=myb0x interface=ens3 url=tftp://IP/preseed.cfg initrd=initrd.gz auto=true priority=critical quiet splash noprompt noshell ---
  ```

- For Windows, you can use "MobaXterm" to start "TFTP" server and then it will fetch the **"preseed.cfg"** file and do auto-install
- For linux, it comes preloaded with **"python-3"**. So, you can use that to initiate a web service inside the folder where we have the **"preseed.cfg"** file

---

### **File Method**

---

- Copy **"preseed.cfg"** file inside the **"customiso"** folder
- Provide the path in **"grub.cfg"** and **"txt.cfg"**
- Editing **grub.cfg** file as `sudo nano boot/grub/grub.cfg`

    ```txt
    # grub.cfg
    # This is for File-based method

    set timeout=0

    menuentry "AutoInstall"
    {
        set gfxpayload=keep
        linux   /linux  file=/cdrom/preseed.cfg auto=true priority=critical locale=en_US quiet splash noprompt noshell ---
        initrd  /initrd.gz
    }
    ```

- Editing **txt.cfg** file as `sudo nano txt.cfg` or `sudo nano isolinux/txt.cfg`

    ```txt
    # txt.cfg
    # This is for File-based method

    default auto-install

    label auto-install
        menu label ^AutoInstall
        menu default
        kernel linux
        append auto=true file=/cdrom/preseed/preseed.cfg priority=critical quiet splash noprompt noshell automatic-ubiquity debian-installer/locale=en_US keyboard-configuration/layoutcode=us languagechooser/language-name=English localechooser/supported-locales=en_US.UTF-8 countrychooser/shortlist=US ---
    ```

- Here `file=/cdrom/` will always come for **"file method"** because the **"preseed.cfg"** file is added inside iso and the system reads the iso file from cdrom. So we are actually defining the path of **"preseed.cfg"** file inside iso
- If we add the preseed.cfg file in the root folder, then above line is ok else, we need to provide the folder name as `file=/cdrom/preseed/preseed.cfg`

---

## **Generating Final ISO**

---

- To generate final ISO image with auto-installer

    ```sh
    sudo genisoimage -r -J -b isolinux.bin -c boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -o AutoInstall_Ubuntu.iso customiso/
    ```

- This iso image **"AutoInstall_Ubuntu.iso"** will be used in the script to **"server/mini"** unattended installation

---

## **REFERENCES**

---

> [**Debian - Preseed File Example**](https://www.debian.org/releases/stretch/example-preseed.txt)

> [**Debian - Installation Guide**](https://www.debian.org/releases/stretch/amd64/apb.html.en)

> [**Debian - Step-By-Step Preseeded Installation with Cubic**](https://www.pugetsystems.com/labs/hpc/Note-Auto-Install-Ubuntu-with-Custom-Preseed-ISO-1654/)

---
