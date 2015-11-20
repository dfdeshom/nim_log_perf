import uri2
import tables
import strutils
import cgi
import times
import json
import sets
import re
import marshal
import times

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
    nginx_ms: int64
    pixel_ms: int64
    override_ms: int64

  VisitorInfo = object
    site_id: string
    network_id: string
    ip: string
    
  LogLine = object
    display_info: DisplayInfo
    session_info: SessionInfo
    timestamp_info: TimestampInfo
    visitor_info: VisitorInfo
    apikey: string
    url: string
    referrer: string
    action: string
    engaged_time_inc: int
    extra_data: Table[string,string]
    user_agent: string
    
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
  var data:Table[string,string] = initTable[string, string](8)
  try:
    let j = parseJson(json_string)
    for k,v in j.pairs():
      data.add(k,v.str)
  except:
    echo("")
  result = data

proc parse_resolution(resolution:string): seq[string] =
  discard """resoultion looks like: '323x323' """
  result = resolution.split("x")
  
proc parse_display(parsed:Table[string,string]): DisplayInfo =
  # resolution string looks like: "1024x768|1024x738|24"
  
  var info = parsed.getOrDefault("res")
  if info.len==0:
    info = parsed.getOrDefault("screen")
    
  if info.len==0:
    return

  let resolutions = info.split("|")
  # total
  let total_stats = parse_resolution(resolutions[0])
  result.total_width = total_stats[0]
  result.total_height=total_stats[1]

  # available
  let available_stats = parse_resolution(resolutions[1])
  result.available_width=available_stats[0]
  result.available_height=available_stats[1]

  # pixel depth
  result.pixel_depth=resolutions[2]
    
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
  const JAN_2000_UNIX_MS = 946702800000  # Jan 1, 2000 in milliseconds 
  var nginx_timeinfo = parse(parts[3].split(' ')[0],"%d/%b/%Y:%H:%M:%S")
  var nginx_ms = toSeconds(timeInfoToTime(nginx_timeinfo))*1000
    
  let pixel = parsed.getOrDefault("rand")
  var pixel_ms = 0
  var override:BiggestInt = 0
  
  if pixel.len>0:
    try:
      pixel_ms = toInt(parseFloat(pixel))
    except:
      pixel_ms = 0

  # The ts override can be in seconds or milliseconds.
  var ts = 0
  var ts_val = data.getOrDefault("ts")
  if ts_val.len==0:
    ts = 0
  else:
    ts = parseInt(ts_val)
  if ts < JAN_2000_UNIX_MS:
      ts *= 1000
  else:
    override = ts

  result.nginx_ms = toInt(nginx_ms)
  result.pixel_ms = pixel_ms
  result.override_ms = override


proc parse_visitor_info(parts:seq[string],
                        parsed:Table[string,string],
                        data:Table[string,string]): VisitorInfo =
    
  result.site_id = data.getOrDefault("parsely_site_uuid") 
  result.network_id = data.getOrDefault("parsely_uuid")
  result.ip = parts[1]
  
proc parse_log_line(line:string): Logline =
  let parts: seq[string] = line.split(" || ")
  let parsed: Table[string,string] = parse_query_args(parts[4].split(' ')[1])
  let data = parse_data(parsed.getOrDefault("data"))
  
  echo($parsed)

  result.display_info = parse_display(parsed)
  result.session_info = parse_session(parts,parsed)
  result.timestamp_info = parse_timestamp(parts,parsed,data)
  result.visitor_info = parse_visitor_info(parts,parsed,data)

  result.apikey = parsed.getOrDefault("idsite")
  result.url = parsed.getOrDefault("url")
  result.referrer = parsed.getOrDefault("urlref")
  result.action = parsed.getOrDefault("action")

  let et_inc = parsed.getOrDefault("inc")
  var inc = 0
  if et_inc.len != 0:
    inc = parseInt(et_inc)

  result.engaged_time_inc = inc
  result.extra_data = data
  result.user_agent = parts[8]
#var line: string = """/plogger/ || 50.73.113.242 || - || 21/Mar/2013:13:22:13 +0000  || GET /plogger/?rand=1363872131875&idsite=deadspin.com&url=http%3A%2F%2Fdeadspin.com%2Frecommended&urlref=http%3A%2F%2Fdeadspin.com%2F&screen=1024x768%7C1024x738%7C24&data=%7B%22parsely_uuid%22%3A%22908932BF-0935-46AD-84BD-10120D5297CA%22%2C%22parsely_site_uuid%22%3A%22908932BF-0935-46AD-84BD-10120D5297CA%22%7D&title=Deadspin+-+Sports+News+without+Access%2C+Favor%2C+or+Discretion&date=Thu+Mar+21+2013+08%3A22%3A11+GMT-0500+(Central+Daylight+Time)&action=pageview HTTP/1.1 || 200 || 363 || - || Mozilla/5.0 (Windows NT 5.1; rv:19.0) Gecko/20100101 Firefox/19.0" || - || - || parsely_network_uuid=CrMHN1FLCYUJWgTmkT47Ag==; expires=Thu, 31-Dec-37 23:55:55 GMT; domain=track.parse.ly; path=/ || 0.000"""  

var line = """"/plogger/ || 191.251.123.60 || - || 31/Aug/2015:23:49:01 +0000  || GET /plogger/?rand=1441064941650&idsite=bolsademulher.com&url=http%3A%2F%2Fwww.bolsademulher.com%2Fbebe%2Fo-que-o-bebe-sente-dentro-da-barriga-quando-a-mae-faz-sexo-4-sensacoes-surpreendentes%2F%3Futm_source%3Dfacebook%26utm_medium%3Dmanual%26utm_campaign%3DBolsaFB&urlref=http%3A%2F%2Fm.facebook.com%2F&screen=360x592%7C360x592%7C32&data=%7B%22parsely_uuid%22%3A%22b5e2fcb7-966f-40f8-b41c-fca446908a56%22%2C%22parsely_site_uuid%22%3A%226e9ab165-497c-45be-9998-e029372b5a92%22%7D&sid=1&surl=http%3A%2F%2Fwww.bolsademulher.com%2Fbebe%2Fo-que-o-bebe-sente-dentro-da-barriga-quando-a-mae-faz-sexo-4-sensacoes-surpreendentes%2F%3Futm_source%3Dfacebook%26utm_medium%3Dmanual%26utm_campaign%3DBolsaFB&sref=http%3A%2F%2Fm.facebook.com%2F&sts=1441064914096&slts=0&date=Mon+Aug+31+2015+20%3A49%3A01+GMT-0300+(BRT)&action=heartbeat&inc=6 HTTP/1.1 || 200 || 236 || http://www.bolsademulher.com/bebe/o-que-o-bebe-sente-dentro-da-barriga-quando-a-mae-faz-sexo-4-sensacoes-surpreendentes/?utm_source=facebook&utm_medium=manual&utm_campaign=BolsaFB || Mozilla/5.0 (Linux; Android 4.4.4; XT1025 Build/KXC21.5-40) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/33.0.0.0 Mobile Safari/537.36 [FB_IAB/FB4A;FBAV/34.0.0.43.267;] || - || - || - || 0.000"""

  
var log_line = parse_log_line(line)
echo($$log_line)
