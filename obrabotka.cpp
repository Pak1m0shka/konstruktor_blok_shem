#include "obrabotka.h"
#include <QQmlEngine>
#include <QDebug>
#include <QString>
#include <QRegularExpression>
#include <stack>
#include <algorithm>
#include <QVariantList>
#include <QMutex>
#include <QCoreApplication>
#include <QThread>
#include <QWaitCondition>
#include <cmath>

QVariantMap Obrabotka::convertToQmlVariantMap() const {
    QVariantMap map;
    for (auto it = peremennieMap.constBegin(); it != peremennieMap.constEnd(); ++it) {
        map[it.key()] = it.value().value;
    }
    return map;
}

void Obrabotka::restoreStateFromVariantMap(const QVariantMap& state) {
    peremennieMap.clear();
    for (auto it = state.constBegin(); it != state.constEnd(); ++it) {
        peremennieMap[it.key()] = VariableInfo(it.value(), "auto");
    }
}

Obrabotka::Obrabotka(QObject *parent) : QObject(parent) {}

// Функции для работы с типами
Obrabotka::VariableType Obrabotka::determineType(const QVariant& value) {
    if (value.type() == QVariant::Int) return Integer;
    if (value.type() == QVariant::Double) return Double;
    if (value.type() == QVariant::String) return String;
    if (value.type() == QVariant::Bool) return Boolean;
    return Unknown;
}

QString Obrabotka::typeToString(VariableType type) {
    switch (type) {
    case Integer: return "int";
    case Double: return "double";
    case String: return "string";
    case Boolean: return "bool";
    default: return "unknown";
    }
}

Obrabotka::VariableType Obrabotka::determineTypeFromString(const QString& value) {
    // Проверяем, является ли строка строковым литералом в одинарных кавычках
    if (value.length() >= 2 && value.startsWith('\'') && value.endsWith('\'')) {
        return String;
    }

    if (value.toLower() == "true" || value.toLower() == "false") {
        return Boolean;
    }

    bool ok;
    value.toInt(&ok);
    if (ok) return Integer;

    value.toDouble(&ok);
    if (ok) return Double;

    return String;
}

bool Obrabotka::canConvertToNumber(const QString& str, double& result) {
    // Если строка в кавычках, это не число
    if (str.length() >= 2 && str.startsWith('\'') && str.endsWith('\'')) {
        return false;
    }

    bool ok;
    result = str.toDouble(&ok);
    return ok;
}

bool Obrabotka::isInteger(double value) {
    return std::fabs(value - std::round(value)) < 1e-10;
}

// Функции операций
QVariant Obrabotka::addValues(const QVariant& left, const QVariant& right) {
    VariableType leftType = determineType(left);
    VariableType rightType = determineType(right);

    // Конкатенация строк
    if (leftType == String && rightType == String) {
        return left.toString() + right.toString();
    }

    // Сложение чисел
    if ((leftType == Integer || leftType == Double) && (rightType == Integer || rightType == Double)) {
        double leftVal = left.toDouble();
        double rightVal = right.toDouble();
        double result = leftVal + rightVal;

        if (leftType == Integer && rightType == Integer && isInteger(result)) {
            return QVariant(static_cast<int>(result));
        }
        return QVariant(result);
    }

    // Если типы несовместимы, преобразуем к строкам и конкатенируем
    return left.toString() + right.toString();
}

QVariant Obrabotka::subtractValues(const QVariant& left, const QVariant& right) {
    double leftVal = left.toDouble();
    double rightVal = right.toDouble();
    double result = leftVal - rightVal;

    if (determineType(left) == Integer && determineType(right) == Integer && isInteger(result)) {
        return QVariant(static_cast<int>(result));
    }
    return QVariant(result);
}

QVariant Obrabotka::multiplyValues(const QVariant& left, const QVariant& right) {
    double leftVal = left.toDouble();
    double rightVal = right.toDouble();
    double result = leftVal * rightVal;

    if (determineType(left) == Integer && determineType(right) == Integer && isInteger(result)) {
        return QVariant(static_cast<int>(result));
    }
    return QVariant(result);
}

QVariant Obrabotka::divideValues(const QVariant& left, const QVariant& right) {
    double rightVal = right.toDouble();
    if (qFuzzyIsNull(rightVal)) {
        return QVariant(0);
    }

    double leftVal = left.toDouble();
    double result = leftVal / rightVal;
    return QVariant(result);
}

QVariant Obrabotka::moduloValues(const QVariant& left, const QVariant& right) {
    int leftVal = left.toInt();
    int rightVal = right.toInt();
    if (rightVal == 0) {
        return QVariant(0);
    }
    return QVariant(leftVal % rightVal);
}

bool Obrabotka::compareValues(const QVariant& left, const QVariant& right, const QString& op) {
    VariableType leftType = determineType(left);
    VariableType rightType = determineType(right);

    // Сравнение строк - разрешаем только == и !=
    if (leftType == String && rightType == String) {
        QString leftStr = left.toString();
        QString rightStr = right.toString();

        if (op == "==") return leftStr == rightStr;
        if (op == "!=") return leftStr != rightStr;

        // Для строк запрещаем другие операции сравнения
        qDebug() << "Ошибка синтаксиса: для строк разрешены только операции == и !=";
        setError("Ошибка синтаксиса: для строк разрешены только операции == и !=");
        return false;
    }

    // Сравнение чисел
    if ((leftType == Integer || leftType == Double) && (rightType == Integer || rightType == Double)) {
        double leftVal = left.toDouble();
        double rightVal = right.toDouble();

        if (op == ">") return leftVal > rightVal;
        if (op == "<") return leftVal < rightVal;
        if (op == ">=") return leftVal >= rightVal;
        if (op == "<=") return leftVal <= rightVal;
        if (op == "==") return qFuzzyCompare(leftVal, rightVal);
        if (op == "!=") return !qFuzzyCompare(leftVal, rightVal);
    }

    // Сравнение булевых значений
    if (leftType == Boolean && rightType == Boolean) {
        bool leftVal = left.toBool();
        bool rightVal = right.toBool();

        if (op == "==") return leftVal == rightVal;
        if (op == "!=") return leftVal != rightVal;
    }

    return false;
}

