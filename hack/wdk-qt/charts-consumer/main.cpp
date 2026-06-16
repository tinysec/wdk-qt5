// MDI GUI demo for the WDK7-built Qt5Charts: a QMainWindow with a QMdiArea whose
// child windows each show a different chart type (line, spline, pie, bar,
// scatter). A real windowed GUI app (WIN32 subsystem, no console). Pass
// "--shot <png>" to render the window to a PNG and exit (for automated checks);
// without it the app runs normally and stays open.
#include <QApplication>
#include <QMainWindow>
#include <QMdiArea>
#include <QMdiSubWindow>
#include <QMenuBar>
#include <QMenu>
#include <QAction>
#include <QString>
#include <QStringList>
#include <QPixmap>
#include <QPainter>

#include <QtCharts/QChart>
#include <QtCharts/QChartView>
#include <QtCharts/QLineSeries>
#include <QtCharts/QSplineSeries>
#include <QtCharts/QScatterSeries>
#include <QtCharts/QPieSeries>
#include <QtCharts/QPieSlice>
#include <QtCharts/QBarSeries>
#include <QtCharts/QBarSet>
#include <QtCharts/QBarCategoryAxis>

QT_CHARTS_USE_NAMESPACE

#if defined(NEED_STATIC_QPA)
#include <QtPlugin>
Q_IMPORT_PLUGIN(QWindowsIntegrationPlugin)
#endif

static QChart* makeLineChart()
{
    QLineSeries* revenue = new QLineSeries();
    revenue->setName("revenue");
    revenue->append(0, 6);
    revenue->append(1, 3);
    revenue->append(2, 8);
    revenue->append(3, 5);
    revenue->append(4, 9);

    QLineSeries* cost = new QLineSeries();
    cost->setName("cost");
    cost->append(0, 2);
    cost->append(1, 4);
    cost->append(2, 3);
    cost->append(3, 6);
    cost->append(4, 4);

    QChart* chart = new QChart();
    chart->addSeries(revenue);
    chart->addSeries(cost);
    chart->setTitle("Line");
    chart->createDefaultAxes();
    chart->legend()->setVisible(true);
    return chart;
}

static QChart* makeSplineChart()
{
    QSplineSeries* series = new QSplineSeries();
    series->setName("signal");
    series->append(0, 4);
    series->append(1, 7);
    series->append(2, 3);
    series->append(3, 8);
    series->append(4, 5);
    series->append(5, 9);

    QChart* chart = new QChart();
    chart->addSeries(series);
    chart->setTitle("Spline");
    chart->createDefaultAxes();
    chart->legend()->setVisible(false);
    return chart;
}

static QChart* makePieChart()
{
    QPieSeries* series = new QPieSeries();
    series->append("Alpha", 35);
    series->append("Beta", 25);
    series->append("Gamma", 20);
    series->append("Delta", 20);

    QPieSlice* alpha = series->slices().at(0);
    alpha->setExploded(true);
    alpha->setLabelVisible(true);

    QChart* chart = new QChart();
    chart->addSeries(series);
    chart->setTitle("Pie");
    chart->legend()->setVisible(true);
    return chart;
}

static QChart* makeBarChart()
{
    QBarSet* y2023 = new QBarSet("2023");
    y2023->append(5);
    y2023->append(3);
    y2023->append(8);
    y2023->append(6);

    QBarSet* y2024 = new QBarSet("2024");
    y2024->append(4);
    y2024->append(7);
    y2024->append(2);
    y2024->append(9);

    QBarSeries* series = new QBarSeries();
    series->append(y2023);
    series->append(y2024);

    QChart* chart = new QChart();
    chart->addSeries(series);
    chart->setTitle("Bars");

    QStringList categories;
    categories << "Q1" << "Q2" << "Q3" << "Q4";
    QBarCategoryAxis* axisX = new QBarCategoryAxis();
    axisX->append(categories);

    chart->createDefaultAxes();
    chart->setAxisX(axisX, series);
    chart->legend()->setVisible(true);
    return chart;
}

static QChart* makeScatterChart()
{
    QScatterSeries* series = new QScatterSeries();
    series->setName("samples");
    series->setMarkerSize(11);
    series->append(0.5, 4.2);
    series->append(1.4, 6.1);
    series->append(2.2, 3.4);
    series->append(3.6, 7.8);
    series->append(4.1, 5.0);
    series->append(4.9, 8.3);

    QChart* chart = new QChart();
    chart->addSeries(series);
    chart->setTitle("Scatter");
    chart->createDefaultAxes();
    chart->legend()->setVisible(false);
    return chart;
}

static void addChartWindow(QMdiArea* mdi, const QString& title, QChart* chart)
{
    QChartView* view = new QChartView(chart);
    view->setRenderHint(QPainter::Antialiasing);

    QMdiSubWindow* sub = mdi->addSubWindow(view);
    sub->setWindowTitle(title);
    sub->resize(460, 330);
}

int main(int argc, char** argv)
{
    QApplication app(argc, argv);

    QMainWindow window;
    window.setWindowTitle("WDK7 Qt5Charts - MDI demo");

    QMdiArea* mdi = new QMdiArea();
    window.setCentralWidget(mdi);

    addChartWindow(mdi, "Line", makeLineChart());
    addChartWindow(mdi, "Spline", makeSplineChart());
    addChartWindow(mdi, "Pie", makePieChart());
    addChartWindow(mdi, "Bars", makeBarChart());
    addChartWindow(mdi, "Scatter", makeScatterChart());

    QMenu* windowMenu = window.menuBar()->addMenu("&Window");
    QAction* tileAction = windowMenu->addAction("&Tile");
    QObject::connect(tileAction, SIGNAL(triggered()), mdi, SLOT(tileSubWindows()));
    QAction* cascadeAction = windowMenu->addAction("&Cascade");
    QObject::connect(cascadeAction, SIGNAL(triggered()), mdi, SLOT(cascadeSubWindows()));

    window.resize(1120, 760);
    window.show();
    mdi->tileSubWindows();

    // 1. Resolve the optional screenshot path (--shot <png>).
    QString shotPath;
    QStringList args = app.arguments();
    int shotIndex = args.indexOf("--shot");
    if (shotIndex >= 0 && shotIndex + 1 < args.size())
    {
        shotPath = args.at(shotIndex + 1);
    }

    // 2. Screenshot mode: render, save, exit. Otherwise run the GUI normally.
    if (!shotPath.isEmpty())
    {
        for (int i = 0; i < 8; ++i)
        {
            app.processEvents();
        }

        QPixmap shot = window.grab();
        shot.save(shotPath);
        return 0;
    }

    return app.exec();
}
