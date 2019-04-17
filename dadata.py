#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import json
import requests


BASE_URL = 'https://suggestions.dadata.ru/suggestions/api/4_1/rs/suggest/%s'

class Dadata:
    'Class to request dadata.ru'
    def __init__(self, api_key):
        self.API_KEY = api_key
        
    def suggest(self, query, resource):
        url = BASE_URL % resource
        headers = {
            'Authorization': 'Token %s' % self.API_KEY,
            'Content-Type': 'application/json',
        }
        data = {
            'query': query
        }
        r = requests.post(url, data=json.dumps(data), headers=headers)
        return r.text
