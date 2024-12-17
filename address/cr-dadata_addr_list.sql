--
-- Name: dadata_addr_list(character varying); Type: FUNCTION; Schema: arc_energo; Owner: postgres
--

CREATE FUNCTION arc_energo.dadata_addr_list(arg_addr_text character varying DEFAULT NULL::character varying, OUT ret_addr character varying, OUT ret_fias_level integer) RETURNS SETOF record
    LANGUAGE plpython2u
    AS $$
# -*- coding: utf-8 -*-
from collections import OrderedDict
import requests
import json
from datetime import datetime
from os.path import expanduser

plpy.log('dadata arg: arg_addr_text={0}'.format(arg_addr_text))

ret_count = -1
ret_addr = u''
addr_list = []
res = plpy.execute("select * from req_dadata('{0}', 'address')".format(arg_addr_text))
#plpy.log("colnames={0}".format(res.colnames()))
#plpy.log("coltypes={0}".format(res.coltypes()))
ret_flg = res[0]["ret_flg"]
if ret_flg:
    addr_info = json.loads(res[0]["ret_jsonb"])
    ret_count = len(addr_info['suggestions'])
    plpy.log("arg_addr_text={0}, ret_count={1}".format(arg_addr_text, ret_count))
    if ret_count:
        for adr in addr_info['suggestions']:
            addr_list.append((adr['value'], adr['data']['fias_level']))
            plpy.log(adr['value'].encode('utf8'))
        """
        for adr in addr_info['suggestions']:
            plpy.warning('kladr_id={0}, fias_id={1}, value={2}'.format(
                    adr['data']['street_kladr_id'],
                    adr['data']['street_fias_id'],
                    adr['value'].encode('utf8')))
        """
    else:
        plpy.warning('Пустой ответ от dadata.ru')

#return ret_count, ret_addr
ret_addr = addr_list
return ret_addr
$$;


ALTER FUNCTION arc_energo.dadata_addr_list(arg_addr_text character varying, OUT ret_addr character varying, OUT ret_fias_level integer) OWNER TO postgres;
