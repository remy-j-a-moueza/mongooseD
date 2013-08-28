// Copyright (c) 2013 Rémy Mouëza.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import std.conv; 
import std.stdio; 
import std.string;
public import mongoose_d;

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

class Connection {
    protected:
        mg_connection * con;
        mg_request_info * req_info;
        void [] outBuffer; 

    public:
        string [string] responseHeaders;
        string responseStatus;
        bool writeResponse; 

    public: 
        this (const(mg_connection)* con, bool writeResponse = false) {
            this (cast (mg_connection *) con, writeResponse);
        }

        this (mg_connection * con, bool writeResponse = false) {
            this.con = con;
            req_info = mg_get_request_info (con);

            this.writeResponse = writeResponse;
            this.responseStatus  = "200 OK"; 
            this.responseHeaders ["Content-Type"] = "text/html; charset=utf8";
        }

        mg_connection * getConnexion () {
            return con;
        }

        mg_request_info * getRequestInfo () {
            return req_info;
        }

        string method () {
            return req_info.request_method.to!string; 
        }
        
        string uri () {
            return req_info.uri.to!string; 
        }
        
        string httpVersion () {
            return req_info.http_version.to!string; 
        }
        
        string queryString () {
            return req_info.query_string.to!string; 
        }
        
        string remoteUser () {
            return req_info.remote_user.to!string; 
        }

        long remoteIp () {
            return req_info.remote_ip; 
        }
        
        int remotePort () {
            return req_info.remote_port; 
        }
        
        bool isSsl () {
            return req_info.is_ssl == 1; 
        }

        void * userData () {
            return req_info.user_data;
        }

        string [][] httpHeaders () {
            string [][] headers;

            foreach (int i; 0 .. req_info.num_headers) {
                mg_request_info.mg_header hd = req_info.http_headers [i]; 
                headers ~= [hd.name.to!string, hd.value.to!string];
            }

            return headers;
        }

        int write (void [] buf) {
            return mg_write (con, buf.ptr, buf.length);
        }

        int write (string msg) {
            return write (cast (void []) msg); 
        }

        void print (T) (T val) {
            this << val;
        }

        Connection opBinary (string op: "<<", T) (T val) {
            outBuffer ~= cast (void []) val.to!string;
            return this;
        }

        void response () {
            write ("HTTP/1.1 " ~ responseStatus ~ "\r\n"); 
            
            foreach (key, val; responseHeaders) {
                write (key ~ ": " ~ val ~ "\r\n"); 
            }

            write ("Content-Length: %d\r\n\r\n".format (outBuffer.length));
            write (outBuffer);
        }

        void sendFile (string path) {
            mg_send_file (con, path.toStringz);
        }

        void read (void *buf, size_t len) {
            mg_read (con, buf, len);
        }

        string getHeader (string name) {
            return mg_get_header (con, name.toStringz).to!string;
        }

        // TODO: mg_download, mg_close_connection, mg_upload. 
        //       Rework mg_read???

}



string getOption (mg_context * ctx, string name) {
    return mg_get_option (ctx, name.toStringz).to!string; 
}

string [] getValidOptionNames () {
    const(char*)* c_options = mg_get_valid_option_names ();
    string [] options; 

    for (const(char)* cstr = c_options [0]; cstr != null; cstr ++) {
        options ~= cstr.to!string; 
    }

    return options;
}

bool modifyPasswordFile (string passwordFileName, string domain, string user, string password) {
    return 0 < mg_modify_passwords_file (passwordFileName.toStringz, 
                                         domain.toStringz,
                                         user.toStringz,
                                         password.toStringz);
}

string getVar (string data, string name) {
    char * var_name = cast (char *) name.toStringz;
    char [] dest    = new char [32]; 
    char * destp    = cast (char *) dest; 
    int succ        = 0; 

    do {
        succ = mg_get_var (data.ptr, data.length, var_name, destp, dest.length);
        
        if (succ >= 0) {
            dest.length = succ; 
            return cast (string) dest; 
        }
        if (succ == -1) return "";
        
        // destination buffer too small.
        if (succ == -2) dest.length *= 2;

    } while (succ < 0); 

    return "";
}

