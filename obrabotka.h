#ifndef OBRABOTKA_H
#define OBRABOTKA_H

#include <QObject>
#include <QVariantMap>
#include <QVariantList>
#include <QString>
#include <QStack>
#include <QMap>
#include <QEventLoop>
#include <QVector>
#include <QUrl>

class Obrabotka : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString currentFilePath READ currentFilePath WRITE setCurrentFilePath NOTIFY currentFilePathChanged)

public:
    explicit Obrabotka(QObject *parent = nullptr);

    QString currentFilePath() const;
    void setCurrentFilePath(const QString &filePath);

    Q_INVOKABLE void myPriem(QVariantList algoritm);
    Q_INVOKABLE void userInputReceived(const QString &input);
    Q_INVOKABLE void startDebugging(QVariantList algorithm, int startBlockId = -1);
    Q_INVOKABLE void stopDebugging();
    Q_INVOKABLE void debugStep();
    Q_INVOKABLE void debugStepBack();

    Q_INVOKABLE QVariantList loadAlgorithmFromFile(const QUrl &filePath);
    Q_INVOKABLE bool saveAlgorithmToFile(const QVariantList &algorithm, const QUrl &filePath);
    Q_INVOKABLE void createNewInstance(const QUrl &filePath);

    Q_INVOKABLE void saveSettings(const QVariantMap &settings);
    Q_INVOKABLE QVariantMap loadSettings();

    // Новая функция для проверки синтаксиса алгоритма
    Q_INVOKABLE QVariantList checkAlgorithmSyntax(const QVariantList& algorithm);

private:
    QString m_currentFilePath;
    struct VariableInfo {
        QVariant value;
        QString type;
        VariableInfo() = default;
        VariableInfo(const QVariant& v, const QString& t) : value(v), type(t) {}
    };

    enum VariableType { Unknown, Numeric, String, Boolean, Array };

    QMap<QString, VariableInfo> peremennieMap;
    QString vvod_peremennich_polsovatela;
    QEventLoop m_loop;
    bool m_waitingForInput = false;
    QString m_receivedInput;

    bool m_hasError = false;
    QString m_errorMessage;

    // Новая система отладки
    bool m_debugging = false;
    QVariantList m_currentAlgorithm;
    QMap<int, QVariantMap> m_blockMap;
    QMap<int, int> m_nextBlockIdMap;
    int m_currentDebugBlockId = -1;
    QVector<QVariantMap> m_algorithmStack;
    QVector<int> m_debugLoopStack;
    QStack<QVariantMap> m_debugHistory;
    QStack<int> m_blockIdHistory;
    int m_currentHistoryIndex = -1;
    QMap<int, bool> m_loopInitialized;

    void flattenAlgorithm(const QVariantList& algorithm, int& nextId);
    void vipolnenie(QVariantList algorithm);
    void vvod(const QString& variableName);
    void vivodim_functionod(QString peremen);
    void deistvie(QString vvod);
    void usl(QString usl, QVariantList trueBranch, QVariantList falseBranch);
    void schetchik(const QString& counterExpr, QVariantList loopBody);
    void predusl(const QString& condition, QVariantList loopBody);
    void postusl(const QString& condition, QVariantList loopBody);
    int requestUserInput();
    void setError(const QString& message);
    void clearError();

    // Новые функции для проверки синтаксиса
    void addSyntaxError(const QString& message, int blockId, QVariantList& errors);
    bool validateExpressionSyntax(const QString& expression, int blockId, QVariantList& errors, bool isConditionalContext = false);

    // Функции-помощники
    VariableType determineType(const QVariant& value);
    VariableType determineTypeFromString(const QString& value);
    QString typeToString(VariableType type);
    bool canConvertToNumber(const QString& str, double& result);
    bool isInteger(double value);
    QVariant getValue(const QString& name);
    QString getType(const QString& name);
    void setValue(const QString& name, const QVariant& value, const QString& type = "");
    QVariant parseExpression(const QString& expr);
    QStringList tokenize(const QString& expr);
    QVariant evaluateTokens(QStringList& tokens);
    bool evaluateCondition(const QString& condition);
    bool parseCondition(const QString& cond);
    bool evaluateSimpleCondition(const QString& cond);
    bool evaluateComplexCondition(QStringList& tokens);
    bool parseCounter(const QString& expr, QString& varName, int& startVal, int& endVal, int& stepVal);
    QVariant addValues(const QVariant& left, const QVariant& right);
    QVariant subtractValues(const QVariant& left, const QVariant& right);
    QVariant multiplyValues(const QVariant& left, const QVariant& right);
    QVariant divideValues(const QVariant& left, const QVariant& right);
    QVariant moduloValues(const QVariant& left, const QVariant& right);
    bool compareValues(const QVariant& left, const QVariant& right, const QString& op);
    void executeMethod(const QString& targetName, const QString& methodName, const QVariantList& args);

    // Новые функции для работы со встроенными функциями (len, int, str)
    QVariant callBuiltinFunction(const QString& funcName, const QVariantList& args);
    QVariant stringToInt(const QVariant& arg);
    QVariant anyToString(const QVariant& arg);

    // Функции для отладки
    void saveDebugState(int finishedBlockId);
    bool hasMoreBlocks();
    void sendCurrentState(int highlightId);
    void executeDebugBlock(const QVariantMap& block);
    int findNextBlockId(int currentId, bool& wasLoop);


    // Конвертация и восстановление состояния
    QVariantMap convertToQmlVariantMap() const;
    void restoreStateFromVariantMap(const QVariantMap& state);
    void internal_cleanup();

signals:
    void vivod(const QString &otvet_cpp);
    void needUserInput();
    void inputProcessed(const QString &result);
    void debugging_peremennie(QVariantMap peremennie);
    void highlightBlock(int blockId);
    void errorOccurred(const QString &errorMessage);
    void debugHistoryChanged(bool canStepBack, bool canStepForward);
    void debugFinished();
    void algorithmLoaded(QVariantList algorithm);
    void newAlgorithmSignal();
    void currentFilePathChanged();
    void fileSaved(const QString &filePath);
    void syntaxErrorsOccurred(const QVariantList& errors); // New signal
};

#endif // OBRABOTKA_H
