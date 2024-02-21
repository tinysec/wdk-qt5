@echo off

set PATH=%PATH%;D:/sdk/qt/5.6.3/src/gnuwin32/bin;D:/sdk/qt/5.6.3/src/build/qtbase/bin;

..\configure -mp -debug-and-release -shared -prefix "d:/sdk/qt/5.6.3/2008/x64" -opensource -confirm-license -platform win32-msvc2008 -nomake examples -nomake tests  -no-compile-examples -no-freetype  -no-harfbuzz -no-iconv -no-style-fusion -qt-zlib -qt-libpng -qt-libjpeg -qt-pcre -skip qtandroidextras -skip qtmacextras -skip qtx11extras -qt-sql-sqlite -opengl desktop -ssl -openssl -direct2d -directwrite -D _USING_V120_SDK71_ -I D:/sdk/openssl/1.0.2g/2008/x64/include -I "C:/Program Files (x86)/Microsoft DirectX SDK (June 2010)/Include" -L D:/sdk/openssl/1.0.2g/2008/x64/lib -L "C:/Program Files (x86)/Microsoft DirectX SDK (June 2010)/Lib/x64"
