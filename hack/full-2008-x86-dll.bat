@echo off

set PATH=%PATH%;D:/sdk/qt/5.6.3/src/gnuwin32/bin;D:/sdk/qt/5.6.3/src/build/qtbase/bin;

..\configure -mp -debug-and-release -shared -prefix "d:/sdk/qt/5.6.3/2008/x86" -opensource -confirm-license -platform win32-msvc2008 -nomake examples -nomake tests  -no-compile-examples -no-freetype  -no-harfbuzz -no-iconv -no-style-fusion  -qt-zlib -qt-libpng -qt-libjpeg -qt-pcre -skip qtandroidextras -skip qtmacextras -skip qtx11extras -qt-sql-sqlite -opengl desktop -ssl -openssl -direct2d -D _USING_V120_SDK71_ -I D:/sdk/openssl/1.0.2g/2008/x86/include -I "C:/Program Files/Microsoft SDKs/Windows/v7.0/Include" -L D:/sdk/openssl/1.0.2g/2008/x86/lib -L "C:/Program Files/Microsoft SDKs/Windows/v7.0/Lib"
