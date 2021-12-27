# Testing Zebra on iOS simulator

## Prerequisites

- `ldid` and `perl` are installed.
- Debug flag set to false (`Command + <` or Edit Scheme, uncheck `Debug executable` in Info tab).
- `DYLD_INSERT_LIBRARIES` is disabled (Edit Scheme, uncheck that in Arguments tab).

iOS simulator is an isolated environment where Procursus bootstrap is out of reach. You need the libraries to be copied or symlinked to the rootfs of that particular simulator. That's not all, because Procursus bootstrap isn't shipped with iOS-sim platform (it only works with macOS Catalyst), you require patchwork among the libraries. The script [to-sim-bin.sh](./to-sim-bin.sh) does it for you.

`to-sim-bin.sh` requires one argument which is the path to `/usr/lib` of your target iOS simulator. The format can be either:

- `/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS.simruntime/Contents/Resources/RuntimeRoot/usr/lib` (built-in simulator)
- `"/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS <VERSION>.simruntime/Contents/Resources/RuntimeRoot/usr/lib"` (optional simulators from Xcode app)

`to-sim-bin.sh` clones Procursus' `/usr/lib` directory to `/usr/lib-sim`, patches all libraries to be compatible with iOS-sim, resigns them with `ldid` then creates symlinks of them to the target `/usr/lib` inside the simulator. The example below allows you to run Zebra on iOS 14.5 simulator:

```sh
sudo to-sim-bin.sh "/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS 14.5.simruntime/Contents/Resources/RuntimeRoot/usr/lib"
```

You are required to run the script for every iOS simulator you wish to be working on.
