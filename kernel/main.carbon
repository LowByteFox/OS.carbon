// SPDX-License-Identifier: 0BSD
import Core library "io";

import Cpp inline '''
typedef unsigned char uint8_t;
typedef unsigned short uint16_t;
typedef unsigned int uint32_t;

uint16_t *terminal_buffer = (uint16_t*) 0xB8000;

static void update_terminal(uint32_t index, uint16_t color)
{
    terminal_buffer[index] = color;
}
''';

let VGA_COLOR_BLACK: i32 = 0;
let VGA_COLOR_BLUE: i32 = 1;
let VGA_COLOR_GREEN: i32 = 2;
let VGA_COLOR_CYAN: i32 = 3;
let VGA_COLOR_RED: i32 = 4;
let VGA_COLOR_MAGENTA: i32 = 5;
let VGA_COLOR_BROWN: i32 = 6;
let VGA_COLOR_LIGHT_GREY: i32 = 7;
let VGA_COLOR_DARK_GREY: i32 = 8;
let VGA_COLOR_LIGHT_BLUE: i32 = 9;
let VGA_COLOR_LIGHT_GREEN: i32 = 10;
let VGA_COLOR_LIGHT_CYAN: i32 = 11;
let VGA_COLOR_LIGHT_RED: i32 = 12;
let VGA_COLOR_LIGHT_MAGENTA: i32 = 13;
let VGA_COLOR_LIGHT_BROWN: i32 = 14;
let VGA_COLOR_WHITE: i32 = 15;

fn vga_entry_color(fg: i32, bg: i32) -> u8
{
	return (fg | (bg << 4)) as u8;
}

fn vga_entry(uc: char, color: u8) -> u16
{
	return (uc as u16) | ((color as u16) << 8);
}

let VGA_WIDTH: u32 = 80;
let VGA_HEIGHT: u32 = 25;

var terminal_row: u32;
var terminal_column: u32;
var terminal_color: u8;

fn terminal_initialize()
{
	terminal_row = 0;
	terminal_column = 0;
	terminal_color = vga_entry_color(VGA_COLOR_LIGHT_GREY, VGA_COLOR_BLACK);

    var i: u32 = 0;

    while (i < VGA_HEIGHT * VGA_WIDTH) {
        Cpp.update_terminal(i, vga_entry(' ', terminal_color));
        i += 1;
    }
}

fn terminal_setcolor(color: u8) 
{
	terminal_color = color;
}

fn terminal_putentryat(c: char, color: u8, x: u32, y: u32) 
{
	let index: u32 = y * VGA_WIDTH + x;
    Cpp.update_terminal(index, vga_entry(c, color));
}

fn terminal_putchar(c: char) 
{
	terminal_putentryat(c, terminal_color, terminal_column, terminal_row);
    terminal_column += 1;
	if (terminal_column == VGA_WIDTH) {
		terminal_column = 0;
        terminal_row += 1;
		if (terminal_row == VGA_HEIGHT) {
			terminal_row = 0;
        }
	}
}

fn terminal_writestring(data: str)
{
    var i: u32 = 0;

    while (true) {
        if (data[i] == '\0') { break; }

        terminal_putchar(data[i]);
        i += 1;
    }
}

fn main()
{
    terminal_initialize();

    terminal_writestring("Hello, World from Carbon!\0");
}
