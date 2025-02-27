DROP FUNCTION arc_energo.dadata_address_ext(integer, varchar);

CREATE OR REPLACE FUNCTION arc_energo.dadata_address_ext(
    IN arg_kod integer,
    IN arg_addr_text varchar DEFAULT NULL,
    OUT ret_flg boolean,
    OUT ret_addr_city varchar,
    OUT ret_addr_city_code varchar,
    OUT ret_addr_street varchar,
    OUT ret_addr_street_type varchar,
    OUT ret_addr_street_with_type varchar,
    OUT ret_addr_house varchar,
    OUT ret_addr_block varchar,
    OUT ret_addr_flat varchar)
  RETURNS record AS
$BODY$
# -*- coding: utf-8 -*-
from collections import OrderedDict
import requests
import json
from datetime import datetime
from os.path import expanduser

if arg_addr_text:
    req_address = arg_addr_text
    addr_type = 'CUSTOM'
else:
    res = plpy.execute('select "ЮрАдрес" from "Предприятия" WHERE "Код" = {0}'.format(arg_kod))
    req_address = res[0]["ЮрАдрес"]
    addr_type = 'LEGAL'
#req_address = req_address + " -"
plpy.log('dadata arg: {0} req_address={1}'.format(addr_type, req_address))

ret_addr_city = ''
ret_addr_city_code = ''
ret_addr_street = ''
ret_addr_street_type = ''
ret_addr_street_with_type = ''
ret_addr_house = ''
ret_addr_block = ''
ret_addr_flat = ''
res = plpy.execute("select * from req_dadata('{0}', 'address')".format(req_address))
#plpy.log("colnames={0}".format(res.colnames()))
#plpy.log("coltypes={0}".format(res.coltypes()))
ret_flg = res[0]["ret_flg"]
if ret_flg:
    addr_info_full = json.loads(res[0]["ret_jsonb"])
    addr_info = {}
    addr_info['suggestions'] = []
    uniq_idx = set()
    for adr in addr_info_full['suggestions']:
        # adr['data']['street_fias_id']
        if adr['data']['street_kladr_id'] not in uniq_idx:
            uniq_idx.add(adr['data']['street_kladr_id'])
            addr_info['suggestions'].append(adr) 

    res_len = len(addr_info['suggestions'])
    plpy.log("req_address={0}, res_len={1}".format(req_address, res_len))
    if res_len > 1:
        ret_addr_city = 'Найдено больше одного адреса ({0})'.format(res_len)
        plpy.warning(ret_addr_city)
        for adr in addr_info['suggestions']:
            plpy.warning('kladr_id={0}, fias_id={1}, value={2}'.format(
                    adr['data']['street_kladr_id'],
                    adr['data']['street_fias_id'],
                    adr['value'].encode('utf8')))
        ret_flg = False
    elif 1 == res_len:
        #ret_addr_city = addr_info['suggestions'][0]['data']['city'] or addr_info['suggestions'][0]['data']['settlement']
        """
        region_with_type: Воронежская обл
        area_with_type: Павловский р-н
        city_with_type: г Павловск
        settlement_with_type
        street_with_type: ул Ленина
        ", ".join([x for x in map(d1.get, ["a", "b", "c"]) if x])
        if addr_info['suggestions'][0]['data']['settlement'] and addr_info['suggestions'][0]['data']['city']:
            ret_addr_city = u'{0}, {1}'.format(addr_info['suggestions'][0]['data']['city'], addr_info['suggestions'][0]['data']['settlement'])
        else:
            ret_addr_city = addr_info['suggestions'][0]['data']['settlement'] or addr_info['suggestions'][0]['data']['city'] 
        """
        addr_list = [x for x in map(addr_info['suggestions'][0]['data'].get,
                        ['region_with_type', 'area_with_type', 'city_with_type', 'settlement_with_type']) if x]
        addr_list = list(OrderedDict.fromkeys(addr_list))
        ret_addr_city = ", ".join(addr_list)
        if ret_addr_city:
            ret_addr_city = ret_addr_city.encode('utf8')
        #
        ret_addr_city_code = addr_info['suggestions'][0]['data']['settlement_kladr_id'] or addr_info['suggestions'][0]['data']['city_kladr_id']
        #    
        ret_addr_street = addr_info['suggestions'][0]['data']['street']
        if ret_addr_street:
            ret_addr_street = ret_addr_street.encode('utf8')
            ret_addr_street_type = addr_info['suggestions'][0]['data']['street_type']
            ret_addr_street_with_type = addr_info['suggestions'][0]['data']['street_with_type']
            if ret_addr_street_type:
                ret_addr_street_type = ret_addr_street_type.encode('utf8')
            if ret_addr_street_with_type:
                ret_addr_street_with_type = ret_addr_street_with_type.encode('utf8')
        else:
            ret_addr_street_type = ''
        #    
        ret_addr_house = addr_info['suggestions'][0]['data']['house']
        if ret_addr_house:
            ret_addr_house = ret_addr_house.encode('utf8')
        #    
        ret_addr_block = addr_info['suggestions'][0]['data']['block']  # корпус/строение
        if ret_addr_block:
            ret_addr_block = ret_addr_block.encode('utf8')
        #    
        ret_addr_flat = addr_info['suggestions'][0]['data']['flat']  # квартира/офис
        if ret_addr_flat:
            ret_addr_flat = ret_addr_flat.encode('utf8')
        plpy.log('addr_city={0}, city_code={1}, addr_street={2}, addr_house={3}, addr_block={4}, addr_flat={5}'.format(ret_addr_city, ret_addr_city_code, ret_addr_street, ret_addr_house, ret_addr_block, ret_addr_flat) )
    else:
        plpy.warning('Пустой ответ от dadata.ru')
        ret_flg = False

return ret_flg, ret_addr_city, ret_addr_city_code, ret_addr_street, ret_addr_street_type,ret_addr_street_with_type, ret_addr_house, ret_addr_block, ret_addr_flat
$BODY$
  LANGUAGE plpython2u VOLATILE
  COST 100;
