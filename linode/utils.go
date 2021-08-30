package main

import (
	"log"
	"os"
	"path/filepath"
)

func FileExists(filename string) bool {
	info, err := os.Stat(filename)
	if os.IsNotExist(err) {
		return false
	}
	return !info.IsDir()
}

func EnsureFileDir(f string) {
	dir, derr := filepath.Abs(filepath.Dir(f))
	if derr != nil {
		log.Fatal(derr)
	}
	if !DirExists(dir) {
		os.MkdirAll(dir, 0700)
	}
	return
}

func EnsureDirExists(d string) bool {
	if DirExists(d) {
		return true
	}
	os.MkdirAll(d, 0700)
	return DirExists(d)
}

func DirExists(filename string) bool {
	info, err := os.Stat(filename)
	if os.IsNotExist(err) {
		return false
	}
	return info.IsDir()
}
