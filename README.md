# Auto Seedbox

Scripts to watch MacOS `~/Downloads` folder for `.torrent` files, upload them
to a seedbox, and download the resulting files.

Also has ability to automatically SCP `.epub` files to an online kindle running KOReader.

This repo is titled `homebrew-` because I may try and get this installable
by brew.

## Why?

1. To be a good citizen, and seed your torrents
1. To remove the hassle of having to keep your laptop cracked open to do so
1. To prevent snooping on your torrent downloads by your ISP
1. To make downloading torrents as easy as any other file
1. For books, to reduce the activation energy to reading as much as possible

## How?

TODO explanation

This is... not ideal. There are better ways to accomplish the same, but this is
good enough for now. It is hacky as hell, and will almost certainly not work
out of the box for you; however, I've written as thorough a guide as possible so
that the enterprising reader can fix it up for themselves.

## Requirements

For auto-downloading torrents:

- Admin access on local macOS machine

- Seedbox with SFTP access

  - Must be able to put SSH key on machine (This is doable with only `sftp` and
    no SSH access.)

  - Must be running qBittorrent (Probably can make it work otherwise, but this
    is what I chose.)

- bash (Unknown if homebrew bash required. TODO figure that out)

- rclone, jq, libtorrent, python3.11, fswatch (`brew install rclone jq
  libtorrent-rasterbar python@3.11 fswatch`)

For copying to kindle:

- All of the above
- nmap, ripgrep (`brew install ripgrep nmap python@3.11`)

## Setup

This requires some manual configuration to work.

1. Confirm SFTP access to seedbox, with username/password
   - `sftp -P <PORT> <USERNAME>@<HOSTNAME>`, and enter password

1. Set up public key authentication

   1. Generate SSH key: `ssh-keygen -t ed25519 -f ~/.ssh/id_seedbox`
      - Use a password manager to generate a secure passphrase. Save it.

   1. Add key to SSH agent `ssh-add --apple-use-keychain ~/.ssh/id_seedbox`

      - This MAY fail. If so, either `brew unlink openssh` or call
        `/usr/bin/ssh-add` instead. Homebrew's SSH doesn't work with the macOS
        keychain, which we need if we want to password-protect the key and be
        able to automate this.

   1. Write to your `~/.ssh/config`, filling in the values:

      ```config
       Host seedbox
           HostName <HOSTNAME>
           User <USERNAME>
           Port <PORT>
           IdentityFile ~/.ssh/id_seedbox
       ```

   1. Add the public key to your seedbox. See [here][add-key-server] for
      instructions.
      - If you don't have SSH access, this can still be done over SFTP. It will
        look something like this:

        ```shell
        $ cd ~/
        $ sftp -P <PORT> <USERNAME>@<HOSTNAME>
        # This may be unnecessary if the directory already exists
        sftp> pwd
        Remote working directory: /home/<USERNAME>
        # If the above is not the home directory, cd into it.
        sftp> mkdir .ssh
        sftp> put .ssh/id_seedbox.pub .ssh/authorized_keys
        sftp> chmod 700 .ssh
        sftp> chmod 600 .ssh/authorized_keys
        ```

   1. Restart the seedbox.

   1. Run `sftp seedbox`. This should sign you in without needing a password.
     - If this fails, try `ssh-add --apple-load-keychain`
     - Confirm you restarted the seedbox

1. Set up qBittorrent
   1. Make watch directories:

   ```shell
   $ sftp seedbox
   sftp> pwd
   Remote working directory: /home/<USERNAME>
   sftp> mkdir twatch
   sftp> mkdir twatch_out
   sftp> mkdir completed_torrents
   ```

   1. Sign in to the web UI for qBittorrent

   1. Go to Tools > Options

   1. Check "Copy .torrent files for finished downloads to:" and set the value
      to `/home/<USERNAME>/completed_torrents`

   1. Under "Automatically add torrents from:" add a line with "Monitored
      Folder" being `/home/<USERNAME>/twatch` and "Override Save Location" being
      `/home/<USERNAME>/twatch_out/`

   1. Scroll to the bottom and click "save"

   1. Test this by `sftp`ing into the server, and copying a .torrent file to
      `/home/<USERNAME>/twatch`. Wait for it to complete by watching the web UI,
      and then check that there is a `.torrent` file for the download in
      `/home/<USERNAME>/completed_torrents`, and the actual files are in
      `/home/<USERNAME>/twatch_out`.

1. Set up `~/.config/rclone/rclone.conf`. It should look something like this:

   ```config
   [seedbox]
   type = sftp
   host = <HOSTNAME>
   user = <USERNAME>
   port = <PORT>
   shell_type = unix
   md5sum_command = none
   sha1sum_command = none
   ```

   - Test configuration with `rclone lsjson
     seedbox:/home/<USERNAME>/twatch_out/`. This should print JSON for the file
     you tested the downloading with. It should NOT need a password.

   - If this fails, you can try messing around with the interactive config
     wizard at `rclone config`

