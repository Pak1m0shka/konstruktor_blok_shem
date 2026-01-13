#ifndef OBRABOTKA_H
#define OBRABOTKA_H

#include <QObject>
#include <QVariant>
#include <QVariantList>
#include <QEventLoop>
#include <QString>
#include <QStack>
#include <QMap>
#include <QFile>
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>
#include <QDir>

// Структура для хранения информации о переменной
struct VariableInfo {
    QVariant value;
    QString type;

    VariableInfo() : value(QVariant()), type("unknown") {}
    VariableInfo(const QVariant& val, const QString& t) : value(val), type(t) {}
};

Q_DECLARE_METATYPE(VariableInfo)

// Структура для хранения информации о цикле в режиме отладки
struct DebugLoopInfo {
    QString type; // "счетчик", "предусл", "постусл"
    QString condition;
    QVariantList body;
    int originalBlockIndex; // index in the parent algorithm

    // For "счетчик"
    QString counterVar;
    int counterEnd;
    int counterStep;
};

class Obrabotka : public QObject
{
    Q_OBJECT
public:
    explicit Obrabotka(QObject *parent = nullptr);

public slots:
    int requestUserInput();
    void myPriem(QVariantList algoritm);
    void userInputReceived(const QString &input);
    void startDebugging(QVariantList algorithm);
    void debugStep();
    void debugStepBack();
    void stopDebugging();
    bool saveAlgorithmToFile(const QVariantList& algorithm, const QString& filename);
    QVariantList loadAlgorithmFromFile(const QString& filename);

signals:
    void needUserInput();
    void inputProcessed(const QString& result);
    void vivod(QString otvet_cpp);
    void debugging_peremennie(QVariantMap peremennie);
    void highlightBlock(int blockIndex);
    void debugHistoryChanged(bool canStepBack, bool canStepForward);
    void debugFinished();
    void errorOccurred(const QString& errorMessage);
    void algorithmLoaded(QVariantList algorithm);

private:
    // Функции выполнения блоков
    void vvod(const QString& variableName);
    void vivodim_functionod(QString peremen);
    void vipolnenie(QVariantList algoritm);
    void deistvie(QString vvod);
    void usl(QString usl, QVariantList trueBranch, QVariantList falseBranch);
    void schetchik(const QString& counterExpr, QVariantList loopBody);
    bool parseCounter(const QString& expr, QString& varName, int& startVal, int& endVal, int& stepVal);
    void predusl(const QString& condition, QVariantList loopBody);
    void postusl(const QString& condition, QVariantList loopBody);

    // Функции для выражений и условий
    QVariant getValue(const QString& name);
    QString getType(const QString& name);
    void setValue(const QString& name, const QVariant& value, const QString& type = "");
    QVariant parseExpression(const QString& expr);
    QVariant evaluateTokens(QStringList& tokens);
    QStringList tokenize(const QString& expr);
    bool parseCondition(const QString& cond);
    bool evaluateSimpleCondition(const QString& cond);
    bool evaluateComplexCondition(QStringList& tokens);
    bool evaluateCondition(const QString& condition);

    // Функции для работы с типами
    enum VariableType { Integer, Double, String, Boolean, Unknown };
    VariableType determineType(const QVariant& value);
    QString typeToString(VariableType type);
    VariableType determineTypeFromString(const QString& value);
    bool canConvertToNumber(const QString& str, double& result);
    bool isInteger(double value);

    // Функции для операций с проверкой типов
    QVariant addValues(const QVariant& left, const QVariant& right);
    QVariant subtractValues(const QVariant& left, const QVariant& right);
    QVariant multiplyValues(const QVariant& left, const QVariant& right);
    QVariant divideValues(const QVariant& left, const QVariant& right);
    QVariant moduloValues(const QVariant& left, const QVariant& right);
    bool compareValues(const QVariant& left, const QVariant& right, const QString& op);

    // Функции для работы со строками
    QVariant stringLength(const QString& str);
    QVariant stringIndex(const QString& str, int index);
    QVariant stringSlice(const QString& str, int start, int end);
    QVariant parseStringOperation(const QString& expr);

    // Функции для работы с состоянием
    QVariantMap convertToQmlVariantMap() const;
    void restoreStateFromVariantMap(const QVariantMap& state);

    // Переменные для ввода
    QEventLoop m_loop;
    QString m_receivedInput;
    bool m_waitingForInput = false;
    QString vvod_peremennich_polsovatela;

    // Хранилище переменных (название -> информация о переменной)
    QMap<QString, VariableInfo> peremennieMap;

    // Отладочные переменные
    bool m_debugging = false;
    int m_currentDebugBlock = -1;

    // История для шага назад
    QStack<QVariantMap> m_debugHistory;
    QStack<int> m_blockHistory;
    QStack<QVariantList> m_algorithmHistory;
    QStack<QStack<QPair<QVariantList, int>>> m_algorithmStackHistory;
    int m_currentHistoryIndex = -1;
    QStack<int> m_highlightHistory;

    // Текущий алгоритм для отладки
    QVariantList m_currentAlgorithm;

    // Стек для вложенных алгоритмов
    QStack<QPair<QVariantList, int>> m_algorithmStack;

    // Стек для отладки циклов
    QStack<DebugLoopInfo> m_debugLoopStack;

    // Флаг ошибки
    bool m_hasError = false;
    QString m_errorMessage;

    // Вспомогательные функции для отладки
    void executeDebugBlock(const QVariantList& block);
    void saveDebugState();
    bool hasMoreBlocks();
    void sendCurrentState(int highlightIndex = -1);
    void setError(const QString& message);
    void clearError();
};

#endif // OBRABOTKA_H