// Функции для работы со строками
QVariant Obrabotka::stringLength(const QString& str) {
    return QVariant(str.length());
}

QVariant Obrabotka::stringIndex(const QString& str, int index) {
    if (index < 0 || index >= str.length()) {
        return QVariant("");
    }
    return QVariant(QString(str[index]));
}

QVariant Obrabotka::stringSlice(const QString& str, int start, int end) {
    if (start < 0) start = 0;
    if (end > str.length()) end = str.length();
    if (start > end) {
        return QVariant("");
    }
    return QVariant(str.mid(start, end - start));
}

QVariant Obrabotka::parseStringOperation(const QString& expr) {
    QString trimmed = expr.trimmed();

    // Обработка len(expression)
    QRegularExpression lenRegex(R"(len\s*\(\s*(\w+)\s*\))");
    QRegularExpressionMatch lenMatch = lenRegex.match(trimmed);
    if (lenMatch.hasMatch()) {
        QString varName = lenMatch.captured(1);
        QVariant value = getValue(varName);
        return stringLength(value.toString());
    }

    // Обработка индексации variable[index]
    QRegularExpression indexRegex(R"((\w+)\s*\[\s*(\-?\d+)\s*\])");
    QRegularExpressionMatch indexMatch = indexRegex.match(trimmed);
    if (indexMatch.hasMatch()) {
        QString varName = indexMatch.captured(1);
        int index = indexMatch.captured(2).toInt();
        QVariant value = getValue(varName);
        return stringIndex(value.toString(), index);
    }

    // Обработка срезов variable[start:end], variable[start:], variable[:end]
    QRegularExpression sliceRegex(R"((\w+)\s*\[\s*(\-?\d*)\s*:\s*(\-?\d*)\s*\])");
    QRegularExpressionMatch sliceMatch = sliceRegex.match(trimmed);
    if (sliceMatch.hasMatch()) {
        QString varName = sliceMatch.captured(1);
        QString startStr = sliceMatch.captured(2);
        QString endStr = sliceMatch.captured(3);

        QVariant value = getValue(varName);
        QString str = value.toString();
        int start = startStr.isEmpty() ? 0 : startStr.toInt();
        int end = endStr.isEmpty() ? str.length() : endStr.toInt();

        return stringSlice(str, start, end);
    }

    return QVariant();
}

void Obrabotka::setError(const QString& message) {
    m_hasError = true;
    m_errorMessage = message;
    qCritical() << "Ошибка:" << message;
    emit errorOccurred(message);
}

void Obrabotka::clearError() {
    m_hasError = false;
    m_errorMessage.clear();
}

//блок ввода
int Obrabotka::requestUserInput()
{
    qDebug() << "C++: Запрашиваем ввод пользователя";
    m_waitingForInput = true;
    emit needUserInput();
    m_loop.exec();
    return 1;
}

void Obrabotka::userInputReceived(const QString &input)
{
    qDebug() << "C++: Получен ввод:" << input;
    vvod_peremennich_polsovatela = input;
    if (m_waitingForInput) {
        m_receivedInput = input;
        m_waitingForInput = false;
        m_loop.quit();
    }
}

void Obrabotka::vvod(const QString& variableName) {
    if (!requestUserInput()) {
        return;
    }

    QString inputValue = vvod_peremennich_polsovatela;

    // Автоматическое определение типа
    VariableType detectedType = determineTypeFromString(inputValue);
    QVariant value;

    switch (detectedType) {
    case Integer:
        value = QVariant(inputValue.toInt());
        break;
    case Double:
        value = QVariant(inputValue.toDouble());
        break;
    case Boolean:
        value = QVariant(inputValue.toLower() == "true");
        break;
    case String:
    default:
        // Убираем кавычки если они есть
        if (inputValue.length() >= 2 && inputValue.startsWith('\'') && inputValue.endsWith('\'')) {
            value = QVariant(inputValue.mid(1, inputValue.length() - 2));
        } else {
            value = QVariant(inputValue);
        }
        break;
    }

    peremennieMap[variableName] = VariableInfo(value, typeToString(detectedType));

    qDebug() << "Ввод переменной:" << variableName << "=" << value;
}

// ответ
void Obrabotka::vivodim_functionod(QString peremen){
    qDebug() << "запуск вывода!";
    if (peremennieMap.contains(peremen)) {
        emit vivod(peremennieMap[peremen].value.toString());
    } else {
        emit vivod("Переменная " + peremen + " не найдена");
    }
}

//действие
QVariant Obrabotka::getValue(const QString& name) {
    if (peremennieMap.contains(name)) {
        return peremennieMap[name].value;
    }

    qDebug() << "Переменная" << name << "не найдена, создаем со значением 0";
    peremennieMap[name] = VariableInfo(QVariant(0), "int");
    return QVariant(0);
}

QString Obrabotka::getType(const QString& name) {
    if (peremennieMap.contains(name)) {
        return peremennieMap[name].type;
    }
    return "unknown";
}

void Obrabotka::setValue(const QString& name, const QVariant& value, const QString& type) {
    QString actualType = type;
    if (type.isEmpty()) {
        actualType = typeToString(determineType(value));
    }
    peremennieMap[name] = VariableInfo(value, actualType);
}

QStringList Obrabotka::tokenize(const QString& expr) {
    QStringList tokens;
    QString currentToken;
    bool inString = false;

    for (QChar ch : expr) {
        if (ch == '\'') {
            if (inString) {
                // Завершаем строку
                currentToken.append(ch);
                tokens.append(currentToken);
                currentToken.clear();
                inString = false;
            } else {
                // Начинаем новую строку
                if (!currentToken.isEmpty()) {
                    tokens.append(currentToken);
                    currentToken.clear();
                }
                currentToken.append(ch);
                inString = true;
            }
        } else if (inString) {
            // Внутри строки - добавляем все символы
            currentToken.append(ch);
        } else if (ch.isSpace()) {
            continue;
        } else if (ch == '(' || ch == ')' || ch == '+' || ch == '-' || ch == '*' || ch == '/' || ch == '%') {
            if (!currentToken.isEmpty()) {
                tokens.append(currentToken);
                currentToken.clear();
            }
            tokens.append(QString(ch));
        } else {
            currentToken.append(ch);
        }
    }

    if (!currentToken.isEmpty()) {
        tokens.append(currentToken);
    }

    return tokens;
}

