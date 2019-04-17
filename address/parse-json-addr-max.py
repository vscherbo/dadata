#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import json
import os
import codecs
import argparse
import logging
import sys
import configparser

(prg_name, prg_ext) = os.path.splitext(os.path.basename(__file__))
conf_file_name = prg_name + ".conf"
log_file_name = prg_name + ".log"

config = configparser.ConfigParser(allow_no_value=True)
config.read(conf_file_name)
data_dir = config['dirs']['data_dir']

parser = argparse.ArgumentParser(description='Разбор адреса.')
# parser.add_argument('--conf', type=str, default=conf_file, help='conf file')
parser.add_argument('--jfile', type=str, required=True, help='JSON file')
parser.add_argument('--log_level', type=str, default="DEBUG", help='log level')
log_dir = ''
args = parser.parse_args()

numeric_level = getattr(logging, args.log_level, None)
if not isinstance(numeric_level, int):
    raise ValueError('Invalid log level: %s' % numeric_level)

log_format = """[%(filename)-20s:%(lineno)4s - %(funcName)20s()]
 %(levelname)-7s | %(asctime)-15s | %(message)s"""

"""
logging.basicConfig(filename=log_file_name, filemode='a', format=log_format,
level=numeric_level)
"""
logging.basicConfig(stream=sys.stdout, format=log_format, level=numeric_level)

# addr_data_file = '{}addr-{}.json'.format(data_dir, args.code)
addr_data_file = args.jfile
jsonf = codecs.open(addr_data_file, 'r', 'utf-8')
logging.debug('Чтение из файла addr={}'.format(addr_data_file))
addr_info = json.load(jsonf)
jsonf.close()

res_len = len(addr_info['suggestions'])
if res_len > 1:
    logging.warning('file=%s len of suggestions=%s', addr_data_file,
                    len(addr_info['suggestions']))
elif 1 == res_len:
    sys.path.append(data_dir)
    point_list = []
    point_list.append(addr_info['suggestions'][0]['data']['city'])
    point_list.append(addr_info['suggestions'][0]['data']['settlement'])
    ret_addr_city = ', '.join(filter(None, point_list))

    ret_addr_street = addr_info['suggestions'][0]['data']['street']
    #
    ret_addr_house = addr_info['suggestions'][0]['data']['house']
    if ret_addr_house:
        ret_addr_house = ret_addr_house.encode('utf8')

    # корпус/строение
    ret_addr_block = addr_info['suggestions'][0]['data']['block']
    if ret_addr_block:
        ret_addr_block = ret_addr_block.encode('utf8')

    # квартира/офис
    ret_addr_flat = addr_info['suggestions'][0]['data']['flat']
    if ret_addr_flat:
        ret_addr_flat = ret_addr_flat.encode('utf8')
    print("""addr_city={0},
 addr_street={1},
 addr_house={2},
 addr_block={3},
 addr_flat={4}""".format(ret_addr_city,
                         ret_addr_street,
                         ret_addr_house,
                         ret_addr_block,
                         ret_addr_flat))

    for (k, v) in addr_info['suggestions'][0]['data'].items():
        if v:
           print('{}: {}'.format(k, str(v)))

    """
    addr_city = addr_info['suggestions'][0]['data']['city']
    addr_kladr_street = addr_info['suggestions'][0]['data']['street_kladr_id']
    addr_house = addr_info['suggestions'][0]['data']['house']
    addr_block = addr_info['suggestions'][0]['data']['block']
    addr_flat = addr_info['suggestions'][0]['data']['flat']  # квартира/офис
    logging.debug('addr_city={}, addr_kladr_street={}, addr_house={},
    addr_block={}, addr_flat={}'.format(addr_city, addr_kladr_street,
    addr_house, addr_block, addr_flat) )
    print('{}^{}^{}^{}'.format(addr_kladr_street, addr_house,
    addr_block, addr_flat))
    """
else:
    logging.warning('empty result')
