local http = require("ssl.https")

local url = "https://raw.githubusercontent.com/mc-cc-scripts/script-manager/master/README.md"

local res, code, headers, status = http.request(url)

print(res, code, headers, status)