QVariant Obrabotka::evaluateTokens(QStringList& tokens) {
    clearError();

    std::stack<int> bracketStack;
    for (int i = 0; i < tokens.size(); i++) {
        if (tokens[i] == "(") {
            bracketStack.push(i);
        } else if (tokens[i] == ")") {
            if (bracketStack.empty()) {
                return QVariant();
            }

            int start = bracketStack.top();
            bracketStack.pop();

            QStringList subTokens;
            for (int j = start + 1; j < i; j++) {
                subTokens.append(tokens[j]);
            }

            QVariant bracketResult = evaluateTokens(subTokens);
            if (m_hasError) return QVariant();

            tokens[start] = bracketResult.toString();
            for (int j = start + 1; j <= i; j++) {
                tokens.removeAt(start + 1);
            }
            i = start;
        }
    }

    if (!bracketStack.empty()) {
        return QVariant();
    }

    // Заменяем переменные на их значения и обрабатываем строки
    for (int i = 0; i < tokens.size(); i++) {
        if (tokens[i] != "+" && tokens[i] != "-" && tokens[i] != "*" &&
            tokens[i] != "/" && tokens[i] != "%" && tokens[i] != "(" && tokens[i] != ")") {

            // Проверяем, является ли токен строковым литералом
            if (tokens[i].length() >= 2 && tokens[i].startsWith('\'') && tokens[i].endsWith('\'')) {
                // Оставляем как есть - это строковый литерал
                continue;
            }

            // Проверяем, является ли токен числом
            bool isNumber;
            tokens[i].toDouble(&isNumber);
            if (!isNumber) {
                // Проверяем, не является ли это строковой операцией (индексация, срез)
                QVariant stringOpResult = parseStringOperation(tokens[i]);
                if (stringOpResult.isValid()) {
                    tokens[i] = stringOpResult.toString();
                } else {
                    // Если не строковая операция, то это переменная
                    tokens[i] = getValue(tokens[i]).toString();
                }
            }
        }
    }

    // Обработка операций *, /, %
    for (int i = 1; i < tokens.size() - 1; ) {
        if (tokens[i] == "*" || tokens[i] == "/" || tokens[i] == "%") {
            QVariant leftVal, rightVal;

            // Обрабатываем левый операнд
            if (tokens[i-1].length() >= 2 && tokens[i-1].startsWith('\'') && tokens[i-1].endsWith('\'')) {
                // Строковый литерал
                leftVal = QVariant(tokens[i-1].mid(1, tokens[i-1].length() - 2));
            } else {
                // Число или переменная
                double num;
                if (canConvertToNumber(tokens[i-1], num)) {
                    if (isInteger(num)) {
                        leftVal = QVariant(static_cast<int>(num));
                    } else {
                        leftVal = QVariant(num);
                    }
                } else {
                    leftVal = QVariant(tokens[i-1]);
                }
            }

            // Обрабатываем правый операнд
            if (tokens[i+1].length() >= 2 && tokens[i+1].startsWith('\'') && tokens[i+1].endsWith('\'')) {
                // Строковый литерал
                rightVal = QVariant(tokens[i+1].mid(1, tokens[i+1].length() - 2));
            } else {
                // Число или переменная
                double num;
                if (canConvertToNumber(tokens[i+1], num)) {
                    if (isInteger(num)) {
                        rightVal = QVariant(static_cast<int>(num));
                    } else {
                        rightVal = QVariant(num);
                    }
                } else {
                    rightVal = QVariant(tokens[i+1]);
                }
            }

            QVariant result;
            if (tokens[i] == "*") {
                result = multiplyValues(leftVal, rightVal);
            } else if (tokens[i] == "/") {
                result = divideValues(leftVal, rightVal);
            } else {
                result = moduloValues(leftVal, rightVal);
            }

            if (m_hasError) return QVariant();

            tokens[i-1] = result.toString();
            tokens.removeAt(i);
            tokens.removeAt(i);
        } else {
            i++;
        }
    }

    // Обработка операций +, -
    for (int i = 1; i < tokens.size() - 1; ) {
        if (tokens[i] == "+" || tokens[i] == "-") {
            QVariant leftVal, rightVal;

            // Обрабатываем левый операнд
            if (tokens[i-1].length() >= 2 && tokens[i-1].startsWith('\'') && tokens[i-1].endsWith('\'')) {
                // Строковый литерал
                leftVal = QVariant(tokens[i-1].mid(1, tokens[i-1].length() - 2));
            } else {
                // Число или переменная
                double num;
                if (canConvertToNumber(tokens[i-1], num)) {
                    if (isInteger(num)) {
                        leftVal = QVariant(static_cast<int>(num));
                    } else {
                        leftVal = QVariant(num);
                    }
                } else {
                    leftVal = QVariant(tokens[i-1]);
                }
            }

            // Обрабатываем правый операнд
            if (tokens[i+1].length() >= 2 && tokens[i+1].startsWith('\'') && tokens[i+1].endsWith('\'')) {
                // Строковый литерал
                rightVal = QVariant(tokens[i+1].mid(1, tokens[i+1].length() - 2));
            } else {
                // Число или переменная
                double num;
                if (canConvertToNumber(tokens[i+1], num)) {
                    if (isInteger(num)) {
                        rightVal = QVariant(static_cast<int>(num));
                    } else {
                        rightVal = QVariant(num);
                    }
                } else {
                    rightVal = QVariant(tokens[i+1]);
                }
            }

            QVariant result;
            if (tokens[i] == "+") {
                result = addValues(leftVal, rightVal);
            } else {
                result = subtractValues(leftVal, rightVal);
            }

            if (m_hasError) return QVariant();

            tokens[i-1] = result.toString();
            tokens.removeAt(i);
            tokens.removeAt(i);
        } else {
            i++;
        }
    }

    if (tokens.size() != 1) {
        return QVariant();
    }

    // Возвращаем результат в правильном типе
    QString resultStr = tokens[0];

    // Если результат - строковый литерал, возвращаем строку без кавычек
    if (resultStr.length() >= 2 && resultStr.startsWith('\'') && resultStr.endsWith('\'')) {
        return QVariant(resultStr.mid(1, resultStr.length() - 2));
    }

    double num;
    if (canConvertToNumber(resultStr, num)) {
        if (isInteger(num)) {
            return QVariant(static_cast<int>(num));
        } else {
            return QVariant(num);
        }
    }

    return QVariant(resultStr);
}

