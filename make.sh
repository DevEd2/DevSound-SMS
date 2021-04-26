#!/bin/sh
wla-z80 -v -o main.o Main.asm
wlalink -d -v -s main.lk DevSound.sms
