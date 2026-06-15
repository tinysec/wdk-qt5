#include <QObject>
#include <QString>
#include <QVector>
#include <cstdio>

// Q_OBJECT in a .cpp exercises AUTOMOC (needs moc.exe wired via the Qt package).
class Greeter : public QObject
{
    Q_OBJECT
public:
    QString greet() const { return QStringLiteral("hello from find_package(Qt5) over WDK7"); }
};

int main()
{
    Greeter greeter;

    QVector<int> v;
    v.append(20); v.append(22);
    int sum = 0;
    for (int i = 0; i < v.size(); ++i) sum += v.at(i);

    printf("%s sum=%d ver=%s\n", qPrintable(greeter.greet()), sum, qVersion());
    return 0;
}

#include "main.moc"
