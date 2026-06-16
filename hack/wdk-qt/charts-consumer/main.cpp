// Proves the WDK7-built Qt5Charts is consumable via find_package(Qt5 Charts).
// QLineSeries is a plain QObject-derived series, so it links the Qt5Charts
// library and runs without needing a GUI application or platform plugin.
#include <QtCharts/QLineSeries>
#include <cstdio>

QT_CHARTS_USE_NAMESPACE

int main()
{
    QLineSeries* series = new QLineSeries();

    series->append(0, 6);
    series->append(2, 4);
    series->append(3, 8);

    int count = series->count();
    qreal lastX = series->at(count - 1).x();

    printf("Qt5Charts OK: points=%d lastX=%g\n", count, (double)lastX);

    delete series;
    return 0;
}
