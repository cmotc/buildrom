/*
 * olpcflash.c: SPI Flash programming utility for OLPC.
 *
 * Copyright 2000 Silicon Integrated System Corporation
 * Copyright 2004 Tyan Corp
 *		yhlu yhlu@tyan.com add exclude start and end option
 * Copyright 2005-2006 coresystems GmbH 
 *      Stefan Reinauer <stepan@coresystems.de> added rom layout
 *      support, and checking for suitable rom image, various fixes
 *      support for flashing the Technologic Systems 5300.
 * Copyright 2006  Ron Minniich <rminnich@lanl.gov>
 *      Initial support for EnE KB3920 EC and the spansion
 *      25FL008A 8Mibit SPI part on the OLPC
 * Copyright 2006 Richard A. Smith <smithbone@gmail.com> 
 *      Added lots of additional stuff to make writing to spansion part
 *      work correctly with the OLPC EnE EC.
 * 
 *	This program is free software; you can redistribute it and/or modify
 *	it under the terms of the GNU General Public License as published by
 *	the Free Software Foundation; either version 2 of the License, or
 *	(at your option) any later version.
 *
 *	This program is distributed in the hope that it will be useful,
 *	but WITHOUT ANY WARRANTY; without even the implied warranty of
 *	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *	GNU General Public License for more details.
 *
 *	You should have received a copy of the GNU General Public License
 *	along with this program; if not, write to the Free Software
 *	Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 *
 */

#include <errno.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <getopt.h>
#include <sys/io.h>
#include <sys/time.h>
#include <time.h>

#define printf_debug(x...) { if(verbose) printf(x); }
#define printf_super_debug(x...) { if(verbose > 1) printf(x); }

#define VER_MAJOR   0
#define VER_MINOR   3
#define VER_RELEASE 0

#define LINUXBIOS_START		0x10000
#define PAGE_SIZE			256
#define EC_CODE_SIZE 		(64*1024)
#define ROM_SIZE			(1024*1024)
#define IOBASE_DEFAULT			(0x381)

enum {
	GPIO5 = 0xfc2a,
	SPIA0 = 0xfea8, 
	SPIA1, 
	SPIA2, 
	SPIDAT,
	SPICMD, 
	SPICFG,
	SPIDATR
};

enum {
	DUMMY,
	WRITESTATUS = 1,
	BYTEPROGRAM, 
	READ,
	WRITEDISABLE,
	READSTATUS,	
	WRITEENABLE,
	HIGHSPEEDREAD 	= 0xb,
	SECTORERASESST 	= 0x20, 
	ENABLEWRITESTATUSSST = 0x50,
	BLOCKERASESST 	= 0x52,  /* 32k block */
	CHIPERASESST 	= 0x60,
	READJDECID 	= 0x9f,
	AUTOINCPROGSST  = 0xad,
	CHIPERASEPCM 	= 0xc7, /* also nexflash */
	SECTORERASEPCM 	= 0xd7,
	BLOCKERASEPCM 	= 0xd8, /* also nexflash, and spansion, SST (64k) */
};

enum {
	SPIBUSY = 2, 
	SPIFIRMWAREMODE = 1 << 4,
	SPICMDWE = 8,
	SPIFLASHREADCE = 1 << 6
};

enum {
	WIP = 1 << 0
};

enum {
	SPANSION	= 0x01,
	SST 		= 0xbf,
	WINBOND 	= 0xef
};

struct flashchip {
	int manufacture_id;
	int model_type;
	int model_id;

	int total_size;
	int page_size;

	int (*write_page) (unsigned char *buf, unsigned long addr, unsigned long size);

};

char *chip_to_probe = NULL;

int exclude_start_page, exclude_end_page;
int force=0, verbose=0; int noop=0;

/* this is the defaut index and data IO base address for
 * EC register access.
 * setup by the EC code.
 */

unsigned short iobase = IOBASE_DEFAULT;

// count to a billion. Time it. If it's < 1 sec, count to 10B, etc.
unsigned long micro = 1;


