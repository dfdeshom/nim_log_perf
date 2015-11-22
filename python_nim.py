from ctypes import *

"""
>>> p = parse_log_line('/plogger/ || 50.73.113.242 || - || 21/Mar/2013:13:22:13 +0000  || GET /plogger/?rand=1363872131875&idsite=deadspin.com&url=http%3A%2F%2Fdeadspin.com%2Frecommended&urlref=http%3A%2F%2Fdeadspin.com%2F&screen=1024x768%7C1024x738%7C24&data=%7B%22parsely_uuid%22%3A%22908932BF-0935-46AD-84BD-10120D5297CA%22%2C%22parsely_site_uuid%22%3A%22908932BF-0935-46AD-84BD-10120D5297CA%22%7D&title=Deadspin+-+Sports+News+without+Access%2C+Favor%2C+or+Discretion&date=Thu+Mar+21+2013+08%3A22%3A11+GMT-0500+(Central+Daylight+Time)&action=pageview HTTP/1.1 || 200 || 363 || - || Mozilla/5.0 (Windows NT 5.1; rv:19.0) Gecko/20100101 Firefox/19.0" || - || - || parsely_network_uuid=CrMHN1FLCYUJWgTmkT47Ag==; expires=Thu, 31-Dec-37 23:55:55 GMT; domain=track.parse.ly; path=/ || 0.000')
    >>> {'i': '50.73.113.242', 'r': {'title': 'Deadspin - Sports News without Access, Favor, or Discretion', 'url': 'http://deadspin.com/recommended', 'screen': '1024x768|1024x738|24', 'action': 'pageview', 'urlref': 'http://deadspin.com/', 'date': 'Thu Mar 21 2013 08:22:11 GMT-0500 (Central Daylight Time)', 'idsite': 'deadspin.com', 'data': {'parsely_site_uuid': '908932BF-0935-46AD-84BD-10120D5297CA', 'parsely_uuid': '908932BF-0935-46AD-84BD-10120D5297CA'}}, 'u': 'Mozilla/5.0 (Windows NT 5.1; rv:19.0) Gecko/20100101 Firefox/19.0', 't': dt.datetime(2013, 3, 21, 13, 22, 11, 875000)} == p
    True
"""
line = "/plogger/ || 191.251.123.60 || - || 31/Aug/2015:23:49:01 +0000  || GET /plogger/?rand=1441064941650&idsite=bolsademulher.com&url=http%3A%2F%2Fwww.bolsademulher.com%2Fbebe%2Fo-que-o-bebe-sente-dentro-da-barriga-quando-a-mae-faz-sexo-4-sensacoes-surpreendentes%2F%3Futm_source%3Dfacebook%26utm_medium%3Dmanual%26utm_campaign%3DBolsaFB&urlref=http%3A%2F%2Fm.facebook.com%2F&screen=360x592%7C360x592%7C32&data=%7B%22parsely_uuid%22%3A%22b5e2fcb7-966f-40f8-b41c-fca446908a56%22%2C%22parsely_site_uuid%22%3A%226e9ab165-497c-45be-9998-e029372b5a92%22%7D&sid=1&surl=http%3A%2F%2Fwww.bolsademulher.com%2Fbebe%2Fo-que-o-bebe-sente-dentro-da-barriga-quando-a-mae-faz-sexo-4-sensacoes-surpreendentes%2F%3Futm_source%3Dfacebook%26utm_medium%3Dmanual%26utm_campaign%3DBolsaFB&sref=http%3A%2F%2Fm.facebook.com%2F&sts=1441064914096&slts=0&date=Mon+Aug+31+2015+20%3A49%3A01+GMT-0300+(BRT)&action=heartbeat&inc=6 HTTP/1.1 || 200 || 236 || http://www.bolsademulher.com/bebe/o-que-o-bebe-sente-dentro-da-barriga-quando-a-mae-faz-sexo-4-sensacoes-surpreendentes/?utm_source=facebook&utm_medium=manual&utm_campaign=BolsaFB || Mozilla/5.0 (Linux; Android 4.4.4; XT1025 Build/KXC21.5-40) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/33.0.0.0 Mobile Safari/537.36 [FB_IAB/FB4A;FBAV/34.0.0.43.267;] || - || - || - || 0.000"


class TGenericSeq (Structure):
    _fields_ = [("len", c_int64), ("reserved", c_int64)]


class NimStringDesc(Structure):
    pass


def make_nim_string(s):
    _len = len(s)
    NimStringDesc._fields_ = [("Sup", TGenericSeq),
                              ("data", c_char * _len)]
    tgs = TGenericSeq(_len, 0)
    nsd = NimStringDesc(tgs, s)
    str_pointer = POINTER(NimStringDesc)
    return str_pointer(nsd)


def main():
    lib = CDLL("/home/dfdeshom/code/nim_log_perf/liblog_parser.so")
    str_pointer = POINTER(NimStringDesc)

    lib_parse = lib.parse_log_line
    lib_parse.argtypes = [str_pointer]
    lib_parse.restype = str_pointer

    # for i in range(100):
    #    res = lib_parse(e)
    e = make_nim_string(line)
    print lib_parse(e)
    return

main()
