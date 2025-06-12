# Ruby Sinatra Todo HTTP Server 🚀

A single-file, in-memory RESTful API written in Ruby using Sinatra.  
Features health, version, metrics, request logging, and graceful shutdown.

**File:** `app.rb`  
**Author:** [bocaletto-luca](https://github.com/bocaletto-luca)  
**License:** MIT

---

## 📦 Installation & Run

##bash
  
    # Install dependencies
    gem install sinatra json

    # Run server (default port 4567)
    ruby app.rb

    # Or specify port
    ruby app.rb --port 9090

🛠️ Features

    In-memory store (no external DB)

    Thread-safe using Mutex

    Automatic JSON parsing and encoding

    Request logging by Sinatra

    Basic metrics: total requests & todos count

    Graceful shutdown on CTRL-C
