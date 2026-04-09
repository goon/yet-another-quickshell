# goon/yet-another-quickshell

Blazingly mid desktop shell built with [Quickshell](https://quickshell.org/) for personal use within my [Nix OS](https://github.com/goon/nixos) configuration delivering a mediocre at best desktop experience. It's **feature limited** by design, **proudly unoptimised** and a questionable attempt replicating what others have done far better.

> [!IMPORTANT]
>
> - I am **not** taking feature requests.
>   - I'm not interested in adding features that do not advance my own use cases. Feel free to **fork** it, modify it and add features as you like.
> - Issue and bug reports are appreciated. 

> [!WARNING]
> 
> - This repository is constantly evolving. It is prone to drastic and likely **breaking** changes.
> - Features may be partially implemented or entirely broken.
> - The README and documentation will often times be outdated.
> - I provide **no guarantees** of stability or support.

## Dependencies 

Whilst the shell is intended for personal use within my [Nix](https://github.com/goon/nixos) configuration, it **is** intended to be distro agnostic. It has been minimally tested on Arch and it's derivatives.

> [!IMPORTANT]
> 
> Don't use the `install.sh` script. It's a mess and outdated.
>
> *It was intended for Arch and derivitives, but it is no longer maintained*.

> [!NOTE]
>
> Package names may vary across distributions. 

```
quickshell-git
qt6-base
qt6-declarative
qt6-svg
qt6-wayland
qt6-connnectivity
qt6-shadertools
cliphist
wl-clipboard
mesa-utils
xdg-utils
xdg-open
nmcli
upower
powerprofilesctl
bluez-utils
brightnessctl
ddcutil
pciutils
gowall
glib2
pywal-git
python-pywalfox
```