void myusec_delay(int time)
{
	volatile unsigned long i;
	for (i = 0; i < time * micro; i++);
}

void myusec_calibrate_delay()
{
	int count = 1000;
	unsigned long timeusec;
	struct timeval start, end;
	int ok = 0;

	printf_debug("Setting up microsecond timing loop\n");
	while (!ok) {
		gettimeofday(&start, 0);
		myusec_delay(count);
		gettimeofday(&end, 0);
		timeusec = 1000000 * (end.tv_sec - start.tv_sec) +
		    (end.tv_usec - start.tv_usec);
		count *= 2;
		if (timeusec < 1000000 / 4)
			continue;
		ok = 1;
	}

	// compute one microsecond. That will be count / time
	micro = count / timeusec;

	printf_debug("%ldM loops per second\n", (unsigned long) micro);
}


void setecindex(unsigned short index)
{
	unsigned char hi = index>>8;
	unsigned char lo = index;

	if (noop) return;

	outb(hi, iobase);
	outb(lo, iobase+1);
	printf_super_debug("%s: set 0x%x to 0x%x, 0x%x to 0x%x\n", __FUNCTION__, 
		iobase, hi, iobase+1, lo);
}

unsigned char getecdata(void)
{
	unsigned char data;

	if (noop) return 0;

	data = inb(iobase+2);
	printf_super_debug("%s: read 0x%x from 0x%x\n", __FUNCTION__, data, iobase+2);
	return data;
}

void putecdata(unsigned char data)
{

	if (noop) return;

	outb(data, iobase+2);
	printf_super_debug("%s: wrote 0x%x to 0x%x\n", __FUNCTION__, data, iobase+2);
}

unsigned char readecdata(unsigned short index)
{
	setecindex(index);
	return getecdata();
}

void writeecdata(unsigned short index, unsigned char data)
{
	setecindex(index);
	putecdata(data);
}

void setaddr(unsigned long addr){
	unsigned char data;
	data = addr;
	writeecdata(SPIA0, data);
	data = addr >> 8;
	writeecdata(SPIA1, data);
	data = addr >> 16;
	writeecdata(SPIA2, data);
}

unsigned char rdata(void)
{
	unsigned char data;
	data = readecdata(SPIDAT);
	return data;
}

void wdata(unsigned char data)
{
	writeecdata(SPIDAT, data);
}

unsigned char cmd(void)
{
	return readecdata(SPICMD);
}

void docmd(unsigned char cmd)
{
	printf_super_debug("docmd: cmd 0x%x\n", cmd);
	writeecdata(SPICMD, cmd);
	printf_super_debug("docmd: cmd 0x%x\n", cmd);
}

void wait_cmd_sent(void)
{
	int trycount = 0;
	myusec_delay(10);

	if (noop) return;

	while (readecdata(SPICFG) & SPIBUSY){
		trycount++;
		myusec_delay(10);
		if (trycount > 100000){ /* 1 second! */
			printf("wait_sent: Err: waited for > 1 second\n");
			trycount = 0;
		}
	}
}	

/* 
 * The EnE code has lots of small delays inbetween
 * many of the actions.  Route all this through 
 * one function so I can play with how long they
 * need to be.
 */
void short_delay(void)
{
	// EnE code did 4 pci reads of the base address
	// which should be around 800nS
	// 2 uS should cover it in case I'm wrong
	myusec_delay(2);
}

/*
 * Firmware mode allows you raw control over the SPI bus
 * the spansion part is not supported by the EC in 
 * "hardware" mode.
 * in this mode bytes written to the SPICMD register
 * are clocked out the bus.
 * This also asserts SPICS#
 */
void start_SPI_firmware_mode_access(void)
{
	writeecdata(SPICFG,0x18);
}

void end_SPI_firmware_mode_access(void)
{
	writeecdata(SPICFG,0x08);
}

/*
 * You must do this prior to _every_ command that
 * writes data to the part.  The write enable
 * latch resets after write commands complete.
 */
