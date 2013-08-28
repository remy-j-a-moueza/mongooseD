// Copyright (c) 2004-2012 Sergey Lyubka
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

import core.stdc.config;

extern (C):

alias void* function (void*) mg_thread_func_t;

struct mg_context
{
}

struct mg_connection
{
}

struct mg_request_info
{
	const(char)* request_method;
	const(char)* uri;
	const(char)* http_version;
	const(char)* query_string;
	const(char)* remote_user;
	c_long remote_ip;
	int remote_port;
	int is_ssl;
	void* user_data;
	int num_headers;

    struct mg_header {
        const(char)* name;   
        const(char)* value;
    }
	mg_header[64] http_headers;
}

struct mg_callbacks
{
	int           function (mg_connection*) begin_request;
	void          function (const(mg_connection)*, int) end_request;
	int           function (const(mg_connection)*, const(char)*) log_message;
	int           function (void*, void*) init_ssl;
	int           function (const(mg_connection)*) websocket_connect;
	void          function (mg_connection*) websocket_ready;
	int           function (mg_connection*, int, char*, size_t) websocket_data;
	const(char)*  function (const(mg_connection)*, const(char)*, size_t*) open_file;
	void          function (mg_connection*, void*) init_lua;
	void          function (mg_connection*, const(char)*) upload;
	int           function (mg_connection*, int) http_error;
}


mg_context* mg_start (const(mg_callbacks)* callbacks, void* user_data, const(char*)* configuration_options);
void mg_stop (mg_context*);
const(char)* mg_get_option (const(mg_context)* ctx, const(char)* name);
const(char*)* mg_get_valid_option_names ();
int mg_modify_passwords_file (const(char)* passwords_file_name, const(char)* domain, const(char)* user, const(char)* password);
mg_request_info* mg_get_request_info (mg_connection*);
int mg_write (mg_connection*, const(void)* buf, size_t len);
int mg_printf (mg_connection*, const(char)* fmt, ...);
void mg_send_file (mg_connection* conn, const(char)* path);
int mg_read (mg_connection*, void* buf, size_t len);
const(char)* mg_get_header (const(mg_connection)*, const(char)* name);
int mg_get_var (const(char)* data, size_t data_len, const(char)* var_name, char* dst, size_t dst_len);
int mg_get_cookie (const(char)* cookie, const(char)* var_name, char* buf, size_t buf_len);
mg_connection* mg_download (const(char)* host, int port, int use_ssl, char* error_buffer, size_t error_buffer_size, const(char)* request_fmt, ...);
void mg_close_connection (mg_connection* conn);
int mg_upload (mg_connection* conn, const(char)* destination_dir);
int mg_start_thread (mg_thread_func_t f, void* p);
const(char)* mg_get_builtin_mime_type (const(char)* file_name);
const(char)* mg_version ();
int mg_url_decode (const(char)* src, int src_len, char* dst, int dst_len, int is_form_url_encoded);
char* mg_md5 (char* buf, ...);