1. Test watching and downloading scripts

   1. If you haven't already, clone this repo: `git clone
      https://github.com/riley-martine/homebrew-auto-seedbox` and `cd
      homebrew-auto-seedbox`

   1. Run `./auto_download/torrent_daemon.sh`
      - This should print `Identity added: /Users/<LOCAL
        USERNAME>/.ssh/id_seedbox` and then wait.

   1. Move a torrent file to `~/Downloads`. You can [download one][kybalion].
      Watch the logs for the program; it should print what it's doing, upload to
      the seedbox, and download the file(s) to `~/Downloads`

1. Set up Launch Agent, so this runs automatically.

   1. `cp auto_download/uploadtorrents.plist ~/Library/LaunchAgents`

   1. Open System Settings, go to "Login Items", and enable `torrent_daemon.sh`

   1. Open System Settings, go to "Privacy and Security", then to "Full Disk
      Access". Click the `+`. In the selection window, press Cmd-Shift-G, and
      type in `/bin/`. Click on `bash`, and select it with `open`

   1. You MAY need to run `launchctl start uploadtorrents` or similar.

   <!-- TODO switch log loc -->
   1. To test this is working, `tail -f ~/Library/Logs/torrent_daemon.log`. You
      should see output that is the same as when you ran the scripts manually.
      Add a [torrent file][abramelin] to `~/Downloads`, and watch the logs as it
      downloads.

At this point, you're probably done! Congratulations! However, if you're also
trying to get your ebooks onto a Kindle, read on...

Note: This probably works with non-kindle KOReader, but I haven't tried it.

1. [Jailbreak][jailbreak] your kindle. Follow ALL instructions in the thread
   carefully. Do not connect to the internet. This may take a while, but do it
   right.

1. Install KUAL, gawk, KUAL+, KUAL Helper. See linked snapshots thread.

1. Install [KOReader][koreader-install]

1. Disable OTA updates through KUAL

1. If running FW >= 5.12.x, you MUST also disable OTA updates with method
   described [here][ota]. You can do this through KOReader's shell in `Top Menu
   > Tools Icon > More Tools > Terminal emulator > Open terminal session`. Here
   is what I ran (the hosts stuff is a bit extra, but sue me I guess, I was
   working on this too long to get got by an update):

   ```shell
   # mntroot rw
   # cd /usr/bin
   # mv otaupd otaupd.bck
   # mv otav3 otav3.bck
   # echo "/bin/true" > /usr/bin/otav3
   # echo "/bin/true" > /usr/bin/otaupd
   # chmod +x /usr/bin/otav3 /usr/bin/otaupd
   # echo "127.0.0.1 firs-ta.g7g.amazon.com" >> /etc/hosts
   # echo "127.0.0.1 amazon.com" >> /etc/hosts
   # touch /var/local/system/DONT_DELETE_CONTENT_ON_DEREGISTRATION
   # exit
   ```

   And then reboot the device.

1. Connect the device to WiFi. Pray you got everything right.

1. Launch KOReader. Go to `Top Menu > Gear Icon > SSH server`. Set the field
   "SSH port" to 2323. Enable "Login without password (DANGEROUS)". I was unable
   to make public key auth work, but I'll only be connecting to home WiFi, so I
   think it's _probably_ fine. Check the box for "SSH server." This will tell
   you the IP address of the device.

1. Test ssh access with `ssh -p 2323 root@<IP>` and just hit enter for the
   password. You should be logged in to the Kindle.

1. You may need to change the download path in `auto_kindle/copy_to_kindle.sh`,
   on the line where it runs `scp`. This should be KOReader's home folder, where
   you want the books to go. Add a file to your kindle in the directory you want
   (I used `/mnt/us/documents` because that's where Calibre was putting things)
   and run `# ls /../../../mnt/us/documents/` to confirm you see your file; if
   not, correct the path and edit it in `copy_to_kindle.sh`.

1. Test `./copy_to_kindle.sh ~/Downloads/example.epub`. It may be slow the first
   time as it finds the Kindle. This should copy a file to the kindle.

<!-- TODO add config for whether to look for kindle or not -->
1. Test the whole thing together. Find a [torrent][fruit] that has an epub in
   it, download it, and watch the logs (`tail -f
   ~/Library/Logs/torrent_daemon.log`). If your kindle is online, everything
   should work.

### Troubleshooting

Updates to the base script (`torrent_daemon.sh`) do not get picked up by the
Launch Agent. The easiest way I've found to deal with this is toggling it off
and on again in System Settings > Login Items. There's probably a `launchctl`
command to do this also, though.

[add-key-server]: https://linuxhandbook.com/add-ssh-public-key-to-server/
[kybalion]: https://archive.org/download/kybalionstudyofh00thre/kybalionstudyofh00thre_archive.torrent
[abramelin]: https://archive.org/download/bookofsacredmagi00abra/bookofsacredmagi00abra_archive.torrent
[jailbreak]: https://www.mobileread.com/forums/showthread.php?t=320564
[ota]: https://www.mobileread.com/forums/showthread.php?t=327879&highlight=touch&page=2
[koreader-install]: https://github.com/koreader/koreader/wiki/Installation-on-Kindle-devices
[fruit]: https://archive.org/download/forbiddenfruitlu28520gut/forbiddenfruitlu28520gut_archive.torrent