void send_write_enable(void) {
	start_SPI_firmware_mode_access();
	short_delay();
	docmd(WRITEENABLE);
	wait_cmd_sent();
	end_SPI_firmware_mode_access();
}

void send_addr(unsigned long addr)
{
	unsigned char data;

	data = addr >> 16 & 0xff;
	docmd(data);
	wait_cmd_sent();

	data = addr >> 8 & 0xff;
	docmd(data);
	wait_cmd_sent();

	data = addr & 0xff;
	docmd(data);
}

void enable_flash_cmd(void)
{
	writeecdata(SPICFG, SPICMDWE|readecdata(SPICFG));
}

void enable_flash_write_protect(void)
{
	unsigned char val;
	val = readecdata(GPIO5);
	val &= ~0x80;
	writeecdata(GPIO5,val);
}

void disable_flash_write_protect(void)
{
	unsigned char val;
	val = readecdata(GPIO5);
	val |= 0x80;
	writeecdata(GPIO5,val);
}

/*
 * This appears to be necessary.  If you watch the lines with 
 *	scope you will see that there is constant activity on the SPI
 *	bus to the part.  Trying to write to the port while all that
 * is going on is sure to muck things up.
 * Putting this into reset stops all that 
 * activity.

 * Plus Ray Tseng said so.
 * 
 */
void put_kbc_in_reset(void)
{
	unsigned char val;
	unsigned long timeout = 500000;

	if (noop) return;

	outb(0xd8,0x66);
	while((inb(0x66) & 0x02) && (timeout>0)) {
		timeout--;
	}
	val = readecdata(0xff14);
	val |= 0x01;
	writeecdata(0xff14,val);
}

void restore_kbc_run_mode(void)
{
	unsigned char val;

	val = readecdata(0xff14);
	val &= ~0x01;
	writeecdata(0xff14,val);
}

unsigned char read_status_register(void)
{
	unsigned char data=0;
	start_SPI_firmware_mode_access();
	short_delay();
	docmd(READSTATUS);
	wait_cmd_sent();
	docmd(DUMMY);
	wait_cmd_sent();
	data =  rdata();
	end_SPI_firmware_mode_access();
	return data;
}

// Staus reg writes; erases and programs all need to 
// check this status bit.
int wait_write_done(void)
{
	int trycount = 0;

	if (noop) return 0;

	while (read_status_register() & WIP){
		trycount++;
		myusec_delay(10);
		// For the spansion part datasheet claims that 
		// the only thing that takes longer than 500mS is 
		// bulk erase and we don't ever want to use that
		// command
		if (trycount > 100000){ /* 1 second! */
			printf("wait_write_done: Err: waited for > 1 second\n");
			trycount = 0;
			return -1;
		}
	}

	return 0;
}	

int erase_sector(unsigned long addr)
{
	send_write_enable();
	short_delay();

	start_SPI_firmware_mode_access();
	short_delay();

	docmd(BLOCKERASEPCM);
	wait_cmd_sent();

	send_addr(addr);
	wait_cmd_sent();

	end_SPI_firmware_mode_access();

	return wait_write_done();
}

/*
 Erase from sectors 0x10000 to 0xf0000
*/
int erase_linuxbios_area(void) 
{
	unsigned long addr;

	for (addr = 0x10000;addr < 0xfffff;addr+=0x10000) {
		printf("Erasing Sector: 0x%08lx\r\n",addr);
		erase_sector(addr);
	}
	return 0;
}

int erase_EC_area(void) 
{
	unsigned long addr = 0;
	printf("Erasing Sector: 0x%08lx\r\n",addr);
	erase_sector(addr);
	return 0;
}

int erase_flash(int mode)
{
	if (mode == 1) {
		erase_EC_area();
	}
	erase_linuxbios_area();
	return 0;
}


unsigned char read_flash_byte(unsigned long addr) 
{
	unsigned char data;

	setaddr(addr);
	docmd(READ);
	wait_cmd_sent();
	data =  rdata();
	printf_debug("read 0x%x@0x%lx\n", data, addr);
	return data;
}

