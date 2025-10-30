#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include "obrabotka.h"


int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    qmlRegisterType<Obrabotka>("myObrabotka", 1, 0, "Obrabotka");
    QQmlApplicationEngine engine;
    const QUrl url(u"qrc:/algoritm/main.qml"_qs);
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}
