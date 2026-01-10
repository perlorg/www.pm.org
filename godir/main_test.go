package main

import (
	"io"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"testing"
)

// testLogger returns a logger that discards output for tests
func testLogger() *slog.Logger {
	return slog.New(slog.NewTextHandler(io.Discard, nil))
}

func TestHealthEndpoint(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/health", nil)
	w := httptest.NewRecorder()

	healthHandler(w, req)

	if w.Code != http.StatusOK {
		t.Errorf("expected status 200, got %d", w.Code)
	}
	if w.Body.String() != "ok" {
		t.Errorf("expected body 'ok', got %q", w.Body.String())
	}
}

func TestXMLLoading(t *testing.T) {
	pm, err := readPerlMongers("../perl_mongers.xml")
	if err != nil {
		t.Fatalf("failed to load perl_mongers.xml: %v", err)
	}
	if len(pm.Groups) == 0 {
		t.Error("expected at least one group")
	}
}

func TestHandlerActiveGroupRedirect(t *testing.T) {
	pm, err := readPerlMongers("../perl_mongers.xml")
	if err != nil {
		t.Fatalf("failed to load perl_mongers.xml: %v", err)
	}

	// Find a few active groups to test
	var activeGroups []Group
	for _, g := range pm.Groups {
		if g.Status == "active" && g.Web != "" && !isLocalRegexp.MatchString(g.Web) {
			activeGroups = append(activeGroups, g)
			if len(activeGroups) >= 3 {
				break
			}
		}
	}

	if len(activeGroups) == 0 {
		t.Fatal("no active groups with non-pm.org web URLs found")
	}

	h := &handler{pm: pm, log: testLogger()}

	for _, g := range activeGroups {
		t.Run(g.Name, func(t *testing.T) {
			// Extract subdomain from group name (e.g., "NY.pm" -> "ny")
			subdomain := g.Name
			if len(subdomain) > 3 && subdomain[len(subdomain)-3:] == ".pm" {
				subdomain = subdomain[:len(subdomain)-3]
			}

			req := httptest.NewRequest(http.MethodGet, "/", nil)
			req.Host = subdomain + ".pm.org"
			w := httptest.NewRecorder()

			h.ServeHTTP(w, req)

			if w.Code != http.StatusMovedPermanently {
				t.Errorf("expected status 301, got %d", w.Code)
			}
			location := w.Header().Get("Location")
			if location != g.Web {
				t.Errorf("expected redirect to %q, got %q", g.Web, location)
			}
		})
	}
}

func TestHandlerUnknownGroup(t *testing.T) {
	pm, err := readPerlMongers("../perl_mongers.xml")
	if err != nil {
		t.Fatalf("failed to load perl_mongers.xml: %v", err)
	}

	h := &handler{pm: pm, log: testLogger()}

	req := httptest.NewRequest(http.MethodGet, "/", nil)
	req.Host = "nonexistent-group-xyz.pm.org"
	w := httptest.NewRecorder()

	h.ServeHTTP(w, req)

	if w.Code != http.StatusNotFound {
		t.Errorf("expected status 404, got %d", w.Code)
	}
}

func TestHandlerInactiveGroup(t *testing.T) {
	pm, err := readPerlMongers("../perl_mongers.xml")
	if err != nil {
		t.Fatalf("failed to load perl_mongers.xml: %v", err)
	}

	// Find an inactive group
	var inactiveGroup Group
	found := false
	for _, g := range pm.Groups {
		if g.Status == "inactive" {
			inactiveGroup = g
			found = true
			break
		}
	}

	if !found {
		t.Skip("no inactive groups found")
	}

	h := &handler{pm: pm, log: testLogger()}

	subdomain := inactiveGroup.Name
	if len(subdomain) > 3 && subdomain[len(subdomain)-3:] == ".pm" {
		subdomain = subdomain[:len(subdomain)-3]
	}

	req := httptest.NewRequest(http.MethodGet, "/", nil)
	req.Host = subdomain + ".pm.org"
	w := httptest.NewRecorder()

	h.ServeHTTP(w, req)

	if w.Code != http.StatusGone {
		t.Errorf("expected status 410 Gone, got %d", w.Code)
	}
}

func TestHandlerMisdirectedRequest(t *testing.T) {
	pm, err := readPerlMongers("../perl_mongers.xml")
	if err != nil {
		t.Fatalf("failed to load perl_mongers.xml: %v", err)
	}

	h := &handler{pm: pm, log: testLogger()}

	// Test the zztestloop.pm group which has a pm.org URL
	req := httptest.NewRequest(http.MethodGet, "/", nil)
	req.Host = "zztestloop.pm.org"
	w := httptest.NewRecorder()

	h.ServeHTTP(w, req)

	if w.Code != http.StatusMisdirectedRequest {
		t.Errorf("expected status 421 Misdirected Request, got %d", w.Code)
	}
}

func TestHandlerBadRequest(t *testing.T) {
	pm, err := readPerlMongers("../perl_mongers.xml")
	if err != nil {
		t.Fatalf("failed to load perl_mongers.xml: %v", err)
	}

	h := &handler{pm: pm, log: testLogger()}

	req := httptest.NewRequest(http.MethodGet, "/", nil)
	req.Host = "nodotinhost"
	w := httptest.NewRecorder()

	h.ServeHTTP(w, req)

	if w.Code != http.StatusBadRequest {
		t.Errorf("expected status 400, got %d", w.Code)
	}
}
