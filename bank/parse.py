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

parser = argparse.ArgumentParser(description='Разбор банковской информации.')
# parser.add_argument('--conf', type=str, default=conf_file, help='conf file')
parser.add_argument('--bic', type=str, required=True, help='БИК')
parser.add_argument('--log_level', type=str, default="DEBUG", help='log level')
log_dir = ''
args = parser.parse_args()

numeric_level = getattr(logging, args.log_level, None)
if not isinstance(numeric_level, int):
    raise ValueError('Invalid log level: %s' % numeric_level)

log_format = '[%(filename)-20s:%(lineno)4s - %(funcName)20s()] %(levelname)-7s | %(asctime)-15s | %(message)s'

# logging.basicConfig(filename=log_file_name, filemode='a', format=log_format, level=numeric_level)
logging.basicConfig(stream=sys.stdout, format=log_format, level=numeric_level)

bank_data_file = '{}bank-{}.json'.format(data_dir, args.bic)
jsonf = codecs.open(bank_data_file, 'r', 'utf-8')
logging.info('Чтение из файла bank={}'.format(bank_data_file))
bank_info = json.load(jsonf)
jsonf.close()

res_len = len(bank_info['suggestions'])
# logging.debug('len of suggestions={}'.format(len(bank_info['suggestions'])))
if res_len > 0:
    logging.info("suggestions[0]['data']['address']['data']={}".format(bank_info['suggestions'][0]['data']['address']['data']))
    sys.path.append(data_dir)
    bank_short_name = bank_info['suggestions'][0]['data']['name']['short'] \
                      or bank_info['suggestions'][0]['data']['name']['payment']
    bank_address = bank_info['suggestions'][0]['data']['address']['value']
    bank_corr = bank_info['suggestions'][0]['data']['correspondent_account']
    if bank_info['suggestions'][0]['data']['address']['data']:
        logging.info("city_type={}".format(bank_info['suggestions'][0]['data']['address']['data']['city_type']))
        logging.info("city={}".format(bank_info['suggestions'][0]['data']['address']['data']['city']))
        logging.info("settlement_with_type={}".format(bank_info['suggestions'][0]['data']['address']['data']['settlement_with_type']))
        if bank_info['suggestions'][0]['data']['address']['data']['city_type']:
            bank_city = "{}. {}".format(bank_info['suggestions'][0]['data']['address']['data']['city_type'],
                                        bank_info['suggestions'][0]['data']['address']['data']['city'])
        else:
            bank_city = "{}".format(bank_info['suggestions'][0]['data']['address']['data']['settlement_with_type'])
    else:
        import dadata
        API_KEY = config['dadata_login']['API_KEY']
        d1 = dadata.Dadata(API_KEY)
        addr_info = json.loads(d1.suggest(bank_address, 'address'))
        # bank_city = addr_info['suggestions'][0]['data']['city']
        logging.info("read extra address={}".format(addr_info))
        if addr_info['suggestions'][0]['data']['city_type']:
            bank_city = "{}. {}".format(addr_info['suggestions'][0]['data']['city_type'],
                                        addr_info['suggestions'][0]['data']['city'])
        else:
            bank_city = None

    logging.debug('bank_short_name={}, bank_address={}, bank_city={}, corr_acc={}'.format(bank_short_name, bank_address, bank_city, bank_corr))
else:
    logging.warning('empty result')
