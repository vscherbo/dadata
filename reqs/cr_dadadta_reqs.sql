-- Function: arc_energo.get_reqs(varchar)

-- DROP FUNCTION arc_energo.dadata_reqs(varchar);

CREATE OR REPLACE FUNCTION arc_energo.dadata_reqs(
    IN arg_inn varchar,
    OUT ret_flg boolean,
    OUT ret_short_name varchar,
    OUT ret_full_name varchar,
    OUT ret_kpp varchar,
    OUT ret_ogrn varchar,
    OUT ret_emails varchar, 
    OUT ret_phones varchar,
    OUT ret_postal_code varchar,
    OUT ret_address varchar,
    OUT ret_country varchar,
    OUT ret_area varchar,
    OUT ret_region varchar,
    OUT ret_city varchar,
    OUT ret_settlement varchar,
    OUT ret_street varchar,
    OUT ret_house varchar,
    OUT ret_block varchar,
    OUT ret_flat varchar,
    OUT ret_name varchar,
    OUT ret_post varchar
)
  RETURNS record AS
$BODY$
# -*- coding: utf-8 -*-
import json

ret_short_name = ''
ret_full_name = ''
ret_kpp = ''
ret_ogrn = ''
ret_name = ''
ret_post = ''
ret_emails = ''
ret_phones = ''
ret_postal_code = ''
ret_address = ''
ret_country = ''
ret_area = ''
ret_region = ''
ret_city = ''
ret_settlement = ''
ret_street = ''
ret_house = ''
ret_block = ''
ret_flat = ''

#plpy.notice('Start dadata_reqs. Len=(%s) of arg_inn=%s', len(arg_inn), arg_inn)
res = plpy.execute("select * from req_dadata('{0}', 'party')".format(arg_inn))
ret_flg = res[0]["ret_flg"]
if ret_flg:
    reqs = json.loads(res[0]["ret_jsonb"])
    if reqs['suggestions']:
        #if len(reqs['suggestions'][0]['data']['inn']) == 10:
        if len(arg_inn) == 10:
            if reqs['suggestions'][0]['data']['inn'] != arg_inn:
                plpy.warning('sugg.inn=%s, arg_inn=%s', reqs['suggestions'][0]['data']['inn'], arg_inn)
                ret_flg = False
                return ret_flg, ret_short_name, ret_full_name, ret_kpp, ret_ogrn,\
                ret_emails ,\
                        ret_phones ,\
                        ret_postal_code ,\
                        ret_address ,\
                        ret_country ,\
                        ret_area ,\
                        ret_region ,\
                        ret_city ,\
                        ret_settlement ,\
                        ret_street ,\
                        ret_house ,\
                        ret_block ,\
                        ret_flat ,\
                ret_name, ret_post

            ret_short_name = reqs['suggestions'][0]['data']['name']['short_with_opf']
            ret_full_name = reqs['suggestions'][0]['data']['name']['full_with_opf']
            #ret_kpp = reqs['suggestions'][0]['data']['kpp']
            ret_kpp = reqs['suggestions'][0]['data'].get('kpp', 'нет КПП') #.encode('utf-8')
            ret_ogrn = reqs['suggestions'][0]['data']['ogrn']
            mng = reqs['suggestions'][0]['data'].get('management')
            #if reqs['suggestions'][0]['data']['management']:
            if mng is not None:
                    ret_name = reqs['suggestions'][0]['data']['management'].get('name', 'ФИО не известно').encode('utf-8')
                    #ret_post = reqs['suggestions'][0]['data']['management'].get('post', 'должность не известна').encode('utf-8')
                    ret_post = reqs['suggestions'][0]['data']['management'].get('post', 'должность не известна')
                    if ret_post is None or ret_post == 'null':
                        ret_post = 'должность не известна'
                    else:
                        ret_post = ret_post.encode('utf-8')

            ret_emails = reqs['suggestions'][0]['data']['emails']
            ret_phones = reqs['suggestions'][0]['data']['phones']
            # addr info
            ret_address = reqs['suggestions'][0]['data']['address'].get('value')
            addr_data = reqs['suggestions'][0]['data']['address']['data']
            if addr_data:
                #ret_address = addr_data.get('source', 'address unknown')
                ret_country = addr_data.get('country', 'country unknown')
                ret_area = addr_data.get('area_with_type', 'area unknown')
                ret_region = addr_data.get('region_with_type', 'region unknown')
                ret_city = addr_data.get('city_with_type', 'city unknown')
                ret_settlement = addr_data.get('settlement_with_type', 'settlement unknown')
                ret_street = addr_data.get('street_with_type', 'street unknown')
                ret_postal_code = addr_data.get('postal_code', 'postal_code unknown')
                house = []
                house.append(addr_data.get('house_type'))
                house.append(addr_data.get('house'))
                ret_house = ' '.join(filter(None, house))

                block = []
                block.append(addr_data.get('block_type'))
                block.append(addr_data.get('block'))
                ret_block = ' '.join(filter(None, block))
                

                flat = []
                flat.append(addr_data.get('flat_type'))
                flat.append(addr_data.get('flat'))
                ret_flat = ' '.join(filter(None, flat))
                

        elif len(arg_inn) == 12:
            # EGRIP
            ret_short_name = reqs['suggestions'][0]['data']['name']['short_with_opf']
            ret_full_name = reqs['suggestions'][0]['data']['name']['full_with_opf']
            ret_ogrn = reqs['suggestions'][0]['data']['ogrn']
            #plpy.notice('query to EGRIP. arg_inn=%s', arg_inn)
        else:
            ret_flg = False
            plpy.warning('Wrong length (%s) of arg_inn=%s', len(arg_inn), arg_inn)
    else:
        ret_flg = False
        ret_short_name = reqs['suggestions']
else:
    ret_short_name = 'no answer'
        
return ret_flg, ret_short_name, ret_full_name, ret_kpp, ret_ogrn,\
ret_emails ,\
        ret_phones ,\
        ret_postal_code ,\
        ret_address ,\
        ret_country ,\
        ret_area ,\
        ret_region ,\
        ret_city ,\
        ret_settlement ,\
        ret_street ,\
        ret_house ,\
        ret_block ,\
        ret_flat ,\
ret_name, ret_post
        
$BODY$
  LANGUAGE plpython2u VOLATILE
  COST 100;
