package main

import (
	"encoding/xml"
	"flag"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"sync"
	"time"

	"github.com/kouhin/envflag"
	"go.ntppool.org/common/logger"
)

var (
	root = flag.String("root", ".", "root directory")
	port = flag.Int("port", 8080, "port number")
)

const reloadCooldown = 30 * time.Second

func main() {
	if err := envflag.Parse(); err != nil {
		panic(err)
	}

	log := logger.Setup()

	path := filepath.Join(*root, "perl_mongers.xml")
	pmr := &PerlMongersReloading{path: path}

	// Initial load
	if err := pmr.reload(); err != nil {
		log.Error("failed to load perl_mongers.xml", "error", err)
		os.Exit(1)
	}

	mux := http.NewServeMux()
	mux.Handle("/", &handler{pm: pmr, log: log})
	mux.HandleFunc("/health", healthHandler)

	log.Info("Serving", "port", *port)
	portStr := fmt.Sprintf(":%d", *port)
	if err := http.ListenAndServe(portStr, mux); err != nil {
		log.Error("server error", "error", err)
		os.Exit(1)
	}
}

func healthHandler(w http.ResponseWriter, _ *http.Request) {
	w.Header().Set("Content-Type", "text/plain")
	w.WriteHeader(http.StatusOK)
	_, _ = io.WriteString(w, "ok")
}

func readPerlMongers(filename string) (*PerlMongers, error) {
	file, err := os.Open(filename)
	if err != nil {
		return nil, err
	}
	defer func() { _ = file.Close() }()

	var pm PerlMongers
	decoder := xml.NewDecoder(file)
	err = decoder.Decode(&pm)
	if err != nil {
		return nil, err
	}

	return &pm, nil
}

type PerlMongers struct {
	Groups []Group `xml:"group"`
}

type Group struct {
	ID           string        `xml:"id,attr"`
	Status       string        `xml:"status,attr"`
	Name         string        `xml:"name"`
	Location     Location      `xml:"location"`
	Emails       []Email       `xml:"email"`
	Tsars        []Tsar        `xml:"tsar"`
	Web          string        `xml:"web"`
	MailingLists []MailingList `xml:"mailing_list"`
	Dates        []Date        `xml:"date"`
	Comment      string        `xml:",comment"`
}

type Location struct {
	City      string `xml:"city"`
	State     string `xml:"state"`
	Region    string `xml:"region"`
	Country   string `xml:"country"`
	Continent string `xml:"continent"`
	Longitude string `xml:"longitude"`
	Latitude  string `xml:"latitude"`
}

type Tsar struct {
	Name  string `xml:"name"`
	Email string `xml:"email"`
}

type MailingList struct {
	Name        string   `xml:"name"`
	Emails      []string `xml:"email"`
	Subscribe   string   `xml:"subscribe"`
	Unsubscribe string   `xml:"unsubscribe"`
}

type Date struct {
	Type string `xml:"type,attr"`
	Text string `xml:",chardata"`
}

type Email struct {
	Type string `xml:"type,attr"`
	Text string `xml:",chardata"`
}

func (pm PerlMongers) Group(id string) (*Group, error) {
	if !strings.HasSuffix(id, ".pm") {
		id = id + ".pm"
	}
	for _, group := range pm.Groups {
		if strings.EqualFold(group.Name, id) {
			return &group, nil
		}
	}
	return nil, fmt.Errorf("Group %s not found", id)
}

type handler struct {
	pm  Grouper
	log *slog.Logger
}

var isLocalRegexp = regexp.MustCompile(`https?://\w+\.pm\.org/`)

func (h *handler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Server", "pmorg")

	log := h.log.With(
		"method", r.Method,
		"host", r.Host,
		"path", r.URL.Path,
		"remote", r.RemoteAddr,
		"x-forwarded-for", r.Header.Get("X-Forwarded-For"),
	)

	dot := strings.Index(r.Host, ".")
	if dot == -1 {
		log.Warn("bad request: no dot in host")
		http.Error(w, "Bad Request", http.StatusBadRequest)
		return
	}

	groupName := r.Host[:dot]
	g, err := h.pm.Group(groupName)
	if err != nil {
		log.Info("group not found", "group", groupName)
		http.Error(w, "Not Found", http.StatusNotFound)
		return
	}

	if g.Status != "active" {
		log.Info("group not active", "group", groupName, "status", g.Status)
		http.Error(w, "Gone", http.StatusGone)
		return
	}

	if isLocalRegexp.MatchString(g.Web) {
		log.Warn("misdirected request: web URL points to pm.org", "group", groupName, "web", g.Web)
		http.Error(w, "Misdirected Request", http.StatusMisdirectedRequest)
		return
	}

	log.Info("redirecting", "group", groupName, "target", g.Web)
	http.Redirect(w, r, g.Web, http.StatusMovedPermanently)
}

type Grouper interface {
	Group(id string) (*Group, error)
}

type PerlMongersReloading struct {
	mu         sync.RWMutex
	pm         *PerlMongers
	path       string
	lastUpdate time.Time
	lastCheck  time.Time
}

// reload updates the perl mongers data from disk.
// Must be called with pmr.mu held.
func (pmr *PerlMongersReloading) reload() error {
	slog.Info("Reloading PerlMongers", "path", pmr.path)
	pm, err := readPerlMongers(pmr.path)
	if err != nil {
		return err
	}
	pmr.pm = pm
	pmr.lastUpdate = time.Now()
	return nil
}

// maybeReload checks if the XML file has been modified and reloads if needed.
// Must be called with pmr.mu held.
func (pmr *PerlMongersReloading) maybeReload() error {
	now := time.Now()

	// Check if cooldown has elapsed since last check
	if now.Sub(pmr.lastCheck) < reloadCooldown {
		return nil
	}
	pmr.lastCheck = now

	fi, err := os.Stat(pmr.path)
	if err != nil {
		return err
	}
	if fi.ModTime().After(pmr.lastUpdate) {
		return pmr.reload()
	}
	return nil
}

func (pmr *PerlMongersReloading) Group(id string) (*Group, error) {
	pmr.mu.Lock()
	defer pmr.mu.Unlock()

	err := pmr.maybeReload()
	if err != nil {
		slog.Warn("failed to reload perl_mongers.xml, serving stale data", "error", err)
	}

	if pmr.pm == nil {
		return nil, fmt.Errorf("perl_mongers.xml not loaded")
	}
	return pmr.pm.Group(id)
}