QVariant Obrabotka::parseExpression(const QString& expr) {
    // Сначала проверяем строковые операции
    QVariant stringOpResult = parseStringOperation(expr);
    if (stringOpResult.isValid()) {
        return stringOpResult;
    }

    // Если не строковая операция, парсим как обычное выражение
    QStringList tokens = tokenize(expr);
    return evaluateTokens(tokens);
}

void Obrabotka::deistvie(QString vvod) {
    clearError();

    vvod.remove(QRegularExpression("\\s+"));

    int equalsPos = vvod.indexOf('=');
    if (equalsPos == -1) {
        return;
    }

    QString left = vvod.left(equalsPos);
    QString right = vvod.mid(equalsPos + 1);

    if (left.isEmpty()) {
        return;
    }

    if (right.isEmpty()) {
        return;
    }

    QVariant result = parseExpression(right);
    if (m_hasError) {
        return;
    }

    setValue(left, result);
    qInfo() << "Присвоено переменной" << left << "значение:" << result;
}

// Новая универсальная функция проверки условий
bool Obrabotka::evaluateCondition(const QString& condition) {
    clearError();

    QString cond = condition.simplified();

    // Если условие - просто имя переменной
    if (peremennieMap.contains(cond)) {
        QVariant value = peremennieMap[cond].value;
        VariableType type = determineType(value);

        if (type == Boolean) {
            return value.toBool();
        }
        if (type == Integer || type == Double) {
            return value.toDouble() != 0;
        }
        if (type == String) {
            return !value.toString().isEmpty();
        }
        return false;
    }

    // Если условие - булево значение
    if (cond.toLower() == "true" || cond == "1") {
        return true;
    }
    if (cond.toLower() == "false" || cond == "0") {
        return false;
    }

    // Парсим сложное условие
    return parseCondition(cond);
}

// условие
void Obrabotka::usl(QString usl, QVariantList trueBranch, QVariantList falseBranch) {
    clearError();

    bool conditionResult = evaluateCondition(usl);

    if (m_hasError) {
        qDebug() << "Ошибка при проверке условия if";
        return;
    }

    if (conditionResult) {
        qDebug() << "Условие ИСТИНА, выполняем true ветку";
        vipolnenie(trueBranch);
    } else {
        qDebug() << "Условие ЛОЖЬ, выполняем false ветку";
        vipolnenie(falseBranch);
    }
}

bool Obrabotka::parseCondition(const QString& cond) {
    clearError();

    QString condition = cond.simplified();
    condition.replace(" ", "");

    qDebug() << "Парсим условие:" << condition;

    QString processedCondition = condition;

    // Заменяем русские логические операторы на английские
    processedCondition.replace(QRegularExpression("\\bи\\b"), " && ");
    processedCondition.replace(QRegularExpression("\\bили\\b"), " || ");
    processedCondition.replace(QRegularExpression("\\bне\\b"), " ! ");

    processedCondition = processedCondition.simplified();

    qDebug() << "Обработанное условие:" << processedCondition;

    if (processedCondition.contains("&&") || processedCondition.contains("||") || processedCondition.contains("!") ||
        processedCondition.contains("(") || processedCondition.contains(")")) {
        QStringList tokens;
        QString currentToken;
        bool inString = false;

        for (int i = 0; i < processedCondition.length(); i++) {
            QChar ch = processedCondition[i];

            if (ch == '\'') {
                if (inString) {
                    currentToken.append(ch);
                    tokens.append(currentToken);
                    currentToken.clear();
                    inString = false;
                } else {
                    if (!currentToken.isEmpty()) {
                        tokens.append(currentToken);
                        currentToken.clear();
                    }
                    currentToken.append(ch);
                    inString = true;
                }
            } else if (inString) {
                currentToken.append(ch);
            } else if (ch == '&' || ch == '|' || ch == '!' || ch == '(' || ch == ')') {
                if (!currentToken.isEmpty()) {
                    tokens.append(currentToken);
                    currentToken.clear();
                }
                if (ch == '&' && i + 1 < processedCondition.length() && processedCondition[i + 1] == '&') {
                    tokens.append("&&");
                    i++;
                } else if (ch == '|' && i + 1 < processedCondition.length() && processedCondition[i + 1] == '|') {
                    tokens.append("||");
                    i++;
                } else if (ch == '!') {
                    tokens.append("!");
                } else {
                    tokens.append(QString(ch));
                }
            } else {
                currentToken.append(ch);
            }
        }

        if (!currentToken.isEmpty()) {
            tokens.append(currentToken);
        }

        qDebug() << "Токены:" << tokens;
        return evaluateComplexCondition(tokens);
    } else {
        return evaluateSimpleCondition(processedCondition);
    }
}

bool Obrabotka::evaluateSimpleCondition(const QString& cond) {
    QString condition = cond;

    // Булевые значения
    if (condition == "1" || condition.toLower() == "true") {
        return true;
    }
    if (condition == "0" || condition.toLower() == "false") {
        return false;
    }

    QVector<QString> operators = {">=", "<=", "!=", "==", ">", "<"};
    QString foundOp;

    for (const QString& op : operators) {
        if (condition.contains(op)) {
            foundOp = op;
            break;
        }
    }

    if (foundOp.isEmpty()) {
        // Если нет оператора, проверяем как булево значение переменной
        QVariant value = getValue(condition);
        VariableType type = determineType(value);
        if (type == Boolean) {
            return value.toBool();
        }
        if (type == Integer || type == Double) {
            return value.toDouble() != 0;
        }
        if (type == String) {
            return !value.toString().isEmpty();
        }

        return false;
    }

    QStringList parts = condition.split(foundOp);
    if (parts.size() != 2) {
        return false;
    }

    QVariant leftVal = parseExpression(parts[0]);
    QVariant rightVal = parseExpression(parts[1]);

    if (m_hasError) return false;

    return compareValues(leftVal, rightVal, foundOp);
}

