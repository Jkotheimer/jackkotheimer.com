/**
 * This server script is purely for testing purposes
 */
var http = require('http');
var fs = require('fs');
var path = require('path');

http.createServer(function (req, res) {
	var filepath;
	if(req.url.includes(".")) {
		filepath = path.join('www', req.url);
	} else {
		filepath = path.join('www', req.url, 'index.html');
	}

	fs.readFile(filepath, function(err, data) {
		if(err) {
			res.writeHead(404, {'Content-Type' : 'text/html'});
			res.write('<html><body><h1>404 Page not found</h1></body></html>');
			res.end();
		}
		else {
			res.writeHead(200);
			res.write(data);
			res.end();
		}
	});
}).listen(5000);

console.log('Node.js web server at port 5000 is running...')
