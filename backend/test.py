import configparser
import json
import requests

def read_ini_config(filename):
    config = configparser.ConfigParser()
    config.read(filename)
    config_list = [{
        'name': 'default',
        'config': {
                key: value
                for key, value in config.defaults().items()
        }
    }] + [
        {
            'name': section,
            'config': {
                key: value
                for key, value in config._sections[section].items()
            }
        }
        for section in config.sections()
    ]
    return config_list

if __name__ == '__main__':
    config = read_ini_config('config.ini')
    print(config)
    for i in range(len(config)):
        requests.delete(f'http://127.0.0.1:5230/api/data?id={i+1}')
    response = requests.post('http://127.0.0.1:5230/api/data', json=config)