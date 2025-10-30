#ifndef OBRABOTKA_H
#define OBRABOTKA_H

#include <QObject>
#include <QVariant>
#include <QVariantList>
#include <QEventLoop>
#include <QString>
#include <vector>
#include <QPair>
#include <QStringList>

class Obrabotka : public QObject
{
    Q_OBJECT
public:
    explicit Obrabotka(QObject *parent = nullptr);

public slots:
    int requestUserInput();
    void myPriem(QVariantList algoritm);
    void userInputReceived(const QString &input);

signals:
    void needUserInput();
    void inputProcessed(const QString& result);
    void vivod(QString otvet_cpp);

private:
    QString m_pendingInput;

    void vvod(const QString& variableName);
    void vivodim_functionod(QString peremen);
    void vipolnenie(QVariantList algoritm);
    void deistvie(QString vvod);
    void usl(QString usl, QVariantList trueBranch, QVariantList falseBranch);
    void schetchik(const QString& counterExpr, QVariantList loopBody);
    bool parseCounter(const QString& expr, QString& varName, int& startVal, int& endVal, int& stepVal);
    void predusl(const QString& condition, QVariantList loopBody);
    void postusl(const QString& condition, QVariantList loopBody);

    int getValue(const QString& name);
    void setValue(const QString& name, int value);
    int parseExpression(const QString& expr);
    int evaluateTokens(QStringList& tokens);
    QStringList tokenize(const QString& expr);
    bool parseCondition(const QString& cond);
    bool evaluateSimpleCondition(const QString& cond);
    bool evaluateComplexCondition(QStringList& tokens);

    QEventLoop m_loop;
    QString m_receivedInput;
    bool m_waitingForInput = false;
    QString vvod_peremennich_polsovatela;
    std::vector<std::vector<QString>> peremennie;
};

#endif // OBRABOTKA_H
