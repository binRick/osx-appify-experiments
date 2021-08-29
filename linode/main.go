package main

import (
	"context"
	"fmt"
	"net"
	"path/filepath"
	"regexp"

	"github.com/kevinburke/ssh_config"
	"github.com/linode/linodego"
	"golang.org/x/oauth2"

	"log"
	"net/http"
	"os"
)

var DEBUG_MODE = false
var DEV_DOMAIN = os.Getenv("DEV_DOMAIN")
var DEV_USER = `root`
var LINODE_LABEL_PREFIX = fmt.Sprintf(`%s`, `f`)
var LINODE_LABEL_REGEX = regexp.MustCompile("f[0-9].*")
var vm_labels = []string{}

type LinodeVM struct {
	ID        int
	Region    string
	Image     string
	IP        *net.IP
	PrivateIP *net.IP
	Type      string
	Hostname  string
	Label     string
}

var cfg *ssh_config.Config

func f(err error) {
	if err != nil {
		log.Fatal(err)
	}
}
func AppendToConfig(new_cfg string) error {
	f, err := os.OpenFile(get_ssh_config_path(), os.O_APPEND|os.O_WRONLY|os.O_CREATE, 0600)
	if err != nil {
		log.Fatal(err)
	}
	defer f.Close()
	if _, err = f.WriteString(fmt.Sprintf("\n%s\n", new_cfg)); err != nil {
		log.Fatal(err)
	}
	_cfg, err := parse_config()
	if err != nil {
		log.Fatal(err)
	}
	cfg = _cfg
	return nil
}

func ReConfig() string {
	c := fmt.Sprintf(`%s`, cfg)
	return c
}

func (l *LinodeVM) GetConfig() string {
	var config = fmt.Sprintf(`
Host %s
	Hostname         %s
	User             %s
	ControlPersist   3600
	ControlMaster    auto
	LogLevel         QUIET
	ForwardAgent     yes
	Compression      yes
	RequestTTY       force
	Port             22
	CheckHostIP      no
	StrictHostKeyChecking      no
`,
		l.Label,
		l.IP,
		DEV_USER,
	)
	return config
}

func (l *LinodeVM) IsConfigured() bool {
	hn, err := cfg.Get(l.Label, `Hostname`)
	f(err)
	return (hn == l.IP.String())
}

func privateIPCheck(ip string) bool {
	ipAddress := net.ParseIP(ip)
	return ipAddress.IsPrivate()
}
func get_ssh_config_path() string {
	return filepath.Join(os.Getenv("HOME"), ".ssh", "config")
}
func parse_config() (*ssh_config.Config, error) {
	f, err := os.Open(get_ssh_config_path())
	if err != nil {
		return &ssh_config.Config{}, err
	}
	cfg, err := ssh_config.Decode(f)
	if err != nil {
		return &ssh_config.Config{}, err
	}
	return cfg, nil
}

func main() {
	_cfg, err := parse_config()
	if err != nil {
		log.Fatal(err)
	}
	cfg = _cfg
	apiKey, ok := os.LookupEnv("LINODE_TOKEN")
	if !ok {
		log.Fatal("Could not find LINODE_TOKEN, please assert it is set.")
	}
	tokenSource := oauth2.StaticTokenSource(&oauth2.Token{AccessToken: apiKey})

	oauth2Client := &http.Client{
		Transport: &oauth2.Transport{
			Source: tokenSource,
		},
	}

	linodeClient := linodego.NewClient(oauth2Client)
	linodeClient.SetDebug(DEBUG_MODE)
	opts := linodego.NewListOptions(0, "")

	linodes, err := linodeClient.ListInstances(context.Background(), opts)
	if err != nil {
		log.Fatal(err)
	}
	for _, l := range linodes {
		if LINODE_LABEL_REGEX.MatchString(l.Label) {
			vm_labels = append(vm_labels, l.Label)
			lvm := LinodeVM{ID: l.ID, Region: l.Region, Image: l.Image, Type: l.Type, Hostname: fmt.Sprintf(`%s.%s`, l.Label, DEV_DOMAIN), Label: l.Label}
			for _, ip := range l.IPv4 {
				if !ip.IsPrivate() {
					lvm.IP = ip
				} else {
					lvm.PrivateIP = ip
				}
			}
			if !lvm.IsConfigured() {
				f(AppendToConfig(lvm.GetConfig()))
			}
		}
	}
}