bool Obrabotka::evaluateComplexCondition(QStringList& tokens) {
    qDebug() << "Вычисляем сложное условие с токенами:" << tokens;

    // Обработка унарного НЕ (!)
    for (int i = 0; i < tokens.size(); ) {
        if (tokens[i] == "!") {
            if (i + 1 >= tokens.size()) {
                return false;
            }

            // Обрабатываем следующий токен после "!"
            bool operandValue;
            if (tokens[i+1] == "(") {
                // Находим соответствующую закрывающую скобку
                int bracketCount = 1;
                int j = i + 2;
                while (j < tokens.size() && bracketCount > 0) {
                    if (tokens[j] == "(") bracketCount++;
                    else if (tokens[j] == ")") bracketCount--;
                    j++;
                }

                QStringList subTokens;
                for (int k = i + 2; k < j - 1; k++) {
                    subTokens.append(tokens[k]);
                }

                operandValue = evaluateComplexCondition(subTokens);
            } else {
                operandValue = evaluateSimpleCondition(tokens[i+1]);
            }

            if (m_hasError) return false;

            tokens[i] = (!operandValue) ? "1" : "0";
            tokens.removeAt(i+1);
        } else {
            i++;
        }
    }

    std::stack<int> bracketStack;
    for (int i = 0; i < tokens.size(); i++) {
        if (tokens[i] == "(") {
            bracketStack.push(i);
        } else if (tokens[i] == ")") {
            if (bracketStack.empty()) {
                return false;
            }

            int start = bracketStack.top();
            bracketStack.pop();

            QStringList subTokens;
            for (int j = start + 1; j < i; j++) {
                subTokens.append(tokens[j]);
            }

            bool bracketResult = evaluateComplexCondition(subTokens);
            if (m_hasError) return false;

            tokens[start] = bracketResult ? "1" : "0";
            for (int j = start + 1; j <= i; j++) {
                tokens.removeAt(start + 1);
            }
            i = start;
        }
    }

    if (!bracketStack.empty()) {
        return false;
    }

    // Заменяем простые условия на "1" или "0"
    for (int i = 0; i < tokens.size(); i++) {
        if (tokens[i] != "&&" && tokens[i] != "||" && tokens[i] != "(" && tokens[i] != ")") {
            bool value = evaluateSimpleCondition(tokens[i]);
            if (m_hasError) return false;
            tokens[i] = value ? "1" : "0";
        }
    }

    // Обработка И (&&)
    for (int i = 1; i < tokens.size() - 1; ) {
        if (tokens[i] == "&&") {
            bool leftVal = (tokens[i-1] == "1");
            bool rightVal = (tokens[i+1] == "1");
            bool result = leftVal && rightVal;

            tokens[i-1] = result ? "1" : "0";
            tokens.removeAt(i);
            tokens.removeAt(i);
        } else {
            i++;
        }
    }

    // Обработка ИЛИ (||)
    for (int i = 1; i < tokens.size() - 1; ) {
        if (tokens[i] == "||") {
            bool leftVal = (tokens[i-1] == "1");
            bool rightVal = (tokens[i+1] == "1");
            bool result = leftVal || rightVal;

            tokens[i-1] = result ? "1" : "0";
            tokens.removeAt(i);
            tokens.removeAt(i);
        } else {
            i++;
        }
    }

    if (tokens.size() != 1) {
        return false;
    }

    return tokens[0] == "1";
}

// счетчик
void Obrabotka::schetchik(const QString& counterExpr, QVariantList loopBody) {
    clearError();

    qDebug() << "Запуск цикла for:" << counterExpr;
    qDebug() << "Тело цикла (размер):" << loopBody.size();

    QString varName;
    int startVal, endVal, stepVal;

    if (!parseCounter(counterExpr, varName, startVal, endVal, stepVal)) {
        return;
    }

    qDebug() << "Цикл for:" << varName << "от" << startVal << "до" << endVal << "шаг" << stepVal;

    if (stepVal == 0) {
        return;
    }

    if (stepVal > 0) {
        for (int i = startVal; i <= endVal; i += stepVal) {
            setValue(varName, QVariant(i), "int");
            if (!loopBody.isEmpty()) {
                vipolnenie(loopBody);
                if (m_hasError) return;
            } else {
                qDebug() << "Тело цикла пустое!";
            }
        }
    } else {
        for (int i = startVal; i >= endVal; i += stepVal) {
            setValue(varName, QVariant(i), "int");
            if (!loopBody.isEmpty()) {
                vipolnenie(loopBody);
                if (m_hasError) return;
            } else {
                qDebug() << "Тело цикла пустое!";
            }
        }
    }

    qDebug() << "Цикл for завершен";
}

bool Obrabotka::parseCounter(const QString& expr, QString& varName, int& startVal, int& endVal, int& stepVal) {
    QString expression = expr.simplified();
    expression.replace(" ", "");

    int toIndex = expression.indexOf("to");
    if (toIndex == -1) toIndex = expression.indexOf("до");

    if (toIndex == -1) {
        return false;
    }

    int equalsIndex = expression.indexOf("=");
    if (equalsIndex == -1 || equalsIndex >= toIndex) {
        return false;
    }

    varName = expression.left(equalsIndex);
    QString startStr = expression.mid(equalsIndex + 1, toIndex - equalsIndex - 1);

    int stepIndex = expression.indexOf("step", toIndex + 2, Qt::CaseInsensitive);
    if (stepIndex == -1) stepIndex = expression.indexOf("шаг", toIndex + 2, Qt::CaseInsensitive);

    QString endStr, stepStr;
    if (stepIndex != -1) {
        endStr = expression.mid(toIndex + 2, stepIndex - toIndex - 2);
        stepStr = expression.mid(stepIndex + (expression.mid(stepIndex, 1) == "s" ? 4 : 3));
    } else {
        endStr = expression.mid(toIndex + 2);
        stepStr = "1";
    }

    startVal = parseExpression(startStr).toInt();
    endVal = parseExpression(endStr).toInt();
    stepVal = parseExpression(stepStr).toInt();

    qDebug() << "Парсинг счетчика:" << varName << "=" << startVal << "to" << endVal << "step" << stepVal;

    return true;
}

