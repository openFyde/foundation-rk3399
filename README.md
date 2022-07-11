## How to build.
### WARNING: these ebuilds are still in developing. The image is not working properly.

1. Get Chromium OS: refer to [Build Chromium OS for raspberry pi 4](https://github.com/FydeOS/chromium_os-raspberry_pi#readme)

2. Prepare ebuild for rk3399:

```
(inside cros sdk)
(cr) git clone <this project> ~/github/chromium_os-rk3399
(cr) cd ~/trunk/src/overlays/
(cr) ln -s ~/github/chromium_os-rk3399/chipset-rk3399-openfyde .
(cr) ln -s ~/github/chromium_os-rk3399/baseboard-rockpi4 .
(cr) ln -s ~/github/chromium_os-rk3399/overlay-rockpi4b-openfyde .
(cr) setup_board --board=rockpi4b-openfyde
```

3. Build Image

```
(cr) ./build_package --board=rockpi4b-openfyde --nowithautotest
(cr) ./build_image --board=rockpi4b-openfyde --noenable_rootfs_verification test
```

4. Flash the generated image to your EMMC/MicroSD card.

5. The board will reboot. Login with the account: chronos, passwd: test0000.
