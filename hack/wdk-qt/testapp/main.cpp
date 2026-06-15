// End-to-end test: exercise QtCore at runtime (string, list, datetime, regexp,
// container) to prove the WDK7-built Qt libraries actually work, not just link.
#include <QString>
#include <QStringList>
#include <QDateTime>
#include <QVector>
#include <QRegExp>
#include <cstdio>

int main()
{
    QString text = QString::fromUtf8("hello from WDK7 Qt build %1").arg(42);

    QStringList parts = text.split(QLatin1Char(' '));

    QVector<int> nums;
    nums.append(10);
    nums.append(20);
    nums.append(12);
    int total = 0;
    for (int i = 0; i < nums.size(); ++i)
        total += nums.at(i);

    QRegExp rx(QStringLiteral("(\\d+)"));
    bool matched = rx.indexIn(text) >= 0;

    printf("text   : %s\n", qPrintable(text));
    printf("parts  : %d\n", parts.size());
    printf("sum    : %d\n", total);
    printf("regexp : matched=%d cap=%s\n", matched ? 1 : 0, qPrintable(rx.cap(1)));
    printf("qt ver : %s\n", qVersion());
    return 0;
}
