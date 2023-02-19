# Auto Seedbox

Scripts to watch macOS `~/Downloads` folder for `.torrent` files, upload them
to a seedbox, and download the resulting files.

Also has ability to automatically SCP `.epub` files to an online Kindle running KOReader.

## Why?

1. To be a good citizen, and seed your torrents
1. To remove the hassle of having to keep your laptop cracked open to do so
1. To prevent snooping on your torrent downloads by your ISP
1. To make downloading torrents as easy as any other file
1. For books, to reduce the activation energy to reading as much as possible

## Requirements

- macOS computer with [Homebrew](https://brew.sh) installed

- Seedbox with SFTP access

  - Must be able to put SSH key on machine (This is doable with only `sftp` and
    no SSH access.)

  - Must be running qBittorrent (Probably can make it work otherwise, but this
    is what I chose.)
    
  - This could be local, cloud self-run, or [managed][seedit4me]

## Setup

This requires some manual configuration to work. I haven't tested this on
setups that are not my own. If this doesn't work for you, please file an
issue.

### Set up public key authentication

1. Generate SSH key: `ssh-keygen -t ed25519 -f ~/.ssh/id_seedbox`
   - Use a password manager to generate a secure passphrase. Save it.

1. Add key to SSH agent `ssh-add --apple-use-keychain ~/.ssh/id_seedbox`

   - This may fail. If so, either `brew unlink openssh` or call
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

    This isn't necessary (the script generates its own config), but it's a
    solid quality-of-life improvement.

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

### Set up qBittorrent

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

<!--
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
-->

### Install auto-seedbox

1. Install [Homebrew](https://brew.sh) if you haven't already.

1. Install this repo:

   ```shell
   brew tap riley-martine/auto-seedbox
   brew install auto-seedbox
   ```

1. Set up your config in `~/.config/auto-seedbox/config.json`. All fields are
   required. It should look like this:

   ```json
   {
       "seedbox_user": "root",
       "seedbox_host": "website.address",
       "seedbox_port": "7777",
       "seedbox_key": "~/.ssh/id_seedbox",
       "send_to_kindle": true
   }
   ```

1. Run `brew services start auto-seedbox`.

1. To test this is working, `tail -50 -f
   /opt/homebrew/var/log/auto-seedbox.log`. Add a [torrent file][abramelin]
   to `~/Downloads`, and watch the logs as it downloads.

<!--
1. You may need to Open System Settings, go to "Privacy and Security", then
   to "Full Disk Access". Click the `+`. In the selection window, press
   Cmd-Shift-G, and type in `/bin/`. Click on `bash`, and select it with
   `open`
   -->

At this point, you're probably done! Congratulations! However, if you're also
trying to get your ebooks onto a Kindle, read on...

### (Optional) Set up Kindle

Note: This probably works with non-Kindle KOReader, but I haven't tried it.

1. [Jailbreak][jailbreak] your Kindle. Follow ALL instructions in the thread
   carefully. Do not connect to the internet. This may take a while, but do it
   right.

1. Install KUAL, gawk, KUAL+, KUAL Helper. See linked snapshots thread.

1. Install [KOReader][koreader-install]

1. Disable OTA updates through KUAL

   1. If running FW >= 5.12.x, you MUST also disable OTA updates with method
      described [here][ota]. You can do this through KOReader's shell in Top
      Menu > Tools Icon > More Tools > Terminal emulator > Open terminal
      session. Here is what I ran (the hosts stuff is a bit extra, but sue me I
      guess, I was working on this too long to get got by an update):

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
   you want the books to go. Add a file to your Kindle in the directory you want
   (I used `/mnt/us/documents` because that's where Calibre was putting things)
   and run `# ls /../../../mnt/us/documents/` to confirm you see your file; if
   not, correct the path and edit it in `copy_to_kindle.sh`.

1. Test `./copy_to_kindle.sh ~/Downloads/example.epub`. It may be slow the first
   time as it finds the Kindle. This should copy a file to the Kindle.

1. Test the whole thing together. Find a [torrent][fruit] that has an epub in
   it, download it, and watch the logs (`tail -f
   /opt/homebrew/var/log/auto-seedbox.log`). If your Kindle is online,
   everything should work.

## Developing

```shell
brew install --verbose --debug --HEAD ./Formula/auto-seedbox.rb
brew services restart auto-seedbox
tail -50 -f /opt/homebrew/var/log/auto-seedbox.log
```

[add-key-server]: https://linuxhandbook.com/add-ssh-public-key-to-server/
[kybalion]: https://archive.org/download/kybalionstudyofh00thre/kybalionstudyofh00thre_archive.torrent
[abramelin]: https://archive.org/download/bookofsacredmagi00abra/bookofsacredmagi00abra_archive.torrent
[jailbreak]: https://www.mobileread.com/forums/showthread.php?t=320564
[ota]: https://www.mobileread.com/forums/showthread.php?t=327879&highlight=touch&page=2
[koreader-install]: https://github.com/koreader/koreader/wiki/Installation-on-Kindle-devices
[fruit]: https://archive.org/download/forbiddenfruitlu28520gut/forbiddenfruitlu28520gut_archive.torrent
[seedit4me]: https://seedit4.me/
