#include <stdio.h>
#include <string.h>

#define BUF_SIZE 256

unsigned char rf_magic_str[] = "525445525f354e4f4f425f5f4453544f";
unsigned char retrofd_str[] = "retrofdretrofdretrofdretrofdretr";
int magic_len;
unsigned char *magic_str, *write_str;

int find_str(unsigned char *s, int bs)
{
	int i, j;

	for (i = 0; i < bs; i++) {
		if (s[i] == magic_str[0]) {
			for (j = i; j < bs; j++) {
				if (magic_str[j - i] == '\0') {
					return (i);
				}
				if (s[j] != magic_str[j - i]) {
					i = j;
					break;
				}
			}
			if (i != j) {
				return (i);
			}
		}	
	}
	return -1;
}

int check_2nd_buf(unsigned char *s, int bs, int idx)
{
	int i;

	if (magic_len - idx > bs) {
		return -1;
	}
	for (i = 0; i < magic_len - idx; i++) {
		if (s[i] != magic_str[idx++]) {
			return -1;
		} 
	}
	return 0;
}

int main(int argc, char **argv)
{
	FILE *fp;
	unsigned char buf[BUF_SIZE];
	int i, buf_size, found_len, found_idx;
	long patch_ptr;
	int rev = 0;

	if (!strcmp(argv[1], "-r")) {
		rev = 1;
		magic_str = retrofd_str;
		write_str = rf_magic_str;
	} else {
		magic_str = rf_magic_str;
		write_str = retrofd_str;
	}

	magic_len = strlen(magic_str);

	if ((fp = fopen(argv[rev?2:1], "rb+")) == NULL) {
		printf("no file\n");
		return 1;
	}

	found_len = -1;
	for (i = 0; (buf_size = fread(buf, 1, BUF_SIZE, fp)) > 0; i++) {
		if (found_len >= 0) {
			if (check_2nd_buf(buf, buf_size, found_len) >= 0) {
				goto found;
			}
		}
		found_idx = find_str(buf, buf_size);
		if (found_idx >= 0) {
			patch_ptr = i * BUF_SIZE + found_idx;	
			found_len = buf_size - found_idx;
			if (found_len >= magic_len) {
				goto found;
			}
			printf("find 1st %d\n", found_len);
		}
	}
	// not found
	fclose(fp);
	return 0;
found:
	printf("found: %ld\n", patch_ptr);
	fseek(fp, patch_ptr, SEEK_SET);
	fwrite(write_str, 1, magic_len, fp);
	fclose(fp);
}