void Obrabotka::predusl(const QString& condition, QVariantList loopBody) {
    clearError();

    qDebug() << "Запуск цикла while (предусловие):" << condition;
    qDebug() << "Тело цикла (размер):" << loopBody.size();

    int iteration = 0;
    const int MAX_ITERATIONS = 1000;

    // Цикл while: проверяем условие ПЕРЕД выполнением тела
    while (evaluateCondition(condition)) {
        if (m_hasError) {
            qDebug() << "Ошибка при проверке условия в цикле while";
            return;
        }

        iteration++;
        if (iteration > MAX_ITERATIONS) {
            qDebug() << "Превышено максимальное количество итераций в цикле while";
            return;
        }

        qDebug() << "Итерация while:" << iteration;

        if (!loopBody.isEmpty()) {
            vipolnenie(loopBody);
            if (m_hasError) {
                qDebug() << "Ошибка в теле цикла while";
                return;
            }
        } else {
            qDebug() << "Тело цикла while пустое!";
        }
    }

    qDebug() << "Цикл while завершен, итераций:" << iteration;
}

void Obrabotka::postusl(const QString& condition, QVariantList loopBody) {
    clearError();

    qDebug() << "Запуск цикла do-while (постусловие):" << condition;
    qDebug() << "Тело цикла (размер):" << loopBody.size();

    int iteration = 0;
    const int MAX_ITERATIONS = 1000;

    // Цикл do-while: выполняем тело минимум один раз
    do {
        iteration++;
        if (iteration > MAX_ITERATIONS) {
            qDebug() << "Превышено максимальное количество итераций в цикле do-while";
            return;
        }

        qDebug() << "Итерация do-while:" << iteration;

        // Выполняем тело цикла
        if (!loopBody.isEmpty()) {
            vipolnenie(loopBody);
            if (m_hasError) {
                qDebug() << "Ошибка в теле цикла do-while";
                return;
            }
        } else {
            qDebug() << "Тело цикла do-while пустое!";
        }

        // Проверяем условие ПОСЛЕ выполнения тела
        bool conditionResult = evaluateCondition(condition);
        qDebug() << "Проверка условия после итерации" << iteration << ":" << condition << "=" << conditionResult;

        if (m_hasError) {
            qDebug() << "Ошибка при проверке условия в цикле do-while";
            return;
        }

        // В do-while цикл продолжается, пока условие ИСТИННО
        // Если условие ложно - выходим
        if (!conditionResult) {
            qDebug() << "Условие ложно, завершаем цикл do-while";
            break;
        }

    } while (true);

    qDebug() << "Цикл do-while завершен, итераций:" << iteration;
}

void Obrabotka::vipolnenie(QVariantList algorithm) {
    clearError();

    qDebug() << ">>> ВЫПОЛНЕНИЕ АЛГОРИТМА (размер:" << algorithm.size() << ")";

    for (int i = 0; i < algorithm.size(); ++i) {
        if (m_hasError) {
            qDebug() << "Выполнение прервано из-за ошибки";
            return;
        }

        QVariant item = algorithm[i];
        qDebug() << "Обрабатываем блок" << i << ":" << item;

        if (!item.canConvert<QVariantList>()) {
            qDebug() << "Блок не может быть преобразован в QVariantList";
            continue;
        }

        QVariantList block = item.value<QVariantList>();
        qDebug() << "Распакованный блок:" << block;

        if (block.size() < 2) {
            qDebug() << "Блок слишком короткий, пропускаем";
            continue;
        }

        QString type = block[0].toString();
        QString content = block[1].toString();

        qDebug() << "Тип:" << type << "| Содержимое:" << content;

        if (type == "ввод") {
            vvod(content);
        } else if (type == "вывод") {
            vivodim_functionod(content);
        } else if (type == "действие") {
            deistvie(content);
        } else if (type == "усл") {
            QVariantList trueBranch = block.size() > 2 ? block[2].value<QVariantList>() : QVariantList();
            QVariantList falseBranch = block.size() > 3 ? block[3].value<QVariantList>() : QVariantList();
            qDebug() << "Условие - true ветка:" << trueBranch.size() << "блоков, false ветка:" << falseBranch.size() << "блоков";
            usl(content, trueBranch, falseBranch);
        } else if (type == "счетчик") {
            QVariantList loopBody = block.size() > 2 ? block[2].value<QVariantList>() : QVariantList();
            qDebug() << "Счетчик - тело цикла:" << loopBody.size() << "блоков";
            schetchik(content, loopBody);
        } else if (type == "предусл") {
            QVariantList loopBody = block.size() > 2 ? block[2].value<QVariantList>() : QVariantList();
            qDebug() << "Предусловие - тело цикла:" << loopBody.size() << "блоков";
            predusl(content, loopBody);
        } else if (type == "постусл") {
            QVariantList loopBody = block.size() > 2 ? block[2].value<QVariantList>() : QVariantList();
            qDebug() << "Постусловие - тело цикла:" << loopBody.size() << "блоков";
            postusl(content, loopBody);
        } else {
            qDebug() << "Неизвестный тип блока:" << type;
        }

        if (m_hasError) {
            qDebug() << "Ошибка в блоке" << i << ", тип:" << type;
            return;
        }
    }

    qDebug() << "<<< ЗАВЕРШЕНИЕ ВЫПОЛНЕНИЯ АЛГОРИТМА";
}