int read_flash(unsigned char *buf, unsigned long start, unsigned long size)
{
	unsigned long i;

	printf("Reading %ld bytes from %lx\r\n",size,start);
	for (i = start; i < start+size; i++) {
		if ((i % 0x10000) == 0) printf("Sector 0x%08lx\r\n", i);
		*buf = read_flash_byte(i);
		buf++;
	}
	return 0;
}

int read_jdec_id(struct flashchip *flash)
{
	unsigned char data;

	start_SPI_firmware_mode_access();
	short_delay();

	docmd(READJDECID);
	wait_cmd_sent();
	docmd(DUMMY);
	wait_cmd_sent();
	data = rdata();
	flash->manufacture_id = data;
	docmd(DUMMY);
	wait_cmd_sent();
	data = rdata();
	flash->model_type = data;
	docmd(DUMMY);
	wait_cmd_sent();
	data = rdata();
	flash->model_id = data;

	end_SPI_firmware_mode_access();
	
	return 0;
}

int write_flash_byte(unsigned long addr, unsigned char data) {

	send_write_enable();
	short_delay();

	start_SPI_firmware_mode_access();
	short_delay();

	docmd(BYTEPROGRAM);
	wait_cmd_sent();

	send_addr(addr);
	wait_cmd_sent();

	docmd(data);
	wait_cmd_sent();

	end_SPI_firmware_mode_access();

	wait_write_done();
/*
	unsigned char verify;
	verify =  read_flash_byte(addr);
	if (verify != data) {
		printf("addr 0x%x, want 0x%x, got 0x%x\n", 
				addr, data, verify);
		return -1;
	}
*/
	return 0;
}

int write_flash_page(unsigned char *buf, unsigned long addr, unsigned long size)
{
	
	send_write_enable();
	short_delay();

	start_SPI_firmware_mode_access();
	short_delay();

	docmd(BYTEPROGRAM);
	wait_cmd_sent();

	send_addr(addr);
	wait_cmd_sent();

	while (size > 0) {
		docmd(*buf);
		wait_cmd_sent();
		size--;
		buf++;
	}

	end_SPI_firmware_mode_access();

	wait_write_done();
/*
	unsigned char verify;
	verify =  read_flash_byte(addr);
	if (verify != data) {
		printf("addr 0x%x, want 0x%x, got 0x%x\n", 
				addr, data, verify);
		return -1;
	}
*/
	return 0;
}

int
write_flash(unsigned char *buf, unsigned long start, unsigned long size){
	unsigned long p=0;
	unsigned long pages=0;
	unsigned long short_page=0;
	
	pages = (size+(PAGE_SIZE-1))/PAGE_SIZE;
	short_page = size-(pages*PAGE_SIZE);

	printf("Writing %ld bytes starting at address 0x%lx\r\n",size,start);

	for (p=0;p<pages;p++) {
		if ((start % 0x10000) == 0) printf("Sector 0x%08lx\r\n", start);
		printf_debug("Page %ld/%ld\r",p+1,pages);

		if (write_flash_page(buf,start,PAGE_SIZE)) {
			return -1;
		}

		buf+=PAGE_SIZE;
		start+=PAGE_SIZE;
	}
	printf_debug("\r\n");

	if (short_page) {
		printf_debug("Short Page of %ld bytes\r\n",short_page);	
		printf_debug("Address %ld\r\n",start);	

		if (write_flash_page(buf,start,short_page)) {
			return -1;
		}
	}

	return 0;
}

int verify_flash(unsigned char *buf, unsigned long start, unsigned long size)
{
	unsigned long idx;
	unsigned char r_val;

	printf("Verifying flash\n");
	
	if(verbose) printf("address: 0x00000000\b\b\b\b\b\b\b\b\b\b");
	
	for (idx = start; idx < start+size; idx++) {
		if (verbose && ( (idx & 0xfff) == 0xfff ))
			printf("0x%08lx", idx);

		if ((idx % 0x10000) == 0)
			printf("Sector 0x%08lx\r\n", idx);

		r_val = read_flash_byte(idx);

		if ( r_val != *buf ) {
			printf("0x%08lx: ", idx);
			printf("Expected 0x%02x Got 0x%02x\n",*buf,r_val);
			printf("Verify FAILED\n");
			return 1;
		}
		buf++;

		if (verbose && ( (idx & 0xfff) == 0xfff ))
			printf("\b\b\b\b\b\b\b\b\b\b");
	}
	if (verbose) 
		printf("\b\b\b\b\b\b\b\b\b\b ");
	
	printf("- VERIFIED         \n");
	return 0;
}


