#ifndef FPGA_H
#define FPGA_H

char BootDraw(char *data, unsigned short len, unsigned short offset, unsigned char stretch);
char BootPrint(const char *text);
void BootExit(void);
void ClearMemory(unsigned long base, unsigned long size);
unsigned char GetFPGAStatus(void);

#endif