void Obrabotka::saveDebugState() {
    // Сохраняем текущее состояние в историю
    m_debugHistory.push(convertToQmlVariantMap());
    m_blockHistory.push(m_currentDebugBlock);
    m_algorithmHistory.push(m_currentAlgorithm);
    m_algorithmStackHistory.push(m_algorithmStack);

    // Сохраняем индекс выделяемого блока (текущий блок - 1)
    int highlightIndex = (m_currentDebugBlock > 0) ? (m_currentDebugBlock - 1) : -1;
    m_highlightHistory.push(highlightIndex);

    // Обновляем индекс истории
    m_currentHistoryIndex = m_debugHistory.size() - 1;

    qDebug() << "Сохранено состояние. Индекс истории:" << m_currentHistoryIndex
             << "Текущий блок:" << m_currentDebugBlock
             << "Выделяем:" << highlightIndex;
}

bool Obrabotka::hasMoreBlocks() {
    return m_currentDebugBlock < m_currentAlgorithm.size() || !m_algorithmStack.isEmpty() || !m_debugLoopStack.isEmpty();
}

void Obrabotka::sendCurrentState(int highlightIndex) {
    QVariantMap currentState = convertToQmlVariantMap();
    emit debugging_peremennie(currentState);
    emit highlightBlock(highlightIndex);
    emit debugHistoryChanged(m_currentHistoryIndex > 0, hasMoreBlocks());
}

void Obrabotka::executeDebugBlock(const QVariantList& block) {
    if (block.isEmpty()) {
        m_currentDebugBlock++;
        return;
    }
    QString type = block[0].toString();
    if (type == "ввод") {
        vvod(block[1].toString());
    } else if (type == "вывод") {
        vivodim_functionod(block[1].toString());
    } else if (type == "действие") {
        deistvie(block[1].toString());
    }
    m_currentDebugBlock++;
}

void Obrabotka::debugStep() {
    if (!m_debugging) return;
    clearError();
    saveDebugState();

    int blockToHighlight = m_currentDebugBlock;

    // Part 1: Handle end-of-scope transitions
    if (m_currentDebugBlock >= m_currentAlgorithm.size()) {
        // Finished a loop body?
        if (!m_debugLoopStack.isEmpty() && m_currentAlgorithm == m_debugLoopStack.top().body) {
            DebugLoopInfo& loop = m_debugLoopStack.top();
            blockToHighlight = loop.originalBlockIndex;
            // For do-while, we check condition after the body
            if (loop.type == "постусл") {
                if (evaluateCondition(loop.condition)) {
                    m_currentAlgorithm = loop.body;
                    m_currentDebugBlock = 0;
                } else {
                    m_debugLoopStack.pop();
                    auto p = m_algorithmStack.pop();
                    m_currentAlgorithm = p.first;
                    m_currentDebugBlock = p.second;
                }
            } else { // For for/while, we've finished a body and must return to the header
                if (loop.type == "счетчик") {
                    int currentVal = getValue(loop.counterVar).toInt() + loop.counterStep;
                    setValue(loop.counterVar, currentVal, "int");
                }
                m_currentAlgorithm = m_algorithmStack.top().first;
                m_currentDebugBlock = loop.originalBlockIndex;
            }
        }
        // Finished a simple 'if' branch?
        else if (!m_algorithmStack.isEmpty()) {
            auto p = m_algorithmStack.pop();
            m_currentAlgorithm = p.first;
            m_currentDebugBlock = p.second;
            blockToHighlight = m_currentDebugBlock;
        }
        // End of entire program
        else {
            stopDebugging();
            emit debugFinished();
            return;
        }
    }
    // Part 2: Process the current block
    else {
        QVariantList block = m_currentAlgorithm[m_currentDebugBlock].value<QVariantList>();
        QString type = block.isEmpty() ? "" : block[0].toString();

        if (type == "усл") {
            m_algorithmStack.push({m_currentAlgorithm, m_currentDebugBlock + 1});
            if (evaluateCondition(block[1].toString())) {
                m_currentAlgorithm = block[2].value<QVariantList>();
            } else {
                m_currentAlgorithm = block[3].value<QVariantList>();
            }
            m_currentDebugBlock = 0;
        } else if (type == "счетчик" || type == "предусл" || type == "постусл") {
            // Is this the first time we're seeing this block, or are we re-evaluating?
            if (m_debugLoopStack.isEmpty() || m_debugLoopStack.top().originalBlockIndex != m_currentDebugBlock) {
                // First time: set up the loop
                DebugLoopInfo loopInfo;
                loopInfo.type = type;
                loopInfo.condition = block[1].toString();
                loopInfo.body = block.size() > 2 ? block[2].value<QVariantList>() : QVariantList();
                loopInfo.originalBlockIndex = m_currentDebugBlock;
                m_debugLoopStack.push(loopInfo);

                if (type == "счетчик") {
                    int startVal;
                    if (parseCounter(loopInfo.condition, m_debugLoopStack.top().counterVar, startVal, m_debugLoopStack.top().counterEnd, m_debugLoopStack.top().counterStep)) {
                        setValue(m_debugLoopStack.top().counterVar, startVal, "int");
                    } else {
                        setError("Ошибка парсинга цикла for");
                        m_debugLoopStack.pop();
                        m_currentDebugBlock++;
                    }
                }
                // For 'post-condition', we immediately enter the body.
                else if (type == "постусл") {
                    m_algorithmStack.push({m_currentAlgorithm, m_currentDebugBlock + 1});
                    m_currentAlgorithm = loopInfo.body;
                    m_currentDebugBlock = 0;
                }
                // For 'for' and 'while', the next step will re-evaluate this same block. The PC doesn't move.
            } else { // Re-evaluating a loop header
                DebugLoopInfo& loop = m_debugLoopStack.top();
                bool conditionMet = false;
                if (loop.type == "счетчик") {
                    int currentVal = getValue(loop.counterVar).toInt();
                    conditionMet = (loop.counterStep >= 0) ? (currentVal <= loop.counterEnd) : (currentVal >= loop.counterEnd);
                } else { // 'предусл'
                    conditionMet = evaluateCondition(loop.condition);
                }

                if (conditionMet) {
                    m_algorithmStack.push({m_currentAlgorithm, m_currentDebugBlock + 1});
                    m_currentAlgorithm = loop.body;
                    m_currentDebugBlock = 0;
                } else {
                    m_debugLoopStack.pop();
                    m_currentDebugBlock++;
                }
            }
        } else {
            executeDebugBlock(block);
        }
    }
    sendCurrentState(blockToHighlight);
    qDebug() << "Отладка: текущий блок" << m_currentDebugBlock << ", размер алгоритма" << m_currentAlgorithm.size() << ", стек:" << m_algorithmStack.size();
}

