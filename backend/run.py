import configparser
from genericpath import exists
from os import mkdir
import matlab.engine
from pygments import highlight
from pygments.lexers import PythonLexer
from pygments.formatters import ImageFormatter

# 读取INI配置文件
def read_ini_config(filename):
    config = configparser.ConfigParser()
    config.read(filename)
    config_dict = {
        section: {
            key: value
            for sub_config in [config.items('DEFAULT')] + [
                config._sections[sub_section].items() 
                for sub_section in [*section.split('.')[:-1], section]
            ]
            for key, value in sub_config
        }
        for section in config.sections()
        if '.' in section
    }
    return config_dict

# 将INI配置转换为Matlab结构体
def ini_to_matlab_struct(config_dict, section):
    struct_str = 'config = struct();\n'
    for key, value in config_dict.items():
        struct_str += f'config.{key} = {value};\n'
    struct_str += f'''
    config.config_name = "{section}";
    config.init_image_display=           "img/hbs_seg/output/config_{section}/init.png";
    config.recounstruced_bound_display=  "img/hbs_seg/output/config_{section}/reconstructed.png";
    config.seg_display=                  "img/hbs_seg/output/config_{section}/seg_display.png";
    '''
    return struct_str

def ini_to_image(config_dict, section):
    lexer = PythonLexer()
    formatter = ImageFormatter(font_size=16, line_numbers=True)
    ini_str = f'# section: config_{section}\n'
    for key, value in config_dict.items():
        ini_str += f'{key} = {value}\n'
    image_data = highlight(ini_str, lexer, formatter)
    
    config_dir = f'../img/hbs_seg/output/config_{section}'
    if not exists(config_dir):
        mkdir(config_dir)

    config_path = f'{config_dir}/config.png'
    if exists(config_path):
        with open(config_path, 'rb') as image_file:
            old_image_data = image_file.read()
            if old_image_data == image_data:
                print(f'Old config {section}, pass')
                return False
            
    with open(config_path, 'wb') as image_file:
        image_file.write(image_data)
        print(f'New config {section}, run')
        return True
    
# 生成Matlab脚本
def generate_matlab_script(matlab_struct):
    matlab_script = f'''
    cd('..');
    addpath('./dependencies');
    addpath('./dependencies/im2mesh');
    addpath('./dependencies/mfile');
    addpath('./dependencies/aco-v1.1/aco');
    addpath('./dependencies/map/map');
    clear all;
    close all;
    
    {matlab_struct}
    disp(config)

    static = Mesh.imread(config.static);
    static = imresize(static, [256,256]);
    static = double(static);
    static = imnoise(static, config.noise_type, config.noise_para(1), config.noise_para(2));
    if config.reverse_image == 1
        static = 1 - static;
    end

    if endsWith(config.moving, '.mat')
        load('vars/mean_hbs.mat');
        moving = mean_hbs;
    elseif endsWith(config.moving, '.png')
        moving = Mesh.imread(config.moving);
        moving = imresize(moving, [256,256]);
        moving = double(moving >= 0.5);
    end
    global best_loss;
    HBS_seg(static, moving, config);
    '''

    return matlab_script

def main():
    ini_filename = '../config/config.ini'
    eng = matlab.engine.start_matlab('-nojvm -nodisplay -nosplash -nodesktop')
    while True:
        config_dict = read_ini_config(ini_filename)
        for section in config_dict.keys():
            result = run(config_dict[section], section, eng)
            if result is not None:
                print(f'{section} best_loss: {result}')
                break
            else:
                continue
        else:
            break

    eng.quit()
    
def run(config, name, eng=None):
    if not ini_to_image(config, name):
        return None
    
    if eng is None:
        eng = matlab.engine.start_matlab('-nojvm -nodisplay -nosplash -nodesktop')

    matlab_struct = ini_to_matlab_struct(config, name)
    matlab_script = generate_matlab_script(matlab_struct)
    eng.eval(matlab_script, nargout=0)
    result = eng.workspace['best_loss']
    eng.quit()
    return result

if __name__ == "__main__":
    main()
