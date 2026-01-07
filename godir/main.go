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
	"runtime/debug"
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
	pmr := &PerlMongersReloading{path: path, log: log}

	// Initial load
	pmr.mu.Lock()
	if err := pmr.reload(); err != nil {
		pmr.mu.Unlock()
		log.Error("failed to load perl_mongers.xml", "error", err)
		os.Exit(1)
	}
	pmr.mu.Unlock()

	mux := http.NewServeMux()
	mux.Handle("/", recoveryMiddleware(&handler{pm: pmr, log: log}, log))
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

func recoveryMiddleware(next http.Handler, log *slog.Logger) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		defer func() {
			if err := recover(); err != nil {
				log.Error("panic recovered", "error", err, "path", r.URL.Path, "stack", string(debug.Stack()))
				http.Error(w, "Internal Server Error", http.StatusInternalServerError)
			}
		}()
		next.ServeHTTP(w, r)
	})
}

func readPerlMongers(filename string) (*PerlMongers, error) {
	file, err := os.Open(filename)
	if err != nil {
		return nil, err
	}
	defer file.Close()

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

var isLocalRegexp = regexp.MustCompile(`^https?://\w+\.pm\.org(/|$)`)

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
	log        *slog.Logger
}

// reload updates the perl mongers data from disk.
// Called during initial load (before server starts) and from Group (with pmr.mu held).
func (pmr *PerlMongersReloading) reload() error {
	pmr.log.Info("reloading PerlMongers", "path", pmr.path)
	pm, err := readPerlMongers(pmr.path)
	if err != nil {
		return err
	}
	pmr.pm = pm
	pmr.lastUpdate = time.Now()
	return nil
}

func (pmr *PerlMongersReloading) Group(id string) (*Group, error) {
	now := time.Now()

	// Fast path: RLock to check cooldown and get pm reference
	pmr.mu.RLock()
	needCheck := now.Sub(pmr.lastCheck) >= reloadCooldown
	pm := pmr.pm
	pmr.mu.RUnlock()

	if needCheck {
		// Slow path: upgrade to write lock for potential reload
		pmr.mu.Lock()
		// Double-check after acquiring write lock
		if now.Sub(pmr.lastCheck) >= reloadCooldown {
			pmr.lastCheck = now
			fi, err := os.Stat(pmr.path)
			if err != nil {
				pmr.log.Warn("failed to stat perl_mongers.xml, serving cached data", "error", err)
			} else if fi.ModTime().After(pmr.lastUpdate) {
				if err := pmr.reload(); err != nil {
					pmr.log.Warn("failed to reload perl_mongers.xml, serving stale data", "error", err)
				}
			}
		}
		pm = pmr.pm
		pmr.mu.Unlock()
	}

	if pm == nil {
		return nil, fmt.Errorf("perl_mongers.xml not loaded")
	}
	return pm.Group(id)
}
