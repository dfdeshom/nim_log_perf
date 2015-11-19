import uri2
import tables
import strutils
import cgi
import times
import json
import sets
import re
import marshal

type
  DisplayInfo = object
    total_width: string
    total_height: string
    available_width: string
    available_height: string
    pixel_depth: string

  SessionInfo = object
    id: string
    timestamp: string
    initial_url: string
    initial_referrer: string
    last_session_timestamp: int64

  TimestampInfo = object
    nginx: string
    pixel: string
    override_ms: BiggestInt

  VisitorInfo = object
    site_id: string
    network_id: string
    ip: string
    
  LogLine = object
    display_info: DisplayInfo
    session_info: SessionInfo
    ts_info: TimestampInfo
    visitor_info: VisitorInfo
    
proc parse_query_args(req:string): Table[string,string] =
  let uri: URI2 = uri2.parseURI2(req)
  let queries : seq[seq[string]] = uri.getAllQueries()
  let ignore = ["h", "m", "s", "java", "qt", "ag", "fla",
                "gears", "pdf", "realp", "wma", "dir"]
  
  var res = initTable[string, string]()
  for i in queries:
    var k:string = i[0]
    if ignore.contains(k):
      continue
    else:
      if k.toLower() == "rand":
        k = "tms"  # timestamp in milliseconds
    res.add(k,decodeUrl(i[1]))
    
  result = res

proc parse_data(json_string:string): Table[string,string] =
  var data:Table[string,string] = initTable[string, string]()
  try:
    let j = parseJson(json_string)
    for k,v in j.pairs():
      data.add(k,v.str)
  except:
    echo("")
  result = data

proc parse_resolution(resolution:string): seq[string] =
  discard """resoultion looks like: '323x323' """
  var sp = resolution.split("x")
  result = sp

proc parse_display(parsed:Table[string,string]): DisplayInfo =
  # resolution string looks like: "1024x768|1024x738|24"
  var res = DisplayInfo() #initTable[string, string]() 

  var info = parsed.getOrDefault("res")
  if info.len==0:
    info = parsed.getOrDefault("screen")
    
  if info.len==0:
    result = res
    return

  let resolutions = info.split("|")
  # total
  let total_stats = parse_resolution(resolutions[0])
  res.total_width = total_stats[0]
  res.total_height=total_stats[1]

  # available
  let available_stats = parse_resolution(resolutions[1])
  res.available_width=available_stats[0]
  res.available_height=available_stats[1]

  # pixel depth
  res.pixel_depth=resolutions[2]
  result = res

proc parse_session(parts:seq[string],parsed:Table[string,string]): SessionInfo =
  let sid = parsed.getOrDefault("sid")
  if not isDigit(sid):
    return

  let sts = parsed.getOrDefault("sts")
  if not isDigit(sts):
    return

  let slts = parsed.getOrDefault("slts")
  if not isDigit(slts):
    return

  let surl = parsed.getOrDefault("surl")
  if not isDigit(surl):
    return

  let sref = parsed.getOrDefault("sref")

  result.id=sid
  result.timestamp=sts
  result.initial_url=surl
  result.initial_referrer=sref
  result.last_session_timestamp=parseBiggestInt(slts)

proc parse_timestamp(parts:seq[string],
                     parsed:Table[string,string],
                     data:Table[string,string]): TimestampInfo =
  const JAN_2000_UNIX_MS = 946702800000  # Jan 1, 2000 in milliseconds since Unix epoch
  let pixel = parsed.getOrDefault("rand")
  var pixel_ms = 0
  var override:BiggestInt = 0
  
  if pixel.len>0:
    try:
      pixel_ms = toInt(parseFloat(pixel))
    except:
      pixel_ms = 0

  # The ts override can be in seconds or milliseconds.
  var ts = parseBiggestInt(data.getOrDefault("ts"))
  if ts < JAN_2000_UNIX_MS:
      ts *= 1000
  else:
    override = ts
  
proc parse_log_line(): Logline =
  var line: string = """/plogger/ || 50.73.113.242 || - || 21/Mar/2013:13:22:13 +0000  || GET /plogger/?rand=1363872131875&idsite=deadspin.com&url=http%3A%2F%2Fdeadspin.com%2Frecommended&urlref=http%3A%2F%2Fdeadspin.com%2F&screen=1024x768%7C1024x738%7C24&data=%7B%22parsely_uuid%22%3A%22908932BF-0935-46AD-84BD-10120D5297CA%22%2C%22parsely_site_uuid%22%3A%22908932BF-0935-46AD-84BD-10120D5297CA%22%7D&title=Deadspin+-+Sports+News+without+Access%2C+Favor%2C+or+Discretion&date=Thu+Mar+21+2013+08%3A22%3A11+GMT-0500+(Central+Daylight+Time)&action=pageview HTTP/1.1 || 200 || 363 || - || Mozilla/5.0 (Windows NT 5.1; rv:19.0) Gecko/20100101 Firefox/19.0" || - || - || parsely_network_uuid=CrMHN1FLCYUJWgTmkT47Ag==; expires=Thu, 31-Dec-37 23:55:55 GMT; domain=track.parse.ly; path=/ || 0.000"""  
  let parts: seq[string] = line.split(" || ")
  let parsed_request: Table[string,string] = parse_query_args(parts[4].split(' ')[1])
  #var res = initTable[string, string]()
  var data = parse_data(parsed_request.getOrDefault("data"))

  echo($data)
  echo($parsed_request)
  
  result.display_info = parse_display(parsed_request)
  result.session_info = parse_session(parts,parsed_request)
  
  echo($$result)
  #echo($display)
  
discard parse_log_line()
