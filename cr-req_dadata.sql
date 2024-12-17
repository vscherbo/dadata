-- Function: arc_energo.req_dadata(character varying)

-- DROP FUNCTION arc_energo.req_dadata(character varying);

CREATE OR REPLACE FUNCTION arc_energo.req_dadata(
    IN arg_query character varying,
    IN arg_resource character varying,
    OUT ret_flg boolean,
    OUT ret_jsonb jsonb)
  RETURNS record AS
$BODY$
import requests
import json
from datetime import datetime

BASE_URL = 'https://suggestions.dadata.ru/suggestions/api/4_1/rs/suggest/%s'
url = BASE_URL % arg_resource
headers = {
    'Authorization': 'Token %s' % 'f740ef88e86c5a567187d118dddd6a2c94b1fd94',
    'Content-Type': 'application/json',
}
data = {
    'query': arg_query
}

# good_status = [ 200, 500 ]
good_status = [ 200 ]

try:
    r = requests.post(url, data=json.dumps(data), headers=headers, timeout=15, verify=False)
except plpy.SPIError, e:
    plpy.error("Ошибка запроса dadata {0}/{1}, err={2}".format(arg_query, arg_resource, e.sqlstate))
    ret_flg = False
else:
    ret_flg = True if r.status_code in good_status else False
    ret_jsonb = r.text
return ret_flg, ret_jsonb
$BODY$
  LANGUAGE plpython2u VOLATILE
  COST 100;