void Obrabotka::debugStepBack() {
    if (m_currentHistoryIndex <= 0) {
        qDebug() << "Невозможно сделать шаг назад - история пуста";
        return;
    }

    // Удаляем текущее состояние из истории (последнее сохранение)
    m_debugHistory.pop();
    m_blockHistory.pop();
    m_algorithmHistory.pop();
    m_algorithmStackHistory.pop();
    m_highlightHistory.pop();

    // Обновляем индекс истории
    m_currentHistoryIndex = m_debugHistory.size() - 1;

    if (m_currentHistoryIndex < 0) {
        qDebug() << "История отладки пуста";
        return;
    }

    // Восстанавливаем состояние из предыдущей записи истории
    restoreStateFromVariantMap(m_debugHistory.top());
    m_currentAlgorithm = m_algorithmHistory.top();
    m_currentDebugBlock = m_blockHistory.top();
    m_algorithmStack = m_algorithmStackHistory.top();

    // Отправляем обновленные данные в QML
    emit debugging_peremennie(m_debugHistory.top());

    // Восстанавливаем сохраненный индекс выделения
    int highlightIndex = m_highlightHistory.top();
    emit highlightBlock(highlightIndex);

    emit debugHistoryChanged(m_currentHistoryIndex > 0, true);

    qDebug() << "Шаг назад. Текущий индекс истории:" << m_currentHistoryIndex
             << "Блок:" << m_currentDebugBlock
             << "Выделяем:" << highlightIndex;
}

void Obrabotka::stopDebugging() {
    m_debugging = false;
    m_currentDebugBlock = -1;
    m_debugHistory.clear();
    m_blockHistory.clear();
    m_algorithmHistory.clear();
    m_algorithmStackHistory.clear();
    m_highlightHistory.clear();
    m_currentHistoryIndex = -1;
    m_algorithmStack.clear();
    peremennieMap.clear();
    clearError();
    emit debugging_peremennie(QVariantMap());
    emit highlightBlock(-1);
    emit debugHistoryChanged(false, false);
}

void Obrabotka::startDebugging(QVariantList algorithm) {
    clearError();

    m_debugging = true;
    m_currentDebugBlock = 0;
    m_currentAlgorithm = algorithm;

    // Очищаем историю и переменные
    m_debugHistory.clear();
    m_blockHistory.clear();
    m_algorithmHistory.clear();
    m_algorithmStackHistory.clear();
    m_highlightHistory.clear();
    m_currentHistoryIndex = -1;
    m_algorithmStack.clear();
    peremennieMap.clear();
    clearError();

    // Сохраняем начальное состояние
    saveDebugState();

    // Сразу отправляем начальное состояние переменных
    QVariantMap currentState = convertToQmlVariantMap();
    emit debugging_peremennie(currentState);
    emit highlightBlock(-1); // Ничего не выделяем при старте
    emit debugHistoryChanged(false, hasMoreBlocks());

    qDebug() << ">>> НАЧАЛО ОТЛАДКИ (размер алгоритма:" << algorithm.size() << ")";
}

// кнопка запустить
void Obrabotka::myPriem(QVariantList algoritm)
{
    clearError();
    vipolnenie(algoritm);
    peremennieMap.clear();
}

// Новые функции для работы с файлами
bool Obrabotka::saveAlgorithmToFile(const QVariantList& algorithm, const QString& filename) {
    QFile file(filename);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text)) {
        return false;
    }

    QJsonArray jsonArray;
    for (const QVariant& item : algorithm) {
        if (item.canConvert<QVariantList>()) {
            QVariantList block = item.value<QVariantList>();
            QJsonArray blockArray;
            for (const QVariant& blockItem : block) {
                if (blockItem.canConvert<QVariantList>()) {
                    // Рекурсивно обрабатываем вложенные алгоритмы
                    QVariantList nestedAlgorithm = blockItem.value<QVariantList>();
                    QJsonArray nestedArray;
                    for (const QVariant& nestedItem : nestedAlgorithm) {
                        nestedArray.append(QJsonValue::fromVariant(nestedItem));
                    }
                    blockArray.append(nestedArray);
                } else {
                    blockArray.append(QJsonValue::fromVariant(blockItem));
                }
            }
            jsonArray.append(blockArray);
        } else {
            jsonArray.append(QJsonValue::fromVariant(item));
        }
    }

    QJsonDocument doc(jsonArray);
    file.write(doc.toJson());
    file.close();

    qDebug() << "Алгоритм успешно сохранен в файл:" << filename;
    return true;
}

QVariantList Obrabotka::loadAlgorithmFromFile(const QString& filename) {
    QVariantList result;

    QFile file(filename);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        emit errorOccurred("Не удалось открыть файл для чтения: " + filename);
        return result;
    }

    QByteArray data = file.readAll();
    file.close();

    QJsonParseError parseError;
    QJsonDocument doc = QJsonDocument::fromJson(data, &parseError);

    if (parseError.error != QJsonParseError::NoError) {
        QString errorMsg = "Ошибка при разборе JSON: " + parseError.errorString();
        emit errorOccurred(errorMsg);
        return result;
    }

    if (!doc.isArray()) {
        QString errorMsg = "Файл не содержит корректную структуру алгоритма";
        emit errorOccurred(errorMsg);
        return result;
    }

    QJsonArray jsonArray = doc.array();
    result = jsonArray.toVariantList();

    qDebug() << "Алгоритм успешно загружен из файла:" << filename;
    qDebug() << "Количество блоков:" << result.size();

    emit algorithmLoaded(result);
    return result;
}
