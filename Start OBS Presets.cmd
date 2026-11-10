@echo off
rem Double-click this (or a desktop shortcut to it) to run OBS Presets.
rem Uses the PowerShell built into Windows - nothing to install.
start "" powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File "%~dp0OBS Presets.ps1"
