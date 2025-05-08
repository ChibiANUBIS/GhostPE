Software :

Ghost : https://pastebin.com/raw/rN7HUwft

ADK : http://software-download.microsoft.com/download/pr/19041.1.191206-1406.vb_release_amd64fre_ADK.iso

Preinstallation Environment : http://software-download.microsoft.com/download/pr/19041.1.191206-1406.vb_release_amd64fre_adkwinpeaddons.iso

Command :

Go to Start>Microsoft Windows ADK and right click Run as administrator the ADK Tools Command Prompt.

If prompted by UAC, click Yes.

In the command prompt window that pops up, type in the following: copype x86 C:\GhostPE

After the scrolling lines stop, type cls and hit enter to clear the screen.

Next, enter the following command: imagex /mountrw C:\GhostPE\winpe.wim 1 C:\GhostPE\mount. This will mount the WIM image so we can edit it.

Navigate in explorer to C:\GhostPE\mount\Windows\ and paste the Ghost32.exe file and/or any other files possible needed for a custom boot disc

Next, the startnet.cmd file must be edited for startup programs to start automatically. In a text editor, open the file C:\GhostPE\mount\Windows\System32\startnet.cmd.

It is crucial that wpeinit is the first line in this file or drivers may not load properly. At the second line, type in the name of the program that needs to be started (e.g. ghost32). Save and exit.

After all changes are complete, go back to the command prompt and enter the command: peimg /prep C:\GhostPE\mount\Windows & imagex /unmount C:\GhostPE\mount /commit & copy C:\GhostPE\winpe.wim C:\GhostPE\ISO\sources\boot.wim. You will be asked to type in the word yes. After doing so, the new image will be compressed, have changes applied, committed to the WIM file, and added the ISO source. This may take some time

Finally, to create a bootable ISO, enter the command: oscdimg –n –bC:\GhostPE\etfsboot.com C:\GhostPE\ISO “%UserProfile%\Desktop\GhostBootDisc.iso”. This may take a few minutes.


About the script :

This script can be use only for create a WinPE French interface and keyboard.
