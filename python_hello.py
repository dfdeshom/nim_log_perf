from ctypes import CDLL

"""
>>> p = parse_log_line('/plogger/ || 50.73.113.242 || - || 21/Mar/2013:13:22:13 +0000  || GET /plogger/?rand=1363872131875&idsite=deadspin.com&url=http%3A%2F%2Fdeadspin.com%2Frecommended&urlref=http%3A%2F%2Fdeadspin.com%2F&screen=1024x768%7C1024x738%7C24&data=%7B%22parsely_uuid%22%3A%22908932BF-0935-46AD-84BD-10120D5297CA%22%2C%22parsely_site_uuid%22%3A%22908932BF-0935-46AD-84BD-10120D5297CA%22%7D&title=Deadspin+-+Sports+News+without+Access%2C+Favor%2C+or+Discretion&date=Thu+Mar+21+2013+08%3A22%3A11+GMT-0500+(Central+Daylight+Time)&action=pageview HTTP/1.1 || 200 || 363 || - || Mozilla/5.0 (Windows NT 5.1; rv:19.0) Gecko/20100101 Firefox/19.0" || - || - || parsely_network_uuid=CrMHN1FLCYUJWgTmkT47Ag==; expires=Thu, 31-Dec-37 23:55:55 GMT; domain=track.parse.ly; path=/ || 0.000')
    >>> {'i': '50.73.113.242', 'r': {'title': 'Deadspin - Sports News without Access, Favor, or Discretion', 'url': 'http://deadspin.com/recommended', 'screen': '1024x768|1024x738|24', 'action': 'pageview', 'urlref': 'http://deadspin.com/', 'date': 'Thu Mar 21 2013 08:22:11 GMT-0500 (Central Daylight Time)', 'idsite': 'deadspin.com', 'data': {'parsely_site_uuid': '908932BF-0935-46AD-84BD-10120D5297CA', 'parsely_uuid': '908932BF-0935-46AD-84BD-10120D5297CA'}}, 'u': 'Mozilla/5.0 (Windows NT 5.1; rv:19.0) Gecko/20100101 Firefox/19.0', 't': dt.datetime(2013, 3, 21, 13, 22, 11, 875000)} == p
    True
"""


def main():
    lib = CDLL("/home/dfdeshom/code/python-nim/libhello.so")
    print lib.fun("dd")

main()
