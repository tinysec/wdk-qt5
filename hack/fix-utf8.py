import sys
import os
import codecs
import chardet
  
def utf8_converter(file_path , universal_endline =True ):
    # Read from file
    print("file:"+ file_path)
    file_open = open(file_path, "rb")
    raw = file_open.read()
    encoding_name = chardet.detect(raw)[ 'encoding']
    print(encoding_name )
    file_open.close()
    # Decode
    raw = raw.decode(encoding_name)
    # Remove windows end line
    if universal_endline:
        raw = raw.replace( '\r\n', '\n')
    # Encode to UTF-8-sig
    raw = raw.encode('utf-8-sig')
  
    file_open = open(file_path, 'wb')
    file_open.write(raw)
    file_open.close()
    return 0
  
if __name__ == '__main__' :
    '''file = sys.argv[1].encode( 'unicode_escape')'''
    f = open("unicode_escape.txt", "r")
    s = f.read()
    files = s.split("\n")
    for file in files:
        utf8_converter(file, False)
    f.close()