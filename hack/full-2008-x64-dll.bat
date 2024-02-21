@echo off

set PATH=%PATH%;D:/sdk/qt/5.6.3/src/gnuwin32/bin;D:/sdk/qt/5.6.3/src/build/qtbase/bin;

..\configure -mp -debug-and-release -shared -prefix "d:/sdk/qt/5.6.3/2008/x64" -opensource -confirm-license -platform win32-msvc2008 -nomake examples -nomake tests  -no-compile-examples -no-freetype  -no-harfbuzz -no-iconv -no-direct2d -no-directwrite  -no-style-fusion -qt-zlib -qt-libpng -qt-libjpeg -qt-pcre -skip qtandroidextras -skip qtmacextras -skip qtx11extras -qt-sql-sqlite -opengl desktop -ssl -openssl   -D _USING_V120_SDK71_ -I D:/sdk/openssl/1.0.2g/2008/x64/include -L D:/sdk/openssl/1.0.2g/2008/x64/lib
