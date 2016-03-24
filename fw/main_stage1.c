/* -*- Mode: C; c-basic-offset:4 ; indent-tabs-mode:nil ; -*- */
/* main.c */

/*******************************************************************************
** MINIMIG-DE0 startup **
Copyright 2016, spersvoldd@gmail.com
Copyright 2012, rok.krajnc@gmail.com

This is main startup firmware for the ctrl block in the Minimig DE0-CV port

This file is part of Minimig

The code is based off the DE1 port by rok.krajnc@gmail.com

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
*******************************************************************************/

#include "hardware.h"
#include "mmc.h"
#include "fat.h"

static const char * firmware="DE0_BOOTBIN";
fileTYPE file;
char led;

void main(void) __attribute__ ((noreturn));
void FatalError(void) __attribute__ ((noreturn));

void main(void)
{
    DEBUG_FUNC_IN(DEBUG_F_MAIN | DEBUG_L2);

    // !!! a pointer to start of RAM
    unsigned char* ram = ((unsigned char *)0x400000);

    // initialize SD card
    LEDS(led=0xf);
    if (!MMC_Init()) FatalError();

    // find drive
    LEDS(led=0x8);
    if (!FindDrive()) FatalError();

    // open and load file
    LEDS(led=0x3);
    if (!LoadFile(firmware,ram)) FatalError();

    // jump to RAM firmware
    LEDS(led=0x0);
    DisableCard();
    sys_jump(0x400004);

    // loop forever
    while(1);

    DEBUG_FUNC_OUT(DEBUG_F_MAIN | DEBUG_L2);
}

// fatal error
void FatalError(void)
{
    DEBUG_FUNC_IN(DEBUG_F_MAIN | DEBUG_L3);

    DisableCard();

    // loop forever
    while(1)
    {
        TIMER_wait(200);
        LEDS(0x0);
        TIMER_wait(200);
        LEDS(led);
    }

    DEBUG_FUNC_OUT(DEBUG_F_MAIN | DEBUG_L3);
}
