# Install guides for my computers

## Arch linux installation

- Follow installation from: https://itsfoss.com/install-arch-linux/ and https://wiki.archlinux.org/index.php/installation_guide where needed
- Create 3 partitions:

  ```
  fdisk -l
  fdisk /dev/nvme0n1 # choose the disk that you want to partition
  fdisk d            # remove all partitions
  fdisk n            # create paritions as shown below
  ```
  - efi with 1G (EFI System, fat32)
  - swap with 16GB (Linux swap, swap)
  - root with rest (Linux root x86_64, ext4)

- Then change the types of the partions

  ```
  fdisk t
  ```
  The types should be EFI=1, swap=19 and root=23

- Write everything:

  ```
  fdisk w
  ```

- Format
  
  ```
  mkfs.fat -F32 /dev/nvme0n1p1
  mkswap /dev/nvme0n1p2
  mkfs.ext4 /dev/nvme0n1p3
  ```

- Mount everything

  ```
  mount /dev/nvme0n1p3 /mnt
  mount --mkdir /dev/nvme0n1p1 /mnt/boot
  swapon /dev/nvme0n1p2
  ```

- Connect to WIFI using `iwctl`
- Install stuff

  ```
  pacman -Syy
  pacstrap /mnt base base-devel linux linux-firmware vim
  ```

- Do the fstab stuff

  ```
  genfstab -U /mnt >> /mnt/etc/fstab
  ```

- Do this

  ```
  arch-chroot /mnt

  passwd
  pacman -S grub efibootmgr

  grub-install --target=x86_64-efi --bootloader-id=GRUB --efi-directory=/boot
  grub-mkconfig -o /boot/grub/grub.cfg
  ```

- Then

  ```
  pacman -S sudo
  useradd -m simon
  passwd simon
  usermod -aG wheel,audio,video,storage simon
  ```

- Finally

  ```
  pacman -S xorg networkmanager gnome i3 i3-wm terminator

  systemctl enable gdm.service
  systemctl enable NetworkManager.service
  ```

- Exit all

  ```
  exit
  exit
  umount -l /mnt
  shutdown now
  ```

## General dependencies

* install firefox bookmarks as well as firefox addons
* create an ssh key (ssh-keygen -t rsa) and add to GitHub.
* install git and add 'github/dotfiles' and copy relevent dotfiles
* install zsh and zpretzo and add .zshrc and .zpreztorc (https://github.com/sorin-ionescu/prezto)
* install neovim, add "nvim/init.vim" and install Vundle (git clone https://github.com/VundleVim/Vundle.vim.git ~/.config/nvim/bundle/Vundle.vim) using PluginInstall
* add .condarc and conda install environment called 'default'
* add configs from dotfiles (help: https://i3wm.org/docs/userguide.html)
* install software, such as
  - docker
  - dropbox
  - atom (+ keymap.cson file),
  - sublime,
  - pycharm/webstorm/clion/intellij/julia vs-code,
  - install texlive,
  - signal,
  - firefox, thunderbird, protonmail
  - pacman
  - redshift,
  - audacious, 
  - asunder
  - feh, 'light' (https://github.com/haikarainen/light)
  - flux
* add bookmarks to firefox from dropbox
* clone my repositories using SSH
* install cuda and nvidia driver
* smaller things:
	- customize arch using gnome tweak utils (remove window borders, etc.)
	- firefox adblocks