void usage(const char *name)
{
	printf("%s Ver: %d.%d.%d\n",name,VER_MAJOR,VER_MINOR,VER_RELEASE);
	printf("usage: %s [-rwv] [-V] [file]\n", name);
	printf("   -r | --read      read flash and save into file\n"
	       "   -w | --write     write file into flash\n"
	       "   -v | --verify    verify flash against file\n"
	       "   -E | --erase     erase LinuxBIOS area (0x10000-0xfffff)\n"
	       "   -V | --verbose   more verbose output\n"
               "   -n | --noop Noop mode. Do the motions but no io\n"
               "   -h | --help This message\n"
	       "        --no-verify skip the autoverify on write\n"
	       "   -P | --nobrick: Partial mode. Writes start @ 64Kib\n"	       
	       "   -I | --id        print out part JDEC ID values\n"
	       "   -f | --force-id <id>  Force a specific ID\n"
	       "\n\n");
	exit(1);
}

int main(int argc, char *argv[])
{
	unsigned long size;
	unsigned long start_addr=LINUXBIOS_START;
	FILE *image;
	int opt;
	int option_index = 0;
	int read_it = 0, 
	    write_it = 0, 
	    erase_it = 0, 
	    verify_it = 0,
	    show_id =0;
	int auto_verify = 1;
	int force_id = 0;
	int brick_mode = 1;
	int ret = 0;
	int i=0;
	int forced_id=0;
	unsigned char buf[ROM_SIZE];
	unsigned char* buf_start=NULL;

	struct flashchip flash;

	static struct option long_options[]= {
		{ "read",		0, 0, 'r' },
		{ "write",		0, 0, 'w' },
		{ "erase",		0, 0, 'E' },
		{ "verify", 		0, 0, 'v' },
		{ "iobase",		1, 0, 'i' },
		{ "verbose",		0, 0, 'V' },
		{ "help", 		0, 0, 'h' },
		{ "brick",		0, 0, 'B' },
		{ "nobrick",		0, 0, 'P' },
		{ "noop",		0, 0, 'n' },
		{ "no-verify",		0, 0, 'a' },
		{ "id",			0, 0, 'I' },
		{ "force-id",		1, 0, 'f' },
		{ 0, 0, 0, 0 }
	};
	
	char *filename = NULL;

	setbuf(stdout, NULL);
	while ((opt = getopt_long(argc, argv, "rwvVEnIhPi:f:", long_options,
					&option_index)) != EOF) {
		switch (opt) {
		case 'r':
			read_it = 1;
			break;
		case 'w':
			write_it = 1;
			break;
		case 'v':
			verify_it = 1;
			break;
		case 'V':
			verbose++;
			break;
		case 'E':
			erase_it = 1;
			break;
		case 'i':
			errno = 0;
			iobase = (unsigned short) strtol(optarg,0,0);
			if (errno || (iobase == 0)) {
				printf("Invalid IO base\n");
				exit(1);
			}
			break;
		case 'B':
			brick_mode = 1;
			break;
		case 'P':
			brick_mode = 0;
			break;
		case 'n':
			noop = 1;
			break;
		case 'a':
			auto_verify = 0;
			break;
		case 'I':
			show_id = 1;
			break;

		case 'f': 
			force_id = 1;
			errno = 0;
			forced_id = (int) strtol(optarg,0,0);
			if (errno || (forced_id  == 0)) {
				printf("Invalid Mfg ID\n");
				exit(1);
			}
			break;

		case 'h':
		default:
			usage(argv[0]);
			break;
		}
	}

	if (argc > 1) {
		/* Yes, print them. */
		int i;
		printf_debug ("The arguments are:\n");
		for (i = 1; i < argc; ++i)
			printf_debug ("%s\n", argv[i]);
	}

	if (!noop) {
		if (iopl(3) < 0){
			perror("iop(3)");
			exit(1);
		}
	}

	if (iobase != IOBASE_DEFAULT) {
		printf("Useing IO base of 0x%x\n",(unsigned int)iobase);
	}

	if (read_it && write_it) {
		printf("-r and -w are mutually exclusive\n");
		usage(argv[0]);
	}

	if (optind < argc)
		filename = argv[optind++];

	if (!erase_it && !write_it && !read_it && !verify_it && !show_id) {
		printf("No command specified so no operations performed\n");
		printf("Use -h for details\n");
		exit(2);
	}

	printf("Calibrating delay loop... ");
	myusec_calibrate_delay();
	printf("ok\n");

	enable_flash_cmd();
	/* 
	 * This is required prior to _all_ commands. Otherwise the kbc can steal your data
	 */
	put_kbc_in_reset();

	read_jdec_id(&flash);

	if (show_id) {
		printf("Manufacture ID = 0x%x\n",flash.manufacture_id);
		printf("Model Type     = 0x%x\n",flash.model_type);
		printf("Model ID       = 0x%x\n",flash.model_id);
	}

	if (force_id) {
		flash.manufacture_id = forced_id;
	}

	switch (flash.manufacture_id) {

		case SST:
//			flash.write_page = write_flash_page_sst;
			printf("SST part found\n");
		break;

		case WINBOND:
			flash.write_page = write_flash_page;
			printf("Windbond part found\n");
		break;
		case SPANSION:
			flash.write_page = write_flash_page;
			printf("Spansion part found\n");
		break;

		default:
			printf("Unable to determine flash type\n");
			printf("use the -f option to force\n");
			exit(1);
	}

	size = ROM_SIZE;
	start_addr = 0;
	buf_start = buf;

	for (i=0;i<size;i++) {
		buf[i] = 0xff;
	}

	if (brick_mode != 1) {
		// Normal image
		// Skip the 1st 64k of the part and the 
		// file we loaded
		size -= EC_CODE_SIZE;
		start_addr = LINUXBIOS_START;
		buf_start+= EC_CODE_SIZE;

		printf("Partial modei. Skipping first 64Kib\n");
	}
	else {
		printf("Brick mode. Will operate on the first 64Kib\n");
	}

	if (erase_it) {
		put_kbc_in_reset();
		disable_flash_write_protect();
		erase_flash(brick_mode);
		enable_flash_write_protect();
		exit(0);		
	} else if (read_it) {
		if ((image = fopen(filename, "w")) == NULL) {
			perror(filename);
			exit(1);
		}

		put_kbc_in_reset();

		// Reading allways read the entire part
		read_flash(buf,0,ROM_SIZE);

		fwrite(buf, sizeof(char),ROM_SIZE, image);
		fclose(image);
		printf("done\n");

	} else {
		if ((image = fopen(filename, "r")) == NULL) {
			perror(filename);
			exit(1);
		}
		printf("Loading 0x%x bytes from %s\r\n",ROM_SIZE,filename);
		fread(buf, sizeof(char), ROM_SIZE, image);
		fclose(image);
	}

	if (write_it) {
		put_kbc_in_reset();
		disable_flash_write_protect();
		erase_flash(brick_mode);
		write_flash(buf_start,start_addr, size);
		enable_flash_write_protect();
		if (auto_verify) {
			ret |= verify_flash(buf_start,start_addr,size);
		}
	}

	if (verify_it) {
		put_kbc_in_reset();
		ret |= verify_flash(buf_start,start_addr,size);
	}

	printf("IMPORTANT! The kbc has been left in reset. You keyboard and mouse WILL NOT WORK until you POWER CYCLE.\n");
	printf("A warm reboot is NOT good enough.\n");
	return ret;
}

