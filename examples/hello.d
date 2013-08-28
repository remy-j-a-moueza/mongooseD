import std.stdio; 
import core.stdc.config;
import std.string;
import dmongoose;

private {
    struct Cout {
        Cout opBinary (string op: "<<", T) (T val) {
            write (val); 
            return this; 
        }
    }
    Cout cout; 
    immutable string endl = "\n";

    string repeat (string s, int n) {
        string v = ""; 
        foreach (times; 1..n) v ~= s; 
        return v;
    }
}

void main () {

    auto router = new Router; 
    auto     nl = "\n";

    router.get ("/index.html|/", (Connection con) {
        con << `
            <html>
                <body style="margin-left: auto; margin-right: auto; width: 67%;">
                    <h1> Welcome To Mongoose </h1>

                    <p style="margin-top: 2em;">
                        This is served in D using Mongoose as the HTTP server.
                    </p>

                    <p>
                        Click <a href="hello">here</a> to get infos.
                    </p>
                </body>
            </html>

        `; 
    }); 
    
    router.get ("/hello", (Connection con) {
        cout << "within the handler" << endl;
        con.responseHeaders ["Content-Type"] = "text/plain";
        con << "Hello from mongoose! Remote port: %d\n".format (con.remotePort)
            << "\n\n\n"
            << "method: " << con.method << nl
            << "query string: " << con.queryString << nl
            << "uri: " << con.uri << nl
            << "HTTP headers: " << con.httpHeaders () << nl;
    });
    
    auto server = new Server (["listening_ports": "8080"]);
    server.onBegin = &router.route;

    server.start ();
    
    import std.process;
    browse ("http://localhost:8080/"); 
    
    getchar ();
    server.stop ();
}

