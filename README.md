# MON2014
An in-memory monitor for RC2014-based micros.

## Building
Requires:
- [zasm](https://k1.spdns.de/Develop/Projects/zasm/Distributions/)
- objcopy

Just run `make` when ready.

## Uploading to SBC
1. `minicom -D/dev/ttyUSB0 115200`
2. Select a cold boot.
3. Enter a memtop of 35071.
4. Paste in the contents of HEXLOAD.BAS, it will auto-run.
5. Paste in the contents of build/MON2014.HEX to be loaded and started.

## Usage
When started, you will be greeted with some text and a square bracket prompt. Type in `?`, followed by enter to see the help text.

![Screenshot of Help Screen](https://i.imgur.com/ci5ck29.png  "Help Screen")

**Reset**
The `R` command resets the system by performing a jump to $0000, returning the system to BASIC. If you wish to return to the monitor later, select a warm boot, then key in `PRINT USR(0)` when you wish to return.

**Goto**
The `G` command takes in an address to jump to. For example: `G F000` will restart the monitor, effectively clearing the screen.

**Store**
The `S` command takes an address, followed by a value. The given value is then stored at the address. 

**Examine**
The `X` command takes an address, then generates a hexdump of the next 256 memory values, starting at the given address.

![Screenshot of Hexdump](https://i.imgur.com/mNH3hLt.png  "Hexdump")

**CompactFlash Access**
The `C` command allows the user to read and write sectors to the CompactFlash device.

The first parameter is a 32-bit hex value representing the 28-bit LBA address of the sector. The second is a memory address to read from/write to. The last character in the command denotes a read or write operation.

For example `C 00000800 D000 R` will request sector $00000800 from the CompactFlash, and read in 512 bytes, starting at $D000.

![Screenshot of CompactFlash hexdump](https://i.imgur.com/hx4sUiV.png  "CompactFlash hexdump")
![Screenshot of CompactFlash hexdump 2](https://i.imgur.com/tkWCeTD.png  "CompactFlash hexdump 2") 
