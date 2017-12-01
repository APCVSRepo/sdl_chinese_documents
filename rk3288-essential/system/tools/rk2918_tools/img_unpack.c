#include <stdio.h>
#include <errno.h>
#include <string.h>
#include <limits.h>
#include <time.h>
#include <sys/stat.h>
#include "rkrom_29xx.h"
#include "md5.h"

int export_data(const char *filename, unsigned int offset, unsigned int length, FILE *fp)
{
	FILE *out_fp = NULL;
	unsigned char buffer[1024];

	out_fp = fopen(filename, "wb");
	if (!out_fp)
	{
		fprintf(stderr, "can't open output file \"%s\": %s\n",
			filename, strerror(errno));
		goto export_end;
	}

	fseek(fp, offset, SEEK_SET);

	for (;length > 0;)
	{
		int readlen = length < sizeof(buffer) ? length : sizeof(buffer);
		readlen = fread(buffer, 1, readlen, fp);
		length -= readlen;
		fwrite(buffer, 1, readlen, out_fp);
	}
	
	fclose(out_fp);
	return 0;
export_end:
	if (out_fp)
		fclose(out_fp);

	return -1;
}

int check_md5sum(FILE *fp, size_t length)
{
	char buf[1024];
	unsigned char md5sum[16];
	MD5_CTX md5_ctx;
	int i;

	fseek(fp, 0, SEEK_SET);

	MD5_Init(&md5_ctx);
	while (length > 0)
	{
		int readlen = length < sizeof(buf) ? length : sizeof(buf);
		readlen = fread(buf, 1, readlen, fp);
		length -= readlen;
		MD5_Update(&md5_ctx, buf, readlen);
	}

	MD5_Final(md5sum, &md5_ctx);

	if (32 != fread(buf, 1, 32, fp))
		return -1;

	for (i = 0; i < 16; ++i)
	{
		sprintf(buf + 32 + i * 2, "%02x", md5sum[i]);
	}

	if (strncasecmp(buf, buf + 32, 32) == 0)
		return 0;	

	return -1;
}

int unpack_rom(const char* filepath, const char* dstpath,int createpath)
{
	struct _rkfw_header rom_header;
	char dstfile[strlen(dstpath) + 20];

	FILE *fp = fopen(filepath, "rb");
	if (!fp)
	{
		fprintf(stderr, "Can't open file %s\n, reason: %s\n", filepath, strerror(errno));
		goto unpack_fail;
	}


	fseek(fp, 0, SEEK_SET);
	if (1 != fread(&rom_header, sizeof(rom_header), 1, fp))
		goto unpack_fail;

	if (strncmp(RK_ROM_HEADER_CODE, rom_header.head_code, sizeof(rom_header.head_code)) != 0)
	{
		fprintf(stderr, "Invalid rom file: %s\n", filepath);
		goto unpack_fail;
	}

	printf("rom version: %x.%x.%x\n",
		(rom_header.version >> 24) & 0xFF,
		(rom_header.version >> 16) & 0xFF,
		(rom_header.version) & 0xFFFF);

	printf("build time: %d-%02d-%02d %02d:%02d:%02d\n", 
		rom_header.year, rom_header.month, rom_header.day,
		rom_header.hour, rom_header.minute, rom_header.second);

	printf("chip: %x\n", rom_header.chip);

	printf("checking md5sum....");
	fflush(stdout);
	if (check_md5sum(fp, rom_header.image_offset + rom_header.image_length) != 0)
	{
		printf("Not match!\n");
		goto unpack_fail;
	}
	printf("OK\n");
	if(createpath && mkdir(dstpath,S_IRWXU | S_IRWXG | S_IRWXO)){
		fprintf(stderr,"create dest path error.%s(%d)",strerror (errno),errno);
		goto unpack_fail;
	}
	sprintf(dstfile,"%s/loader.img",dstpath);
	export_data(dstfile, rom_header.loader_offset, rom_header.loader_length, fp);
	sprintf(dstfile,"%s/update.img",dstpath);
	export_data(dstfile, rom_header.image_offset, rom_header.image_length, fp);

	fclose(fp);
	return 0;
unpack_fail:
	if (fp)
		fclose(fp);
	return -1;
}

int main(int argc, char **argv)
{
	struct stat st;
	int createdir = 1;
	if (argc != 3)
	{
		fprintf(stderr, "usage: %s <source> <destination folder>\n", argv[0]);
		return 1;
	}
	if(!stat(argv[2],&st) && !S_ISDIR(st.st_mode))
	{
		fprintf(stderr,"%s exist and it's not a directory.\n",argv[2]);
		return 1;
	}
	if(S_ISDIR(st.st_mode)){
		createdir = 0;
	}
	unpack_rom(argv[1], argv[2],createdir);

	return 0;
}
