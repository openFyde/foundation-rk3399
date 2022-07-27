## How to build.
### WARNING: these ebuilds are still in developing. The image is not working properly.

1. Get openFyde: refer to [openFyde getting started](https://github.com/openFyde/getting-started)

2. Prepare ebuild for rk3399:

```
(inside cros sdk)
(cr) git clone <this project> ~/github/foundation-rk3399
(cr) git clone https://github.com/openFyde/overlay-rockpi4b-openfyde
(cr) cd ~/trunk/src/overlays/
(cr) ln -s ~/github/foundation-rk3399/chipset-rk3399-openfyde .
(cr) ln -s ~/github/foundation-rk3399/baseboard-rockpi4 .
(cr) ln -s ~/github/overlay-rockpi4b-openfyde .
(cr) setup_board --board=rockpi4b-openfyde
```

3. Build Image

```
(cr) ./build_package --board=rockpi4b-openfyde --nowithautotest
(cr) ./build_image --board=rockpi4b-openfyde --noenable_rootfs_verification test
```

4. Flash the generated image to your EMMC/MicroSD card.

5. The board will reboot. Login with the account: chronos, passwd: test0000.
