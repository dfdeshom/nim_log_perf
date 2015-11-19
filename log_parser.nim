import uri2
import tables
import strutils
import cgi
import times
import json
import sets

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
  
proc parse_log_line(): bool =
  var line: string = """/plogger/ || 50.73.113.242 || - || 21/Mar/2013:13:22:13 +0000  || GET /plogger/?rand=1363872131875&idsite=deadspin.com&url=http%3A%2F%2Fdeadspin.com%2Frecommended&urlref=http%3A%2F%2Fdeadspin.com%2F&screen=1024x768%7C1024x738%7C24&data=%7B%22parsely_uuid%22%3A%22908932BF-0935-46AD-84BD-10120D5297CA%22%2C%22parsely_site_uuid%22%3A%22908932BF-0935-46AD-84BD-10120D5297CA%22%7D&title=Deadspin+-+Sports+News+without+Access%2C+Favor%2C+or+Discretion&date=Thu+Mar+21+2013+08%3A22%3A11+GMT-0500+(Central+Daylight+Time)&action=pageview HTTP/1.1 || 200 || 363 || - || Mozilla/5.0 (Windows NT 5.1; rv:19.0) Gecko/20100101 Firefox/19.0" || - || - || parsely_network_uuid=CrMHN1FLCYUJWgTmkT47Ag==; expires=Thu, 31-Dec-37 23:55:55 GMT; domain=track.parse.ly; path=/ || 0.000"""  
  let parts: seq[string] = line.split(" || ")
  let parsed_request: Table[string,string] = parse_query_args(parts[4].split(' ')[1])
  var res = initTable[string, string]()
  
  try:
    var data = parseJson(parsed_request.getOrDefault("dataq"))
    var tmsp_override = data.getStr("ts")
  except:
    var data = initTable[string, string]()
    var tmsp_override = 0

  if tmsp_override:
    echo("convert to time obj?")
  else:
    let rand = parts[3]
    
  #echo($data["parsely_uuid"])
  
  #var tmsp_override = 
  #echo($tmsp_override)
  echo($parsed_request)
  #echo( $req)
  
#discard parse_log_line()

#discard parse_query_args("/dsd")
discard parse_log_line()
