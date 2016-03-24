/* -*- Mode: C; c-basic-offset:4 ; indent-tabs-mode:nil ; -*- */
/*
Copyright 2005, 2006, 2007 Dennis van Weeren
Copyright 2008, 2009 Jakub Bednarski

This file is part of Minimig

Minimig is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3 of the License, or
(at your option) any later version.

Minimig is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

// 2009-10-10   - any length (any multiple of 8 bytes) fpga core file support
// 2009-12-10   - changed command header id
// 2010-04-14   - changed command header id

#include "stdio.h"
#include "string.h"
#include "errors.h"
#include "hardware.h"
#include "fdd.h"
#include "fpga.h"

#define CMD_HDRID 0xAACA

// draw on screen
char BootDraw(char *data, unsigned short len, unsigned short offset, unsigned char stretch)
{
    DEBUG_FUNC_IN(DEBUG_F_FPGA | DEBUG_L0);

    unsigned char c1, c2, c3, c4;
    unsigned char cmd;
    const char *p;
    unsigned short n;
    unsigned short i;

    if (stretch) len=len*2;

    n = (len+3)&(~3);
    i = 0;

    cmd = 1;
    while (1)
    {
        EnableFpga();
        c1 = SPI(0x10); // track read command
        c2 = SPI(0x01); // disk present
        SPI(0);
        SPI(0);
        c3 = SPI(0);
        c4 = SPI(0);

        if (c1 & CMD_RDTRK)
        {
            if (cmd)
            { // command phase
                if (c3 == 0x80 && c4 == 0x06) // command packet size must be 12 bytes
                {
                    cmd = 0;
                    SPI(CMD_HDRID >> 8); // command header
                    SPI(CMD_HDRID & 0xFF);
                    SPI(0x00); // cmd: 0x0001 = print text
                    SPI(0x01);
                    // data packet size in bytes
                    SPI(0x00);
                    SPI(0x00);
                    SPI((n)>>8);
                    SPI((n)&0xff); // +2 because only even byte count is possible to send and we have to send termination zero byte
                    // offset
                    SPI(0x00);
                    SPI(0x00);
                    SPI(offset>>8);
                    SPI(offset&0xff);
                }
                else
                    break;
            }
            else
            { // data phase
                if (c3 == 0x80 && c4 == ((n) >> 1))
                {
                    p = data;
                    n = c4 << 1;
                    while (n--)
                    {
                      c4 = *p;
                      if (stretch) {
                        SPI((i>=len) ? 0 : ((c4&0x10 ? 3 : 0) | (c4&0x20 ? 12 : 0) | (c4&0x40 ? 48 : 0) | (c4&0x80 ? 192 : 0)));
                        i++;
                        n--;
                        SPI((i>=len) ? 0 : ((c4&0x01 ? 3 : 0) | (c4&0x02 ? 12 : 0) | (c4&0x04 ? 48 : 0) | (c4&0x08 ? 192 : 0)));
                      } else {
                        SPI((i>=len) ? 0 : c4);
                      }
                      p++;
                      i++;
                    }
                    DisableFpga();
                    return 1;
                }
                else
                    break;
            }
        }
        DisableFpga();
    }
    DisableFpga();
    return 0;

    DEBUG_FUNC_OUT(DEBUG_F_FPGA | DEBUG_L0);
}

// print message on the boot screen
char BootPrint(const char *text)
{
    DEBUG_FUNC_IN(DEBUG_F_FPGA | DEBUG_L1);

    unsigned char c1, c2, c3, c4;
    unsigned char cmd;
    const char *p;
    unsigned char n;

    printf(text);
    printf("\r");

    return 0;

    p = text;
    n = 0;
    while (*p++ != 0)
        n++; // calculating string length

    cmd = 1;
    while (1)
    {
        EnableFpga();
        c1 = SPI(0x10); // track read command
        c2 = SPI(0x01); // disk present
        SPI(0);
        SPI(0);
        c3 = SPI(0);
        c4 = SPI(0);

        if (c1 & CMD_RDTRK)
        {
            if (cmd)
            { // command phase
                if (c3 == 0x80 && c4 == 0x06) // command packet size must be 12 bytes
                {
                    cmd = 0;
                    SPI(CMD_HDRID >> 8); // command header
                    SPI(CMD_HDRID & 0xFF);
                    SPI(0x00); // cmd: 0x0001 = print text
                    SPI(0x01);
                    // data packet size in bytes
                    SPI(0x00);
                    SPI(0x00);
                    SPI(0x00);
                    SPI(n+2); // +2 because only even byte count is possible to send and we have to send termination zero byte
                    // don't care
                    SPI(0x00);
                    SPI(0x00);
                    SPI(0x00);
                    SPI(0x00);
                }
                else
                    break;
            }
            else
            { // data phase
                if (c3 == 0x80 && c4 == ((n + 2) >> 1))
                {
                    p = text;
                    n = c4 << 1;
                    while (n--)
                    {
                        c4 = *p;
                        SPI(c4);
                        if (c4) // if current character is not zero go to next one
                            p++;
                    }
                    DisableFpga();
                    return 1;
                }
                else
                    break;
            }
        }
        DisableFpga();
    }
    DisableFpga();
    return 0;

    DEBUG_FUNC_OUT(DEBUG_F_FPGA | DEBUG_L1);
}

void BootExit(void)
{
    DEBUG_FUNC_IN(DEBUG_F_FPGA | DEBUG_L0);

    unsigned char c1, c2, c3, c4;

    while (1)
    {
        EnableFpga();
        c1 = SPI(0x10); // track read command
        c2 = SPI(0x01); // disk present
        SPI(0);
        SPI(0);
        c3 = SPI(0);
        c4 = SPI(0);
        if (c1 & CMD_RDTRK)
        {
            if (c3 == 0x80 && c4 == 0x06) // command packet size 12 bytes
            {
                SPI(CMD_HDRID >> 8); // command header
                SPI(CMD_HDRID & 0xFF);
                SPI(0x00); // cmd: 0x0003 = restart
                SPI(0x03);
                // don't care
                SPI(0x00);
                SPI(0x00);
                SPI(0x00);
                SPI(0x00);
                // don't care
                SPI(0x00);
                SPI(0x00);
                SPI(0x00);
                SPI(0x00);
            }
            DisableFpga();
            return;
        }
        DisableFpga();
    }

    DEBUG_FUNC_OUT(DEBUG_F_FPGA | DEBUG_L0);
}


void ClearMemory(unsigned long base, unsigned long size)
{
    DEBUG_FUNC_IN(DEBUG_F_FPGA | DEBUG_L0);

    unsigned char c1, c2, c3, c4;

    while (1)
    {
        EnableFpga();
        c1 = SPI(0x10); // track read command
        c2 = SPI(0x01); // disk present
        SPI(0);
        SPI(0);
        c3 = SPI(0);
        c4 = SPI(0);
        if (c1 & CMD_RDTRK)
        {
            if (c3 == 0x80 && c4 == 0x06)// command packet size 12 bytes
            {
                SPI(CMD_HDRID >> 8); // command header
                SPI(CMD_HDRID & 0xFF);
                SPI(0x00); // cmd: 0x0004 = clear memory
                SPI(0x04);
                // memory base
                SPI((unsigned char)(base >> 24));
                SPI((unsigned char)(base >> 16));
                SPI((unsigned char)(base >> 8));
                SPI((unsigned char)base);
                // memory size
                SPI((unsigned char)(size >> 24));
                SPI((unsigned char)(size >> 16));
                SPI((unsigned char)(size >> 8));
                SPI((unsigned char)size);
            }
            DisableFpga();
            return;
        }
        DisableFpga();
    }

    DEBUG_FUNC_OUT(DEBUG_F_FPGA | DEBUG_L0);
}


unsigned char GetFPGAStatus(void)
{
    DEBUG_FUNC_IN(DEBUG_F_FPGA | DEBUG_L2);

    unsigned char status;

    EnableFpga();
    status = SPI(0);
    SPI(0);
    SPI(0);
    SPI(0);
    SPI(0);
    SPI(0);
    DisableFpga();

    return status;

    DEBUG_FUNC_OUT(DEBUG_F_FPGA | DEBUG_L2);
}

