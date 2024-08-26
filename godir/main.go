package main

import (
	"encoding/xml"
	"flag"
	"fmt"
	"log"
	"log/slog"
	"net/http"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"time"

	"github.com/kouhin/envflag"
	sloghttp "github.com/samber/slog-http"
)

var (
	root = flag.String("root", ".", "root directory")
	port = flag.Int("port", 8080, "port number")
)

func main() {
	if err := envflag.Parse(); err != nil {
		panic(err)
	}
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))
	slog.SetDefault(logger)

	// TODO: Add a refresher to reload if the file has changed.
	path := filepath.Join(*root, "perl_mongers.xml")
	pmr := &PerlMongersReloading{path: path}

	var h http.Handler = &handler{pm: pmr}

	slogConfig := sloghttp.Config{
		WithUserAgent: true,
	}
	h = sloghttp.Recovery(h)
	h = sloghttp.NewWithConfig(logger, slogConfig)(h)

	http.Handle("/", h)

	slog.Info("Serving",
		"port", port)
	portStr := fmt.Sprintf(":%d", *port)
	log.Fatal(http.ListenAndServe(portStr, nil))

}

func readPerlMongers(filename string) (*PerlMongers, error) {
	// Open the XML file
	file, err := os.Open(filename)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	// Decode the XML data into a PerlMongers struct
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
	pm Grouper
}

var isLocalRegexp = regexp.MustCompile(`https?://\w+\.pm\.org/`)

func (h *handler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Server", "pmorg")
	sloghttp.AddCustomAttributes(r, slog.String("X-Forwarded-For", r.Header.Get("X-Forwarded-For")))
	dot := strings.Index(r.Host, ".")
	if dot == -1 {
		http.Error(w, "Bad Request", http.StatusBadRequest)
		return
	}

	g, err := h.pm.Group(r.Host[:dot])
	if err != nil {
		http.Error(w, "Not Found", http.StatusNotFound)
		return
	}

	if g.Status != "active" {
		http.Error(w, "Gone", http.StatusGone)
		return
	}

	if isLocalRegexp.MatchString(g.Web) {
		http.Error(w, "Misdirected Request", http.StatusMisdirectedRequest)
		return
	}
	http.Redirect(w, r, g.Web, http.StatusMovedPermanently)
}

type Grouper interface {
	Group(id string) (*Group, error)
}

type PerlMongersReloading struct {
	pm         *PerlMongers
	path       string
	lastUpdate time.Time
}

func (pmr *PerlMongersReloading) reload() error {
	slog.Info("Reloading PerlMongers",
		"path", pmr.path)
	pm, err := readPerlMongers(pmr.path)
	if err != nil {
		return err
	}
	pmr.pm = pm
	pmr.lastUpdate = time.Now()
	return nil
}

func (pmr *PerlMongersReloading) maybeReload() error {
	fi, err := os.Stat(pmr.path)
	if err != nil {
		return err
	}
	if fi == nil {
		return fmt.Errorf(pmr.path + " does not exist")
	}
	if fi.ModTime().After(pmr.lastUpdate) {
		return pmr.reload()
	}
	return nil
}

func (pmr *PerlMongersReloading) Group(id string) (*Group, error) {
	if err := pmr.maybeReload(); err != nil {
		log.Fatal(err)
	}
	return pmr.pm.Group(id)
}
