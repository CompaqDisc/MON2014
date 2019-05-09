BASEADDR=0xF000
BASENAME=MON2014

all: MON2014.ROM

MON2014.ROM:
	zasm -uwy ${BASENAME}.ASM
	mv ${BASENAME}.lst build/${BASENAME}.LST
	mv ${BASENAME}.rom build/${BASENAME}.BIN
	objcopy -I binary -O ihex --change-address ${BASEADDR} build/${BASENAME}.BIN build/${BASENAME}.HEX
	sed -i '/:[0-9A-F]\{6\}03[0-9A-F]\+/d' build/${BASENAME}.HEX

clean:
	rm build/${BASENAME}.LST
	rm build/${BASENAME}.BIN
	rm build/${BASENAME}.HEX
