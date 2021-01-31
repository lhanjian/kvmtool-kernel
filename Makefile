TARGET_EXEC := kvmtool

SRC_DIRS := $(PWD)
export BUILD_DIR := $(SRC_DIRS)/build

SRCS := $(shell find $(SRC_DIRS) -name "*.c"|grep -v bios\/|grep -v tests|grep -v guest/init.c)
OBJS := $(SRCS:%=$(BUILD_DIR)/%.o)

INC_DIRS := $(shell find $(SRC_DIRS) -name "*include" -type d)
INC_FLAGS := $(addprefix -I,$(INC_DIRS))

CONFIG_DEFINE := -DCONFIG_HAS_SDL -DCONFIG_HAS_VNCSERVER -DCONFIG_HAS_AIO -DCONFIG_X86_64 
BUILD_DEFINE := -D_GNU_SOURCE -DBUILD_ARCH=\"x86\" -D_FILE_OFFSET_BITS=64
BUILD_OPTION := -Wall -std=gnu99 -fno-strict-aliasing -fverbose-asm -O2
LIBS := -lSDL -lvncserver -laio -lutil -lbfd -lpthread
export CFLAGS := $(INC_FLAGS) $(BUILD_DEFINE) $(CONFIG_DEFINE) $(LIBS) $(BUILD_OPTION)


BIOS_CFLAGS := -m32 -march=i386 -mregparm=3 -fno-stack-protector -fno-pic

all: build/x86/bios $(BUILD_DIR)/$(TARGET_EXEC)

build/x86/bios:
	mkdir -p $(BUILD_DIR)/x86/bios/ && cp -r x86/bios $(BUILD_DIR)/x86/
	cd $(BUILD_DIR)/x86/bios && \
	$(CC) $(CFLAGS) $(BIOS_CFLAGS) -c memcpy.c -o memcpy.o && \
	$(CC) $(CFLAGS) $(BIOS_CFLAGS) -c e820.c   -o e820.o && \
	$(CC) $(CFLAGS) $(BIOS_CFLAGS) -c int10.c  -o int10.o && \
	$(CC) $(CFLAGS) $(BIOS_CFLAGS) -c int15.c  -o int15.o && \
	$(CC) $(CFLAGS) $(BIOS_CFLAGS) -c entry.S  -o entry.o && \
	$(LD) -T rom.ld.S -o bios.bin.elf memcpy.o entry.o e820.o int10.o int15.o && \
	objcopy -O binary -j .text  bios.bin.elf bios.bin && \
	$(CC) -c $(CFLAGS) bios-rom.S -o bios-rom.o && \
	bash gen-offsets.sh > bios-rom.h && cp bios-rom.h $(SRC_DIRS)/x86/bios && \
	cd $(SRC_DIRS) #&& \
	#cp $(SRC_DIRS)/x86/bios.c $(BUILD_DIR)/x86/bios.c && \
	#$(CC) $(CFLAGS) -I $(BUILD_DIR)/x86/bios/ $(BUILD_DIR)/x86/bios.c -o $(BUILD_DIR)/x86/bios.c.o



$(BUILD_DIR)/$(TARGET_EXEC): build/x86/bios $(OBJS)
	$(CC) $(CFLAGS) $(OBJS) build/x86/bios/bios-rom.o -o $@

$(BUILD_DIR)/%.c.o: %.c
	mkdir -p $(dir $@) && $(CC) $(CFLAGS) -c $< -o $@

.PHONY: clean build/x86/bios $(BUILD_DIR)/$(TARGET_EXEC) default

clean:
	rm -rf $(BUILD_DIR)
