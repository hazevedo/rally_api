#Custom headers
headers = RallyAPI::CustomHttpHeader.new()
headers.name    = "Rally Software Development Corp"
headers.vendor  = "Rally"
headers.version = "1.00"

# Config parameters
@config = {}
@config[:version]   = "1.42"        # If not set, will use default version defined in gem.
@config[:headers]   = headers