string getCookie (string cookie, string name) {
    char [] dest    = new char [32]; 
    char *  destp   = cast (char *) dest; 
    int succ        = 0;
    
    do {
        succ = mg_get_cookie (cookie.toStringz, name.toStringz, destp, dest.length); 

        if (succ >= 0) {
            dest.length = succ; 
            return cast (string) dest; 
        }
            
        if (succ == -1) {
            return "";
        }

        if (succ == -2) {
            dest.length *= 2; 
        }

    } while (succ < 0);

    return "";
}

string getBuiltinMimeType (string filename) {
    return mg_get_builtin_mime_type (filename.toStringz).to!string;
}

string MongooseVersion () {
    return mg_version ().to!string;
}

string urlDecode (string src, bool isFormUrlEncoded = 0) {
    char [] dest = new char [32];
    char * destp = cast (char *) dest;

    int succ = 0;

    do {
        succ = mg_url_decode (src.toStringz, src.length, destp, dest.length, isFormUrlEncoded);

        if (succ >= 0) {
            dest.length = succ;
            return cast (string) dest; 
        }

        if (succ == -1) {
            dest.length *= 2;
        } else {
            break;
        }
    } while (succ == -1);

    return "";
}


char ** toMgStartOptions (string [string] options) {
    char * [] opts; 

    foreach (k, v; options) {
        opts ~= cast (char *) k;
        opts ~= cast (char *) v;
    }
    opts ~= null;

    return cast (char **) opts;
}

mg_context * start (ref mg_callbacks callbacks,
                    string [string] options) {
    return mg_start (&callbacks, 
                     null,
                     options.toMgStartOptions); 
}

mg_context * startWithData (T) (ref mg_callbacks callbacks, 
                                ref T user_data,
                                string [string] options) {

    return mg_start (&callbacks, 
                     user_data is null ? null : cast (void *) &user_data,
                     options.toMgStartOptions); 
}

void stop (mg_context * ctx) {
    mg_stop (ctx);
}

extern (C) {
    int d_begin_request (mg_connection* con) {
        auto cxn = new Connection (con, true);
        auto svr = cast (Server) cxn.userData;

        if (null == svr.onBegin)
            return 0;

        auto status = cast (int) svr.onBegin (cxn);

        if (cxn.writeResponse)
            cxn.response ();

        return status;
    }

    void d_end_request (const(mg_connection)* con, int status) {
        auto cxn = new Connection (con);
        auto svr = cast (Server) cxn.userData;

        if (null == svr.onEnd) return;

        svr.onEnd (new Connection (con), status);
    }

    int d_log_message (const(mg_connection)* con, const(char)* msg) {
        auto cxn = new Connection (con);
        auto svr = cast (Server) cxn.userData;

        if (null == svr.onLogMessage)
            return 0;
        return svr.onLogMessage (new Connection (con), msg.to!string); 
    }

    //int d_init_ssl (void* sslContext, void* userData) {
    //    auto cxn = new Connection (con);
    //    auto svr = cast (Server) cxn.userData;

    //    if (null == svr.onInitSsl)
    //        return 0;

    //    return svr.onInitSsl (sslContext, userData); 
    //}

    int d_websocket_connect (const(mg_connection)* con) {
        auto cxn = new Connection (con);
        auto svr = cast (Server) cxn.userData;

        if (null == svr.onWebsocketConnect) 
            return 1;

        return cast (int) ! svr.onWebsocketConnect (new Connection (con)); 
    }

    void d_websocket_ready (mg_connection* con) {
        auto cxn = new Connection (con);
        auto svr = cast (Server) cxn.userData;

        if (null == svr.onWebsocketReady) 
            return;

        svr.onWebsocketReady (new Connection (con));
    }

    int d_websocket_data (mg_connection* con, 
                        int bits, char* cdata, size_t dataLength) {
        auto cxn = new Connection (con, true);
        auto svr = cast (Server) cxn.userData;

        if (null == svr.onWebsocketReady) return 0;

        char [] data   = new char [dataLength];

        foreach (i; 0..dataLength) 
            data [i] = cdata [i];

        return cast (int) ! svr.onWebsocketData (new Connection (con), bits, data);
        
    }

    const(char)* d_open_file (const(mg_connection)* con, 
                            const(char)* path, size_t* dataLength) {
        auto cxn = new Connection (con, true);
        auto svr = cast (Server) cxn.userData;

        if (null == svr.onOpenFile)
            return null;
        
        size_t len  = *dataLength;
        auto   res  = svr.onOpenFile (new Connection (con), path.to!string, len); 
        *dataLength = len;
        
        return res.toStringz;
    }

    void d_init_lua (mg_connection* con, void* luaContext) {
        auto cxn = new Connection (con, true);
        auto svr = cast (Server) cxn.userData;

        if (null == svr.onInitLua)
            return;

        svr.onInitLua (new Connection (con), luaContext);
    }

    void d_upload (mg_connection* con, const(char)* fileName) {
        auto cxn = new Connection (con, true);
        auto svr = cast (Server) cxn.userData;

        if (null == svr.onUpload) 
            return;

        return svr.onUpload (new Connection (con), fileName.to!string);
    }
}

