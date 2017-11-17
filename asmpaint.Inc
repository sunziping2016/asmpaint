include user32.inc
include kernel32.inc
include gdi32.inc
include windows.inc
include comctl32.inc
include comdlg32.inc
include msvcrt.inc
include shell32.inc
include shlwapi.inc

includelib user32.lib
includelib kernel32.lib
includelib gdi32.lib
includelib comctl32.lib
includelib comdlg32.lib
includelib msvcrt.lib
includelib shell32.lib
includelib shlwapi.lib

include asmpaintEqu.inc

IDM_TOOLBAR_FIRST equ 10010
IDM_FREE_SELECTOR equ 10010
IDM_RECT_SELECTOR equ 10011
IDM_ERASER equ 10012
IDM_PAINT_BARREL equ 10013
IDM_COLOR_PICKER equ 10014
IDM_MAGNIFIER equ 10015
IDM_PENCIL equ 10016
IDM_BRASH equ 10017
IDM_AIRBRUSH equ 10018
IDM_TEXT equ 10019
IDM_STRAIGHT_LINE equ 10020
IDM_CURVE equ 10021
IDM_RECTANGLE equ 10022
IDM_POLYGON equ 10023
IDM_ELLIPSE equ 10024
IDM_ROUNDED_RECTANGLE equ 10025
IDM_TOOLBAR_LAST equ 10025

IDM_FOREGROUND_COLOR equ 10026
IDM_BACKGROUND_COLOR equ 10027
