package main

import (
	"bytes"
	"cmp"
	"fmt"
	"log/slog"
	"net"
	"net/mail"
	"os"

	_ "github.com/joho/godotenv/autoload"
	"github.com/mhale/smtpd"
)

var (
	PORT = os.Getenv("SMTP_PORT")
)

// mailHandler is a simple SMTP server handler that prints the subject of the
func mailHandler(origin net.Addr, from string, to []string, data []byte) error {
	msg, _ := mail.ReadMessage(bytes.NewReader(data))
	subject := msg.Header.Get("Subject")

	slog.Info("Received mail", "from: ", from, "to: ", to[0], "with subject: ", subject)
	return nil
}

// listenAndServe starts a new SMTP server listening on the given address.
func listenAndServe(addr string, handler smtpd.Handler, authHandler smtpd.AuthHandler) error {
	mechs := map[string]bool{"PLAIN": true}

	srv := &smtpd.Server{
		Addr:         addr,
		Handler:      handler,
		Appname:      "my-server",
		Hostname:     "",
		AuthHandler:  authHandler,
		AuthRequired: true,
		AuthMechs:    mechs,
	}

	return srv.ListenAndServe()
}

func authHandler(remoteAddr net.Addr, mechanism string, username, password, shared []byte) (bool, error) {

	return true, nil
}

func main() {
	port := cmp.Or(PORT, "2525")

	slog.Info("Starting server on", "port", port)

	err := listenAndServe(fmt.Sprintf(":%s", port), mailHandler, authHandler)

	if err != nil {
		slog.Error("Error starting", "error", err)
		os.Exit(1)
	}
}