class Router {
protected:
    struct Route {
        string path;
        string flags;
    }
    void delegate (Connection) [Route][string] routes;

public:
    Router get (string route, void delegate (Connection) handler, string flags = "") {
        routes ["get"][Route (route, flags)] = handler;
        return this; 
    }

    Router post (string route, void delegate (Connection) handler, string flags = "") {
        routes ["post"][Route (route, flags)] = handler;
        return this;
    }
    
    Router any (string route, void delegate (Connection) handler, string flags = "") {
        routes ["any"][Route (route, flags)] = handler;
        return this; 
    }

    void delegate (Connection) match (Connection con) {
        import std.regex;

        foreach (method; ["post", "get", "any"]) {
            if (method !in routes) continue;

            foreach (route, dg ; routes [method]) {
                if (std.regex.match (con.uri, regex ("^(" ~ route.path ~ ")$", route.flags))) {
                    cout << "serving [" << route.path << ", " << route.flags << "] "
                         << "from \"" << con.uri << "\"\n";
                    return dg;
                }
            }
        }
        return null;
    }

    bool route (Connection con) {
        auto dg = match (con); 
        
        if (dg != null) {
            dg (con); 
            return true;
        }
        return false;
    }
}

class Server {
    mg_context * context; 

protected:
public: 
    string [string] options;

    bool    delegate (Connection)             onBegin;
    void    delegate (Connection, int status) onEnd; 
	int     delegate (Connection, string)     onLogMessage;
	int     delegate (void*, void*)           onInitSsl;
	bool    delegate (Connection)             onWebsocketConnect;
	void    delegate (Connection)             onWebsocketReady;
	bool    delegate (Connection, int, char[])  onWebsocketData;
	string  delegate (Connection, string, ref size_t)  onOpenFile;
	void    delegate (Connection, void*)               onInitLua;
	void    delegate (Connection, string)      onUpload;
	int     delegate (Connection, int)         onHttpError;
    
    this (string [string] options) {
        this.options = options;
    }

    void stop () {
        mg_stop (context);
    }

    void start () {
        mg_callbacks callbacks; 
        with (callbacks) {
            begin_request     = & d_begin_request;
            end_request       = & d_end_request;
            log_message       = & d_log_message;
            //init_ssl          = & d_init_ssl;
            websocket_connect = & d_websocket_connect;
            websocket_ready   = & d_websocket_ready;
            websocket_data    = & d_websocket_data;
            open_file         = & d_open_file;
            init_lua          = & d_init_lua;
            upload            = & d_upload;
            thread_start      = null;
            thread_stop       = null;
        }

        context = mg_start (&callbacks, cast (void *) this, options.toMgStartOptions);
    }
}
