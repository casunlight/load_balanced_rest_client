package main

import (
	"flag"
	"fmt"
	"log"
	"net"
	"net/http"
	"strconv"
	"sync"
)

var (
	err          error
	port         int
	listen_addr  string
	conn_counter int
	max_conn     int
	listener     net.Listener
)

type handler struct {
	*http.ServeMux
	w sync.WaitGroup
}

func init() {
	flag.IntVar(&port, "p", 8080, "Port to listen on")
	flag.IntVar(&max_conn, "m", 4, "Max connections to ever accept")
	flag.Parse()

	listen_addr = fmt.Sprintf(":%s", strconv.Itoa(port))
	conn_counter = 0
}

func main() {
	listener, err = net.Listen("tcp", listen_addr)
	if err != nil {
		panic(err)
	}

	log.Printf("Server is listening on port %d and will handle %d connections before dying", port, max_conn)

	handler := &handler{ServeMux: http.NewServeMux()}
	handler.ServeMux.HandleFunc("/favicon.ico", http.NotFound)
	handler.ServeMux.HandleFunc("/", closeHandler)

	http.Serve(listener, handler)
	handler.w.Wait()
}

func (h *handler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	defer h.w.Done()

	h.w.Add(1)
	h.ServeMux.ServeHTTP(w, r)
	w.(http.Flusher).Flush()
}

func closeHandler(w http.ResponseWriter, r *http.Request) {
	conn_counter++

	if conn_counter == max_conn {
		listener.Close()
		log.Printf("Server has died")
		fmt.Fprintf(w, "Server has died")
	} else {
		log.Printf("Server has %d connections left", max_conn-conn_counter)
		fmt.Fprintf(w, "Server has %d connections left", max_conn-conn_counter)
	}
}
