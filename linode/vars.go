package main

import (
	"fmt"
	"os"
	"regexp"

	"github.com/kevinburke/ssh_config"
)

var APPS_DIR = `apps`

var DEBUG_MODE = false
var DEV_DOMAIN = os.Getenv("DEV_DOMAIN")
var DEV_USER = `root`
var LINODE_LABEL_PREFIX = fmt.Sprintf(`%s`, `f`)
var LINODE_LABEL_REGEX = regexp.MustCompile("f[0-9].*")
var vm_labels = []string{}

var cfg *ssh_config.Config
