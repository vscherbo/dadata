DROP FUNCTION arc_energo.dadata_country(varchar);

CREATE OR REPLACE FUNCTION arc_energo.dadata_country(
    IN arg_addr_text varchar,
    OUT ret_flg boolean,
    OUT ret_country text)
  RETURNS record AS
$BODY$
# -*- coding: utf-8 -*-
import json
from datetime import datetime
from os.path import expanduser

plpy.log('dadata_country arg_addr_text={0}'.format(arg_addr_text))

ret_country = ''
res = plpy.execute("select * from req_dadata_int('{0}', 'address')".format(arg_addr_text))
ret_flg = res[0]["ret_flg"]
if ret_flg:
    addr_info_full = json.loads(res[0]["ret_jsonb"])
    addr_info = {}
    addr_info['suggestions'] = []
    uniq_idx = set()
    for adr in addr_info_full['suggestions']:
        if adr['data']['street'] not in uniq_idx:
            uniq_idx.add(adr['data']['street'])
            addr_info['suggestions'].append(adr) 

    res_len = len(addr_info['suggestions'])
    plpy.log("addr_info={0}, res_len={1}".format(addr_info, res_len))
    if res_len > 1:
        ret_country = 'Найдено больше одного адреса ({0})'.format(res_len)
        plpy.warning(ret_country)
        loc_country = set()
        for adr in addr_info['suggestions']:
            #loc_country.add(adr['data']['country'].encode('utf8'))
            loc_country.add(adr['data']['country'])
            plpy.warning('country={0}, city={1}, street={2}'.format(
                    adr['data']['country'].encode('utf8'), '', ''
                    #adr['data'].get('city', 'NO-city').encode('utf8'),
                    #adr['data'].get('street', 'NO-street').encode('utf8')
            )      )
        ret_country = ''.join(list(loc_country)) #.encode('utf8')
        ret_flg = True
    elif 1 == res_len:

        ret_country = addr_info['suggestions'][0]['data'].get('country', '') # .encode('utf8')
        plpy.log('addr_country={0}'.format(ret_country.encode('utf8')))
        #plpy.log('addr_country={0}'.format(ret_country))
        #ret_country = addr_info['suggestions'][0]['data'].get('country', '')
        #plpy.log('addr_country={0}'.format(ret_country.encode('utf8')))
    else:
        plpy.warning('Пустой ответ от dadata.ru')
        ret_flg = False

return ret_flg, ret_country
$BODY$
  LANGUAGE plpython2u VOLATILE
  COST 100;
