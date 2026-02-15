#include "obrabotka.h"
#include <QQmlEngine>
#include <QDebug>
#include <QString>
#include <QRegularExpression>
#include <stack>
#include <QVariantList>
#include <QMutex>
#include <QCoreApplication>
#include <QThread>
#include <QWaitCondition>
#include <cmath>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QFile>
#include <QProcess>
#include <QSettings>

// ============================================================================
// ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ ДЛЯ РАБОТЫ С СОСТОЯНИЕМ ПЕРЕМЕННЫХ
// ============================================================================

// Преобразует внутреннюю карту переменных в QVariantMap для передачи в QML
QVariantMap Obrabotka::convertToQmlVariantMap() const
{
    QVariantMap map;
    for (auto it = peremennieMap.constBegin(); it != peremennieMap.constEnd(); ++it) {
        map[it.key()] = it.value().value;
    }
    return map;
}

// Восстанавливает состояние переменных из QVariantMap (для отладки/отката)
void Obrabotka::restoreStateFromVariantMap(const QVariantMap& state)
{
    peremennieMap.clear();
    for (auto it = state.constBegin(); it != state.constEnd(); ++it) {
        peremennieMap[it.key()] = VariableInfo(it.value(), "auto");
    }
}

// Конструктор класса обработчика алгоритмов
Obrabotka::Obrabotka(QObject *parent) : QObject(parent)
{
}

// ============================================================================
// РАБОТА С ТИПАМИ ДАННЫХ
// ============================================================================

// Определяет тип переменной на основе QVariant
Obrabotka::VariableType Obrabotka::determineType(const QVariant& value)
{
    switch (value.typeId()) {
    case QMetaType::Int:
    case QMetaType::Double: return Numeric;
    case QMetaType::QString: return String;
    case QMetaType::Bool: return Boolean;
    default: return Unknown;
    }
}

// Преобразует перечисление типа в строковое представление
QString Obrabotka::typeToString(VariableType type)
{
    switch (type) {
    case Numeric: return "numeric";
    case String: return "string";
    case Boolean: return "bool";
    default: return "unknown";
    }
}

// Определяет тип переменной по строковому представлению (для ввода пользователя)
Obrabotka::VariableType Obrabotka::determineTypeFromString(const QString& value)
{
    if (value.length() >= 2 && value.startsWith('"') && value.endsWith('"')) {
        return String;
    }
    if (value.toLower() == "true" || value.toLower() == "false") {
        return Boolean;
    }
    bool ok;
    value.toDouble(&ok);
    if (ok) return Numeric;
    return String;
}

// Проверяет, можно ли преобразовать строку в число, и возвращает результат
bool Obrabotka::canConvertToNumber(const QString& str, double& result)
{
    if (str.length() >= 2 && str.startsWith('"') && str.endsWith('"')) {
        return false;
    }
    bool ok;
    result = str.toDouble(&ok);
    return ok;
}

// Проверяет, является ли число целым (с точностью до 1e-10)
bool Obrabotka::isInteger(double value)
{
    return std::fabs(value - std::round(value)) < 1e-10;
}

// ============================================================================
// АРИФМЕТИЧЕСКИЕ И ЛОГИЧЕСКИЕ ОПЕРАЦИИ
// ============================================================================

// Выполняет сложение двух значений с проверкой типов (строки конкатенируются, числа складываются)
QVariant Obrabotka::addValues(const QVariant& left, const QVariant& right)
{
    qDebug() << "addValues called with left:" << left << "type:" << typeToString(determineType(left))
    << ", right:" << right << "type:" << typeToString(determineType(right));
    VariableType leftType = determineType(left);
    VariableType rightType = determineType(right);

    // Строгая проверка: нельзя складывать строку с числом без явного приведения
    if ((leftType == String && rightType == Numeric) || (leftType == Numeric && rightType == String)) {
        setError("Ошибка: Несовместимые типы для операции сложения. Нельзя складывать строку с числом без явного приведения типа (например, str(число) или использование кавычек).");
        return QVariant();
    }

    if (leftType == String || rightType == String) {
        QString result = left.toString() + right.toString();
        qDebug() << "addValues (string concat) result:" << result;
        return result;
    }

    if (leftType == Numeric && rightType == Numeric) {
        double leftVal = left.toDouble();
        double rightVal = right.toDouble();
        double result = leftVal + rightVal;
        qDebug() << "addValues (numeric sum) result:" << result;
        return QVariant(result);
    }

    setError("Ошибка: Несовместимые типы для операции сложения.");
    return QVariant();
}

// Выполняет вычитание двух числовых значений
QVariant Obrabotka::subtractValues(const QVariant& left, const QVariant& right)
{
    VariableType leftType = determineType(left);
    VariableType rightType = determineType(right);
    if (leftType == Numeric && rightType == Numeric) {
        double leftVal = left.toDouble();
        double rightVal = right.toDouble();
        double result = leftVal - rightVal;
        return QVariant(result);
    }
    setError("Ошибка: Несовместимые типы для операции вычитания.");
    return QVariant();
}

// Выполняет умножение двух числовых значений
QVariant Obrabotka::multiplyValues(const QVariant& left, const QVariant& right)
{
    VariableType leftType = determineType(left);
    VariableType rightType = determineType(right);
    if (leftType == Numeric && rightType == Numeric) {
        double leftVal = left.toDouble();
        double rightVal = right.toDouble();
        double result = leftVal * rightVal;
        return QVariant(result);
    }
    setError("Ошибка: Несовместимые типы для операции умножения.");
    return QVariant();
}

// Выполняет деление двух числовых значений с проверкой деления на ноль
QVariant Obrabotka::divideValues(const QVariant& left, const QVariant& right)
{
    VariableType leftType = determineType(left);
    VariableType rightType = determineType(right);
    if (leftType == Numeric && rightType == Numeric) {
        double rightVal = right.toDouble();
        if (qFuzzyIsNull(rightVal)) {
            setError("Ошибка: Деление на ноль.");
            return QVariant();
        }
        double leftVal = left.toDouble();
        double result = leftVal / rightVal;
        return QVariant(result);
    }
    setError("Ошибка: Несовместимые типы для операции деления.");
    return QVariant();
}

// Выполняет операцию по модулю (%) с проверкой целочисленности и деления на ноль
QVariant Obrabotka::moduloValues(const QVariant& left, const QVariant& right)
{
    VariableType leftType = determineType(left);
    VariableType rightType = determineType(right);
    if (leftType == Numeric && rightType == Numeric) {
        bool leftOk, rightOk;
        int leftVal = left.toInt(&leftOk);
        int rightVal = right.toInt(&rightOk);
        if (!leftOk || !rightOk) {
            setError("Ошибка: Для операции по модулю требуются целые числа.");
            return QVariant();
        }
        if (rightVal == 0) {
            setError("Ошибка: Деление на ноль при операции по модулю.");
            return QVariant();
        }
        return QVariant(leftVal % rightVal);
    }
    setError("Ошибка: Несовместимые типы для операции по модулю.");
    return QVariant();
}

// Сравнивает два значения по заданному оператору (>, <, ==, !=, >=, <=)
bool Obrabotka::compareValues(const QVariant& left, const QVariant& right, const QString& op)
{
    VariableType leftType = determineType(left);
    VariableType rightType = determineType(right);

    if (leftType == String && rightType == String) {
        QString leftStr = left.toString();
        QString rightStr = right.toString();
        if (op == "==") return leftStr == rightStr;
        if (op == "!=") return leftStr != rightStr;
        setError("Ошибка синтаксиса: для строк разрешены только операции == и != ");
        return false;
    }

    if (leftType == Numeric && rightType == Numeric) {
        double leftVal = left.toDouble();
        double rightVal = right.toDouble();
        if (op == ">") return leftVal > rightVal;
        if (op == "<") return leftVal < rightVal;
        if (op == ">=") return leftVal >= rightVal;
        if (op == "<=") return leftVal <= rightVal;
        if (op == "==") return qFuzzyCompare(leftVal, rightVal);
        if (op == "!=") return !qFuzzyCompare(leftVal, rightVal);
    }

    if (leftType == Boolean && rightType == Boolean) {
        bool leftVal = left.toBool();
        bool rightVal = right.toBool();
        if (op == "==") return leftVal == rightVal;
        if (op == "!=") return leftVal != rightVal;
    }

    setError("Ошибка: Несовместимые типы для операции сравнения.");
    return false;
}

// ============================================================================
// ОПЕРАЦИИ СО СТРОКАМИ
// ============================================================================

// Возвращает длину строки
QVariant Obrabotka::stringLength(const QString& str)
{
    return QVariant(str.length());
}

// Возвращает символ строки по индексу (поддерживает отрицательные индексы)
QVariant Obrabotka::stringIndex(const QString& str, int index)
{
    int len = str.length();
    if (index < 0) {
        index = len + index;
    }
    if (index < 0 || index >= len) {
        setError("Ошибка: Индекс строки выходит за границы.");
        return QVariant();
    }
    return QVariant(QString(str[index]));
}

// Возвращает срез строки по диапазону индексов (поддерживает отрицательные индексы и пустые границы)
QVariant Obrabotka::stringSlice(const QString& str, int start, int end)
{
    int len = str.length();
    if (start < 0) {
        start = len + start;
    }
    if (end < 0) {
        end = len + end;
    }
    start = qMax(0, start);
    end = qMin(len, end);
    if (start >= end) {
        return QVariant("");
    }
    return QVariant(str.mid(start, end - start));
}

// Парсит и выполняет строковые операции: len(), индексация [], срез [:]
QVariant Obrabotka::parseStringOperation(const QString& expr)
{
    QString trimmed = expr.trimmed();

    // len(переменная)
    QRegularExpression lenRegex(R"(len\s*\(\s*(\w+)\s*\))");
    QRegularExpressionMatch lenMatch = lenRegex.match(trimmed);
    if (lenMatch.hasMatch()) {
        QString varName = lenMatch.captured(1);
        QVariant value = getValue(varName);
        return stringLength(value.toString());
    }

    // переменная[индекс]
    QRegularExpression indexRegex(R"((\w+)\s*\[\s*(\-?\d+)\s*\])");
    QRegularExpressionMatch indexMatch = indexRegex.match(trimmed);
    if (indexMatch.hasMatch()) {
        QString varName = indexMatch.captured(1);
        int index = indexMatch.captured(2).toInt();
        QVariant value = getValue(varName);
        return stringIndex(value.toString(), index);
    }

    // переменная[начало:конец]
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

// ============================================================================
// СИНТАКСИЧЕСКИЙ АНАЛИЗ
// ============================================================================

// Добавляет ошибку синтаксиса в список ошибок с указанием ID блока
void Obrabotka::addSyntaxError(const QString& message, int blockId, QVariantList& errors)
{
    QVariantMap error;
    error["message"] = message;
    error["blockId"] = blockId;
    errors.append(error);
    qDebug() << "Syntax Error (Block ID:" << blockId << "):" << message;
}

// Проверяет синтаксис выражения: баланс скобок, кавычек, корректность операторов
bool Obrabotka::validateExpressionSyntax(const QString& expression, int blockId, QVariantList& errors, bool isConditionalContext)
{
    bool hasLocalErrors = false;
    QString expr = expression.trimmed();

    if (expr.isEmpty()) {
        addSyntaxError("Выражение не может быть пустым.", blockId, errors);
        hasLocalErrors = true;
        return !hasLocalErrors;
    }

    // Проверка использования = вместо == в условиях
    if (isConditionalContext) {
        if (expr.contains('=')) {
            if (!expr.contains("==") && !expr.contains(">=") && !expr.contains("<=") && !expr.contains("!=")) {
                addSyntaxError("Оператор присваивания '=' не разрешен в условиях. Используйте '==' для сравнения.", blockId, errors);
                hasLocalErrors = true;
            }
        }
    }

    // Проверка баланса скобок и кавычек
    QStack<QChar> stack;
    QMap<QChar, QChar> matchingBrackets = {
        {'(', ')'}, {'[', ']'}
    };
    bool inString = false;
    for (int i = 0; i < expr.length(); ++i) {
        QChar ch = expr[i];
        if (ch == '"') {
            inString = !inString;
        } else if (!inString) {
            if (matchingBrackets.keys().contains(ch)) {
                stack.push(ch);
            } else if (matchingBrackets.values().contains(ch)) {
                if (stack.isEmpty()) {
                    addSyntaxError("Несогласованная закрывающая скобка '" + QString(ch) + "' на позиции " + QString::number(i), blockId, errors);
                    hasLocalErrors = true;
                } else {
                    QChar openBracket = stack.pop();
                    if (matchingBrackets[openBracket] != ch) {
                        addSyntaxError("Несогласованная закрывающая скобка '" + QString(ch) + "' на позиции " + QString::number(i) +
                                           ". Ожидалась '" + QString(matchingBrackets[openBracket]) + "'", blockId, errors);
                        hasLocalErrors = true;
                    }
                }
            }
        }
    }

    if (inString) {
        addSyntaxError("Незакрытая кавычка.", blockId, errors);
        hasLocalErrors = true;
    }
    if (!stack.isEmpty()) {
        addSyntaxError("Незакрытая открывающая скобка '" + QString(stack.top()) + "'.", blockId, errors);
        hasLocalErrors = true;
    }

    // Проверка повторяющихся операторов (++, --, ** и т.д.)
    QRegularExpression doubleOpRegex(R"([+\-*/%]{2})");
    if (expr.contains(doubleOpRegex)) {
        addSyntaxError("Обнаружен повторяющийся оператор (например, ++, --, **).", blockId, errors);
        hasLocalErrors = true;
    }

    // Проверка операторов в начале/конце выражения (кроме унарного минуса)
    QString operators = "+-*/%";
    bool leadingOpError = false;
    bool trailingOpError = false;

    if (expr.length() > 0) {
        QChar firstChar = expr.at(0);
        if (operators.contains(firstChar)) {
            if (firstChar == '-') {
                QString remaining = expr.mid(1).trimmed();
                if (!remaining.isEmpty() && (remaining.at(0).isDigit() || remaining.at(0).isLetter() ||
                                             remaining.startsWith("(") || remaining.startsWith("\""))) {
                    // Корректный унарный минус
                } else {
                    leadingOpError = true;
                }
            } else {
                leadingOpError = true;
            }
        }
    }

    if (expr.length() > 0 && operators.contains(expr.at(expr.length() - 1))) {
        trailingOpError = true;
    }

    if (leadingOpError || trailingOpError) {
        addSyntaxError("Оператор в начале или конце выражения.", blockId, errors);
        hasLocalErrors = true;
    }

    // Проверка двух операторов подряд (с учетом унарного минуса)
    QRegularExpression invalidOpSequence(R"([+\-*/%]\s*[+\-*/%])");
    QString tempCodeForOpCheck = expr;
    tempCodeForOpCheck.replace(QRegularExpression(R"(-\s*\d+)"), "1");
    tempCodeForOpCheck.replace(QRegularExpression(R"(-\s*\"[^\"]*\")"), "\"1\"");
    if (tempCodeForOpCheck.contains(invalidOpSequence)) {
        addSyntaxError("Неправильное расположение операторов (возможно, два оператора подряд).", blockId, errors);
        hasLocalErrors = true;
    }

    return !hasLocalErrors;
}

// ============================================================================
// ОБРАБОТКА ОШИБОК
// ============================================================================

// Устанавливает флаг ошибки и сохраняет сообщение об ошибке
void Obrabotka::setError(const QString& message)
{
    m_hasError = true;
    m_errorMessage = message;
    qCritical() << "Ошибка:" << message;
    emit errorOccurred(message);
}

// Сбрасывает флаг ошибки и очищает сообщение
void Obrabotka::clearError()
{
    m_hasError = false;
    m_errorMessage.clear();
}

// ============================================================================
// БЛОК ВВОДА ДАННЫХ
// ============================================================================

// Запрашивает ввод от пользователя (синхронная блокирующая операция)
int Obrabotka::requestUserInput()
{
    qDebug() << "C++: Запрашиваем ввод пользователя";
    m_waitingForInput = true;
    emit needUserInput();
    m_loop.exec();
    return 1;
}

// Обрабатывает полученный от пользователя ввод
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

// Выполняет операцию ввода: запрашивает значение и сохраняет в переменную с автоматическим определением типа
void Obrabotka::vvod(const QString& variableName)
{
    if (!requestUserInput()) {
        return;
    }
    QString inputValue = vvod_peremennich_polsovatela;
    VariableType detectedType = determineTypeFromString(inputValue);
    QVariant value;

    switch (detectedType) {
    case Numeric:
        value = QVariant(inputValue.toDouble());
        break;
    case Boolean:
        value = QVariant(inputValue.toLower() == "true");
        break;
    case String:
    default:
        if (inputValue.length() >= 2 && inputValue.startsWith('"') && inputValue.endsWith('"')) {
            value = QVariant(inputValue.mid(1, inputValue.length() - 2));
        } else {
            value = QVariant(inputValue);
        }
        break;
    }

    peremennieMap[variableName] = VariableInfo(value, typeToString(detectedType));
    qDebug() << "Ввод переменной:" << variableName << "=" << value;
}

// ============================================================================
// БЛОК ВЫВОДА ДАННЫХ
// ============================================================================

// Выполняет операцию вывода значения переменной
void Obrabotka::vivodim_functionod(QString peremen)
{
    qDebug() << "запуск вывода!";
    if (peremennieMap.contains(peremen)) {
        emit vivod(peremennieMap[peremen].value.toString());
    } else {
        emit vivod("Переменная " + peremen + " не найдена");
    }
}

// ============================================================================
// РАБОТА С ПЕРЕМЕННЫМИ
// ============================================================================

// Возвращает значение переменной по имени (создает переменную со значением 0, если не существует)
QVariant Obrabotka::getValue(const QString& name)
{
    if (peremennieMap.contains(name)) {
        return peremennieMap[name].value;
    }
    qDebug() << "Переменная" << name << "не найдена, создаем со значением 0";
    peremennieMap[name] = VariableInfo(QVariant(0), "int");
    return QVariant(0);
}

// Возвращает тип переменной по имени
QString Obrabotka::getType(const QString& name)
{
    if (peremennieMap.contains(name)) {
        return peremennieMap[name].type;
    }
    return "unknown";
}

// Устанавливает значение и тип переменной
void Obrabotka::setValue(const QString& name, const QVariant& value, const QString& type)
{
    QString actualType = type;
    if (type.isEmpty()) {
        actualType = typeToString(determineType(value));
    }
    peremennieMap[name] = VariableInfo(value, actualType);
}

// ============================================================================
// ТОКЕНИЗАЦИЯ И ВЫЧИСЛЕНИЕ ВЫРАЖЕНИЙ
// ============================================================================

// Разбивает выражение на токены (числа, переменные, операторы, скобки, строки)
QStringList Obrabotka::tokenize(const QString& expr)
{
    QStringList tokens;
    QString currentToken;
    bool inString = false;

    for (QChar ch : expr) {
        if (ch == '"') {
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

// Вычисляет значение выражения по списку токенов (с обработкой скобок и приоритета операторов)
QVariant Obrabotka::evaluateTokens(QStringList& tokens)
{
    clearError();
    std::stack<int> bracketStack;

    // Обработка вложенных скобок
    for (int i = 0; i < tokens.size(); i++) {
        if (tokens[i] == "(") {
            bracketStack.push(i);
        } else if (tokens[i] == ")") {
            if (bracketStack.empty()) {
                setError("Ошибка: Несоответствующая закрывающая скобка.");
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
        setError("Ошибка: Несоответствующая открывающая скобка.");
        return QVariant();
    }

    // Предварительная обработка токенов: замена переменных, строковых операций и литералов
    for (int i = 0; i < tokens.size(); ++i) {
        QString token = tokens[i].trimmed();

        // Пропускаем операторы и скобки
        if (token == "(" || token == ")" || token == "+" || token == "-" || token == "*" ||
            token == "/" || token == "%" || token == "&&" || token == "||" || token == "!" ||
            token == ">=" || token == "<=" || token == "!=" || token == "==" || token == ">" || token == "<") {
            continue;
        }

        // Строковые литералы оставляем как есть
        if (token.startsWith('"') && token.endsWith('"') && token.length() >= 2) {
            continue;
        }

        // Числовые литералы стандартизируем
        double num;
        if (canConvertToNumber(token, num)) {
            tokens[i] = QVariant(num).toString();
            continue;
        }

        // Строковые операции (len, индексация, срез)
        QVariant stringOpResult = parseStringOperation(token);
        if (stringOpResult.isValid()) {
            if (stringOpResult.typeId() == QMetaType::QString) {
                tokens[i] = "\"" + stringOpResult.toString() + "\"";
            } else {
                tokens[i] = stringOpResult.toString();
            }
            continue;
        }

        // Переменные заменяем на их значения
        QVariant varValue = getValue(token);
        if (varValue.typeId() == QMetaType::QString) {
            tokens[i] = "\"" + varValue.toString() + "\"";
        } else {
            tokens[i] = varValue.toString();
        }
    }

    // Выполнение умножения, деления и модуля (приоритет 1)
    for (int i = 1; i < tokens.size() - 1; ) {
        if (tokens[i] == "*" || tokens[i] == "/" || tokens[i] == "%") {
            QVariant leftVal, rightVal;

            if (tokens[i-1].length() >= 2 && tokens[i-1].startsWith('"') && tokens[i-1].endsWith('"')) {
                leftVal = QVariant(tokens[i-1].mid(1, tokens[i-1].length() - 2));
            } else {
                double num;
                if (canConvertToNumber(tokens[i-1], num)) {
                    leftVal = QVariant(num);
                } else {
                    leftVal = getValue(tokens[i-1]);
                }
            }

            if (tokens[i+1].length() >= 2 && tokens[i+1].startsWith('"') && tokens[i+1].endsWith('"')) {
                rightVal = QVariant(tokens[i+1].mid(1, tokens[i+1].length() - 2));
            } else {
                double num;
                if (canConvertToNumber(tokens[i+1], num)) {
                    rightVal = QVariant(num);
                } else {
                    rightVal = getValue(tokens[i+1]);
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

    // Выполнение сложения и вычитания (приоритет 2)
    for (int i = 1; i < tokens.size() - 1; ) {
        if (tokens[i] == "+" || tokens[i] == "-") {
            QVariant leftVal, rightVal;

            if (tokens[i-1].length() >= 2 && tokens[i-1].startsWith('"') && tokens[i-1].endsWith('"')) {
                leftVal = QVariant(tokens[i-1].mid(1, tokens[i-1].length() - 2));
            } else {
                double num;
                if (canConvertToNumber(tokens[i-1], num)) {
                    leftVal = QVariant(num);
                } else {
                    leftVal = getValue(tokens[i-1]);
                }
            }

            if (tokens[i+1].length() >= 2 && tokens[i+1].startsWith('"') && tokens[i+1].endsWith('"')) {
                rightVal = QVariant(tokens[i+1].mid(1, tokens[i+1].length() - 2));
            } else {
                double num;
                if (canConvertToNumber(tokens[i+1], num)) {
                    rightVal = QVariant(num);
                } else {
                    rightVal = getValue(tokens[i+1]);
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

    // Проверка корректности результата
    if (tokens.size() != 1) {
        setError("Ошибка: Некорректное выражение.");
        return QVariant();
    }

    QString resultStr = tokens[0];
    if (resultStr.length() >= 2 && resultStr.startsWith('"') && resultStr.endsWith('"')) {
        return QVariant(resultStr.mid(1, resultStr.length() - 2));
    }
    double num;
    if (canConvertToNumber(resultStr, num)) {
        return QVariant(num);
    }
    return QVariant(resultStr);
}

// Парсит и вычисляет арифметическое выражение
QVariant Obrabotka::parseExpression(const QString& expr)
{
    QStringList tokens = tokenize(expr);
    return evaluateTokens(tokens);
}

// ============================================================================
// БЛОК ДЕЙСТВИЯ (ПРИСВАИВАНИЕ)
// ============================================================================

// Выполняет операцию присваивания: вычисляет правую часть и сохраняет в переменную
void Obrabotka::deistvie(QString vvod)
{
    clearError();
    qDebug() << "deistvie input:" << vvod;
    vvod.remove(QRegularExpression("\\s+"));
    int equalsPos = vvod.indexOf('=');
    if (equalsPos == -1) {
        return;
    }
    QString left = vvod.left(equalsPos);
    QString right = vvod.mid(equalsPos + 1);
    if (left.isEmpty() || right.isEmpty()) {
        return;
    }
    QVariant result = parseExpression(right);
    if (m_hasError) {
        qDebug() << "deistvie: Ошибка при разборе выражения:" << m_errorMessage;
        return;
    }
    setValue(left, result);
    qInfo() << "Присвоено переменной" << left << "значение:" << result;
}

// ============================================================================
// УСЛОВНЫЕ ВЫРАЖЕНИЯ
// ============================================================================

// Вычисляет условие: поддерживает переменные, логические литералы и сложные выражения
bool Obrabotka::evaluateCondition(const QString& condition)
{
    clearError();
    QString cond = condition.simplified();

    // Проверка переменной как условия
    if (peremennieMap.contains(cond)) {
        QVariant value = peremennieMap[cond].value;
        VariableType type = determineType(value);
        if (type == Boolean) return value.toBool();
        if (type == Numeric) return value.toDouble() != 0;
        if (type == String) return !value.toString().isEmpty();
        return false;
    }

    // Логические литералы
    if (cond.toLower() == "true" || cond == "1") return true;
    if (cond.toLower() == "false" || cond == "0") return false;

    return parseCondition(cond);
}

// ============================================================================
// УСЛОВНЫЙ ОПЕРАТОР (ЕСЛИ)
// ============================================================================

// Выполняет условный оператор: проверяет условие и выполняет соответствующую ветку
void Obrabotka::usl(QString usl, QVariantList trueBranch, QVariantList falseBranch)
{
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

// ============================================================================
// ПАРСИНГ И ВЫЧИСЛЕНИЕ УСЛОВИЙ
// ============================================================================

// Парсит условие: заменяет русские ключевые слова на логические операторы и обрабатывает сложные выражения
bool Obrabotka::parseCondition(const QString& cond)
{
    clearError();
    QString condition = cond.simplified();
    condition.replace(" ", "");

    qDebug() << "Парсим условие:" << condition;
    QString processedCondition = condition;
    processedCondition.replace(QRegularExpression("\\bи\\b"), " && ");
    processedCondition.replace(QRegularExpression("\\bили\\b"), " || ");
    processedCondition.replace(QRegularExpression("\\bне\\b"), " ! ");
    processedCondition = processedCondition.simplified();
    qDebug() << "Обработанное условие:" << processedCondition;

    // Обработка сложных условий с логическими операторами и скобками
    if (processedCondition.contains("&&") || processedCondition.contains("||") || processedCondition.contains("!") ||
        processedCondition.contains("(") || processedCondition.contains(")")) {
        QStringList tokens;
        QString currentToken;
        bool inString = false;

        for (int i = 0; i < processedCondition.length(); i++) {
            QChar ch = processedCondition[i];
            if (ch == '"') {
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

// Вычисляет простое условие (без логических операторов И/ИЛИ)
bool Obrabotka::evaluateSimpleCondition(const QString& cond)
{
    QString condition = cond;

    // Логические литералы
    if (condition == "1" || condition.toLower() == "true") return true;
    if (condition == "0" || condition.toLower() == "false") return false;

    // Поиск оператора сравнения
    QVector<QString> operators = { ">=", "<=", "!=", "==", ">", "<" };
    QString foundOp;
    for (const QString& op : operators) {
        if (condition.contains(op)) {
            foundOp = op;
            break;
        }
    }

    // Если нет оператора сравнения - проверяем значение переменной как условие
    if (foundOp.isEmpty()) {
        QVariant value = getValue(condition);
        VariableType type = determineType(value);
        if (type == Boolean) return value.toBool();
        if (type == Numeric) return value.toDouble() != 0;
        if (type == String) return !value.toString().isEmpty();
        return false;
    }

    // Сравнение двух значений
    QStringList parts = condition.split(foundOp);
    if (parts.size() != 2) return false;
    QVariant leftVal = parseExpression(parts[0]);
    QVariant rightVal = parseExpression(parts[1]);
    if (m_hasError) return false;
    return compareValues(leftVal, rightVal, foundOp);
}

// Вычисляет сложное условие с логическими операторами И/ИЛИ/НЕ и вложенными скобками
bool Obrabotka::evaluateComplexCondition(QStringList& tokens)
{
    qDebug() << "Вычисляем сложное условие с токенами:" << tokens;

    // Обработка оператора НЕ (!)
    for (int i = 0; i < tokens.size(); ) {
        if (tokens[i] == "!") {
            if (i + 1 >= tokens.size()) return false;
            bool operandValue;
            if (tokens[i+1] == "(") {
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

    // Обработка вложенных скобок
    std::stack<int> bracketStack;
    for (int i = 0; i < tokens.size(); i++) {
        if (tokens[i] == "(") {
            bracketStack.push(i);
        } else if (tokens[i] == ")") {
            if (bracketStack.empty()) return false;
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
    if (!bracketStack.empty()) return false;

    // Замена простых условий на 0/1
    for (int i = 0; i < tokens.size(); i++) {
        if (tokens[i] != "&&" && tokens[i] != "||" && tokens[i] != "(" && tokens[i] != ")") {
            bool value = evaluateSimpleCondition(tokens[i]);
            if (m_hasError) return false;
            tokens[i] = value ? "1" : "0";
        }
    }

    // Выполнение операций И (&&) - приоритет 1
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

    // Выполнение операций ИЛИ (||) - приоритет 2
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

    if (tokens.size() != 1) return false;
    return tokens[0] == "1";
}

// ============================================================================
// ЦИКЛ С ПАРАМЕТРОМ (СЧЕТЧИК)
// ============================================================================

// Выполняет цикл for с заданным счетчиком и телом цикла
void Obrabotka::schetchik(const QString& counterExpr, QVariantList loopBody)
{
    clearError();
    qDebug() << "Запуск цикла for:" << counterExpr;
    qDebug() << "Тело цикла (размер):" << loopBody.size();

    QString varName;
    int startVal, endVal, stepVal;
    if (!parseCounter(counterExpr, varName, startVal, endVal, stepVal)) {
        return;
    }

    qDebug() << "Цикл for:" << varName << "от" << startVal << "до" << endVal << "шаг" << stepVal;
    if (stepVal == 0) return;

    // Цикл с положительным шагом
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
        // Цикл с отрицательным шагом
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

// Парсит выражение счетчика цикла (формат: переменная = начало до конец шаг шаг)
bool Obrabotka::parseCounter(const QString& expr, QString& varName, int& startVal, int& endVal, int& stepVal)
{
    QString expression = expr.simplified();
    expression.replace(" ", "");

    int toIndex = expression.indexOf("to");
    if (toIndex == -1) toIndex = expression.indexOf("до");
    if (toIndex == -1) return false;

    int equalsIndex = expression.indexOf("=");
    if (equalsIndex == -1 || equalsIndex >= toIndex) return false;

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

// ============================================================================
// ЦИКЛ С ПРЕДУСЛОВИЕМ (WHILE)
// ============================================================================

// Выполняет цикл while: проверяет условие перед каждой итерацией
void Obrabotka::predusl(const QString& condition, QVariantList loopBody)
{
    clearError();
    qDebug() << "Запуск цикла while (предусловие):" << condition;
    qDebug() << "Тело цикла (размер):" << loopBody.size();

    int iteration = 0;
    const int MAX_ITERATIONS = 1000;

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

// ============================================================================
// ЦИКЛ С ПОСТУСЛОВИЕМ (DO-WHILE)
// ============================================================================

// Выполняет цикл do-while: выполняет тело цикла, затем проверяет условие
void Obrabotka::postusl(const QString& condition, QVariantList loopBody)
{
    clearError();
    qDebug() << "Запуск цикла do-while (постусловие):" << condition;
    qDebug() << "Тело цикла (размер):" << loopBody.size();

    int iteration = 0;
    const int MAX_ITERATIONS = 1000;

    do {
        iteration++;
        if (iteration > MAX_ITERATIONS) {
            qDebug() << "Превышено максимальное количество итераций в цикле do-while";
            return;
        }
        qDebug() << "Итерация do-while:" << iteration;
        if (!loopBody.isEmpty()) {
            vipolnenie(loopBody);
            if (m_hasError) {
                qDebug() << "Ошибка в теле цикла do-while";
                return;
            }
        } else {
            qDebug() << "Тело цикла do-while пустое!";
        }

        bool conditionResult = evaluateCondition(condition);
        qDebug() << "Проверка условия после итерации" << iteration << ":" << condition << "=" << conditionResult;
        if (m_hasError) {
            qDebug() << "Ошибка при проверке условия в цикле do-while";
            return;
        }
        if (!conditionResult) {
            qDebug() << "Условие ложно, завершаем цикл do-while";
            break;
        }
    } while (true);

    qDebug() << "Цикл do-while завершен, итераций:" << iteration;
}

// ============================================================================
// ОСНОВНОЙ ИНТЕРПРЕТАТОР АЛГОРИТМА
// ============================================================================

// Выполняет алгоритм, представленный в виде списка блоков
void Obrabotka::vipolnenie(QVariantList algorithm)
{
    clearError();
    qDebug() << ">>> ВЫПОЛНЕНИЕ АЛГОРИТМА (размер:" << algorithm.size() << ")";

    for (int i = 0; i < algorithm.size(); ++i) {
        if (m_hasError) {
            qDebug() << "Выполнение прервано из-за ошибки";
            return;
        }

        QVariant item = algorithm[i];
        qDebug() << "Обрабатываем блок" << i << ":" << item;

        if (!item.canConvert<QVariantMap>()) {
            qDebug() << "Блок не может быть преобразован в QVariantMap";
            continue;
        }

        QVariantMap block = item.value<QVariantMap>();
        qDebug() << "Распакованный блок:" << block;

        QString type = block["type"].toString();
        QString content = block["input"].toString();
        qDebug() << "Тип:" << type << "| Содержимое:" << content;

        if (type == "ввод") {
            vvod(content);
        } else if (type == "вывод") {
            vivodim_functionod(content);
        } else if (type == "действие") {
            deistvie(content);
        } else if (type == "усл") {
            QVariantList trueBranch = block["trueBranch"].value<QVariantList>();
            QVariantList falseBranch = block["falseBranch"].value<QVariantList>();
            qDebug() << "Условие - true ветка:" << trueBranch.size() << "блоков, false ветка:" << falseBranch.size() << "блоков";
            usl(content, trueBranch, falseBranch);
        } else if (type == "счетчик") {
            QVariantList loopBody = block["loopBody"].value<QVariantList>();
            qDebug() << "Счетчик - тело цикла:" << loopBody.size() << "блоков";
            schetchik(content, loopBody);
        } else if (type == "предусл") {
            QVariantList loopBody = block["loopBody"].value<QVariantList>();
            qDebug() << "Предусловие - тело цикла:" << loopBody.size() << "блоков";
            predusl(content, loopBody);
        } else if (type == "постусл") {
            QVariantList loopBody = block["loopBody"].value<QVariantList>();
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

// ============================================================================
// ОТЛАДКА: СОХРАНЕНИЕ СОСТОЯНИЙ
// ============================================================================

// Сохраняет текущее состояние переменных и ID завершенного блока в историю отладки
void Obrabotka::saveDebugState(int finishedBlockId)
{
    m_debugHistory.push(convertToQmlVariantMap());
    m_blockIdHistory.push(finishedBlockId);
    m_currentHistoryIndex = m_debugHistory.size() - 1;
    qDebug() << "Сохранено состояние. Индекс истории:" << m_currentHistoryIndex
             << "ID завершенного блока:" << finishedBlockId;
}

// Проверяет, есть ли следующие блоки для выполнения в режиме отладки
bool Obrabotka::hasMoreBlocks()
{
    return m_currentDebugBlockId != -1;
}

// Отправляет текущее состояние переменных и подсвечивает текущий блок в UI
void Obrabotka::sendCurrentState(int highlightId)
{
    QVariantMap currentState = convertToQmlVariantMap();
    emit debugging_peremennie(currentState);
    emit highlightBlock(highlightId);
    emit debugHistoryChanged(m_currentHistoryIndex > 0, hasMoreBlocks());
}

// ============================================================================
// ОТЛАДКА: ВЫПОЛНЕНИЕ ОДИНОЧНОГО БЛОКА
// ============================================================================

// Выполняет один блок алгоритма в режиме отладки (без вложенных структур)
void Obrabotka::executeDebugBlock(const QVariantMap& block)
{
    if (block.isEmpty()) {
        return;
    }

    QString type = block["type"].toString();
    QString content = block["input"].toString();

    if (type == "ввод") {
        vvod(content);
    } else if (type == "вывод") {
        vivodim_functionod(content);
    } else if (type == "действие") {
        deistvie(content);
    }
}

// ============================================================================
// ОТЛАДКА: ОЧИСТКА СОСТОЯНИЯ
// ============================================================================

// Полная очистка состояния отладчика и переменных
void Obrabotka::internal_cleanup()
{
    m_debugging = false;
    m_currentDebugBlockId = -1;
    m_debugHistory.clear();
    m_blockIdHistory.clear();
    m_loopInitialized.clear();
    m_currentHistoryIndex = -1;
    m_algorithmStack.clear();
    m_debugLoopStack.clear();
    peremennieMap.clear();
    clearError();
}

// ============================================================================
// ОТЛАДКА: ПЛОСКАЯ СТРУКТУРА АЛГОРИТМА
// ============================================================================

// Преобразует древовидную структуру алгоритма в плоскую карту блоков для пошаговой отладки
void Obrabotka::flattenAlgorithm(const QVariantList& algorithm, int& nextId)
{
    for (int i = 0; i < algorithm.size(); ++i) {
        const QVariantMap& block = algorithm[i].value<QVariantMap>();
        if (!block.contains("uniqueId")) {
            qWarning() << "flattenAlgorithm: Пропускаем блок без uniqueId:" << block;
            continue;
        }

        int blockId = block["uniqueId"].toInt();
        m_blockMap.insert(blockId, block);

        int nextSequentialId = (i + 1 < algorithm.size())
                                   ? algorithm[i + 1].value<QVariantMap>()["uniqueId"].toInt()
                                   : nextId;

        m_nextBlockIdMap.insert(blockId, nextSequentialId);

        QString type = block["type"].toString();
        if (type == "усл") {
            flattenAlgorithm(block["trueBranch"].value<QVariantList>(), nextSequentialId);
            flattenAlgorithm(block["falseBranch"].value<QVariantList>(), nextSequentialId);
        } else if (type == "счетчик" || type == "предусл" || type == "постусл") {
            flattenAlgorithm(block["loopBody"].value<QVariantList>(), blockId);
        }
    }
}

// ============================================================================
// ОТЛАДКА: ПОИСК СЛЕДУЮЩЕГО БЛОКА
// ============================================================================

// Определяет следующий блок для выполнения с учетом логики ветвлений и циклов
int Obrabotka::findNextBlockId(int currentId, bool& wasLoop)
{
    wasLoop = false;
    if (!m_blockMap.contains(currentId)) return -1;

    QVariantMap currentBlock = m_blockMap.value(currentId);
    QString type = currentBlock["type"].toString();
    QString content = currentBlock["input"].toString();
    int nextSequentialId = m_nextBlockIdMap.value(currentId, -1);

    if (type == "усл") {
        return evaluateCondition(content)
        ? (currentBlock["trueBranch"].value<QVariantList>().isEmpty()
               ? nextSequentialId
               : currentBlock["trueBranch"].value<QVariantList>().first().value<QVariantMap>()["uniqueId"].toInt())
        : (currentBlock["falseBranch"].value<QVariantList>().isEmpty()
               ? nextSequentialId
               : currentBlock["falseBranch"].value<QVariantList>().first().value<QVariantMap>()["uniqueId"].toInt());
    } else if (type == "счетчик") {
        wasLoop = true;
        QString varName;
        int startVal, endVal, stepVal;
        parseCounter(content, varName, startVal, endVal, stepVal);

        if (!m_loopInitialized.contains(currentId)) {
            setValue(varName, startVal, "int");
            m_loopInitialized[currentId] = true;
        } else {
            setValue(varName, getValue(varName).toInt() + stepVal, "int");
        }

        if ((stepVal >= 0) ? (getValue(varName).toInt() <= endVal) : (getValue(varName).toInt() >= endVal)) {
            const QVariantList& loopBody = currentBlock["loopBody"].value<QVariantList>();
            return loopBody.isEmpty()
                       ? currentId
                       : loopBody.first().value<QVariantMap>()["uniqueId"].toInt();
        } else {
            m_loopInitialized.remove(currentId);
            return nextSequentialId;
        }
    } else if (type == "предусл") {
        wasLoop = true;
        if (evaluateCondition(content)) {
            const QVariantList& loopBody = currentBlock["loopBody"].value<QVariantList>();
            return loopBody.isEmpty()
                       ? currentId
                       : loopBody.first().value<QVariantMap>()["uniqueId"].toInt();
        } else {
            return nextSequentialId;
        }
    } else if (type == "постусл") {
        wasLoop = true;
        const QVariantList& loopBody = currentBlock["loopBody"].value<QVariantList>();
        return loopBody.isEmpty()
                   ? currentId
                   : loopBody.first().value<QVariantMap>()["uniqueId"].toInt();
    } else {
        return nextSequentialId;
    }
}

// ============================================================================
// ОТЛАДКА: ЗАПУСК И УПРАВЛЕНИЕ
// ============================================================================

// Запускает режим отладки с возможностью установки начальной точки выполнения
void Obrabotka::startDebugging(QVariantList algorithm, int startBlockId)
{
    QVariantList syntaxErrors = checkAlgorithmSyntax(algorithm);
    if (!syntaxErrors.isEmpty()) {
        emit syntaxErrorsOccurred(syntaxErrors);
        return;
    }

    internal_cleanup();
    m_currentAlgorithm = algorithm;
    m_blockMap.clear();
    m_nextBlockIdMap.clear();

    int endOfMain = -1;
    flattenAlgorithm(m_currentAlgorithm, endOfMain);
    m_debugging = true;

    int firstBlockId = m_currentAlgorithm.isEmpty()
                           ? -1
                           : m_currentAlgorithm.first().value<QVariantMap>()["uniqueId"].toInt();

    // Бесшумное выполнение до указанной точки останова
    if (startBlockId != -1 && m_blockMap.contains(startBlockId) && startBlockId != firstBlockId) {
        qDebug() << "Бесшумный запуск до блока" << startBlockId;
        int blockToRun = firstBlockId;
        int runLimit = 10000;

        while (blockToRun != -1 && blockToRun != startBlockId && runLimit-- > 0) {
            if (m_hasError) {
                stopDebugging();
                return;
            }
            QVariantMap block = m_blockMap.value(blockToRun);
            QString type = block["type"].toString();
            if (type != "усл" && type != "счетчик" && type != "предусл" && type != "постусл") {
                executeDebugBlock(block);
            }
            bool wasLoopUnused;
            blockToRun = findNextBlockId(blockToRun, wasLoopUnused);
        }

        if (runLimit <= 0) {
            setError("Превышен лимит итераций при подготовке к отладке. Возможен бесконечный цикл.");
            stopDebugging();
            return;
        }
    }

    saveDebugState(-1);

    if (startBlockId != -1 && m_blockMap.contains(startBlockId)) {
        m_currentDebugBlockId = startBlockId;
    } else {
        m_currentDebugBlockId = firstBlockId;
    }

    sendCurrentState(-1);
    qDebug() << ">>> НАЧАЛО ОТЛАДКИ (карта блоков:" << m_blockMap.size() << "шт.). Стартовый блок:" << m_currentDebugBlockId;
}

// ============================================================================
// ОТЛАДКА: ПОШАГОВОЕ ВЫПОЛНЕНИЕ
// ============================================================================

// Выполняет один шаг отладки: текущий блок -> сохранение состояния -> переход к следующему
void Obrabotka::debugStep()
{
    if (!m_debugging || m_currentDebugBlockId == -1) {
        if (m_debugging) {
            stopDebugging();
        }
        return;
    }

    clearError();
    int idOfBlockToExecute = m_currentDebugBlockId;
    QVariantMap currentBlock = m_blockMap.value(idOfBlockToExecute);
    QString type = currentBlock["type"].toString();

    if (type != "усл" && type != "счетчик" && type != "предусл" && type != "постусл") {
        executeDebugBlock(currentBlock);
    }

    bool wasLoop = false;
    int nextBlockId = findNextBlockId(idOfBlockToExecute, wasLoop);

    // Специальная обработка цикла do-while при возврате к началу тела
    if (type == "постусл" && !wasLoop) {
        bool isLoopingBack = (m_blockIdHistory.size() > 1 &&
                              m_nextBlockIdMap.value(m_blockIdHistory.top(), -1) == idOfBlockToExecute);
        if (isLoopingBack) {
            if (evaluateCondition(currentBlock["input"].toString())) {
                const QVariantList& loopBody = currentBlock["loopBody"].value<QVariantList>();
                nextBlockId = loopBody.isEmpty()
                                  ? idOfBlockToExecute
                                  : loopBody.first().value<QVariantMap>()["uniqueId"].toInt();
            } else {
                nextBlockId = m_nextBlockIdMap.value(idOfBlockToExecute, -1);
            }
        }
    }

    if (m_hasError) {
        stopDebugging();
        return;
    }

    saveDebugState(idOfBlockToExecute);
    m_currentDebugBlockId = nextBlockId;
    sendCurrentState(idOfBlockToExecute);
}

// ============================================================================
// ОТЛАДКА: ВОЗВРАТ НА ШАГ НАЗАД
// ============================================================================

// Откатывает выполнение на один шаг назад с восстановлением состояния переменных
void Obrabotka::debugStepBack()
{
    if (m_debugHistory.size() < 2) return;

    m_debugHistory.pop();
    int undoneBlockId = m_blockIdHistory.top();
    m_blockIdHistory.pop();
    restoreStateFromVariantMap(m_debugHistory.top());
    int blockIdToShow = m_blockIdHistory.top();

    m_currentDebugBlockId = undoneBlockId;
    m_loopInitialized.clear();
    m_currentHistoryIndex--;

    sendCurrentState(blockIdToShow);
}

// ============================================================================
// ОТЛАДКА: ЗАВЕРШЕНИЕ
// ============================================================================

// Полностью останавливает режим отладки и очищает все состояния
void Obrabotka::stopDebugging()
{
    internal_cleanup();
    emit debugging_peremennie(QVariantMap());
    emit highlightBlock(-1);
    emit debugHistoryChanged(false, false);
    emit debugFinished();
}

// ============================================================================
// ОСНОВНОЙ ЗАПУСК АЛГОРИТМА
// ============================================================================

// Запускает выполнение алгоритма с предварительной проверкой синтаксиса
void Obrabotka::myPriem(QVariantList algoritm)
{
    clearError();
    QVariantList syntaxErrors = checkAlgorithmSyntax(algoritm);
    if (!syntaxErrors.isEmpty()) {
        emit syntaxErrorsOccurred(syntaxErrors);
        return;
    }
    vipolnenie(algoritm);
    peremennieMap.clear();
}

// ============================================================================
// РАБОТА С ФАЙЛАМИ
// ============================================================================

// Возвращает текущий путь к открытому файлу алгоритма
QString Obrabotka::currentFilePath() const
{
    return m_currentFilePath;
}

// Устанавливает текущий путь к файлу и уведомляет об изменении
void Obrabotka::setCurrentFilePath(const QString &filePath)
{
    if (m_currentFilePath != filePath) {
        m_currentFilePath = filePath;
        emit currentFilePathChanged();
    }
}

// Создает новый экземпляр приложения с загрузкой указанного файла
void Obrabotka::createNewInstance(const QUrl &filePath)
{
    QProcess::startDetached(QCoreApplication::applicationFilePath(), QStringList() << filePath.toLocalFile());
    QCoreApplication::quit();
}

// Сохраняет алгоритм в файл в формате JSON
bool Obrabotka::saveAlgorithmToFile(const QVariantList& algorithm, const QUrl& filePath)
{
    QString localPath = filePath.toLocalFile();
    if (localPath.isEmpty()) {
        emit errorOccurred("Неверный путь к файлу.");
        return false;
    }

    QFile file(localPath);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text)) {
        qWarning() << "Could not open file for writing:" << localPath;
        emit errorOccurred("Не удалось открыть файл для записи: " + localPath);
        return false;
    }

    QJsonDocument doc = QJsonDocument::fromVariant(QVariant(algorithm));
    file.write(doc.toJson(QJsonDocument::Indented));
    file.close();
    setCurrentFilePath(localPath);
    emit fileSaved(localPath);
    return true;
}

// Загружает алгоритм из файла в формате JSON
QVariantList Obrabotka::loadAlgorithmFromFile(const QUrl& filePath)
{
    QString localPath = filePath.toLocalFile();
    QVariantList result;

    if (localPath.isEmpty()) {
        emit errorOccurred("Неверный путь к файлу.");
        return result;
    }

    QFile file(localPath);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        emit errorOccurred("Не удалось открыть файл для чтения: " + localPath);
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
    emit algorithmLoaded(result);
    return result;
}

// ============================================================================
// РАБОТА С НАСТРОЙКАМИ
// ============================================================================

// Сохраняет настройки приложения в системное хранилище (QSettings)
void Obrabotka::saveSettings(const QVariantMap &settings)
{
    QSettings qSettings;
    for (auto it = settings.constBegin(); it != settings.constEnd(); ++it) {
        qSettings.setValue(it.key(), it.value());
    }
    qSettings.sync();
    qDebug() << "Настройки сохранены с помощью QSettings.";
}

// Загружает настройки приложения из системного хранилища
QVariantMap Obrabotka::loadSettings()
{
    QSettings qSettings;
    QVariantMap loadedSettings;
    QStringList keys = qSettings.allKeys();
    for (const QString &key : keys) {
        loadedSettings[key] = qSettings.value(key);
    }
    qDebug() << "Настройки загружены с помощью QSettings.";
    return loadedSettings;
}

// ============================================================================
// ПРОВЕРКА СИНТАКСИСА АЛГОРИТМА
// ============================================================================

// Проверяет синтаксис всего алгоритма, включая вложенные блоки (ветки условий, тела циклов)
QVariantList Obrabotka::checkAlgorithmSyntax(const QVariantList& algorithm)
{
    QVariantList allErrors;

    for (const QVariant& blockVariant : algorithm) {
        if (!blockVariant.canConvert<QVariantMap>()) {
            addSyntaxError("Некорректный формат блока алгоритма.", -1, allErrors);
            continue;
        }

        QVariantMap block = blockVariant.toMap();
        QString type = block["type"].toString();
        QString content = block["input"].toString();
        int blockId = block["uniqueId"].toInt();

        if (type == "действие") {
            QString trimmedContent = content.trimmed();
            int equalsPos = trimmedContent.indexOf('=');
            if (equalsPos == -1) {
                addSyntaxError("В действии отсутствует оператор присваивания '='.", blockId, allErrors);
            } else {
                QString left = trimmedContent.left(equalsPos).trimmed();
                QString right = trimmedContent.mid(equalsPos + 1).trimmed();
                if (left.isEmpty()) {
                    addSyntaxError("Левая часть присваивания не может быть пустой.", blockId, allErrors);
                }
                if (right.isEmpty()) {
                    addSyntaxError("Правая часть присваивания не может быть пустой.", blockId, allErrors);
                } else {
                    validateExpressionSyntax(right, blockId, allErrors, false);
                }
            }
        } else if (type == "усл" || type == "предусл" || type == "постусл") {
            validateExpressionSyntax(content, blockId, allErrors, true);
        } else if (type == "счетчик") {
            QRegularExpression counterParseRegex(R"(^\s*(\w+)\s*=\s*(.+)\s+(?:to|до)\s+(.+)\s+(?:step|шаг)\s*(.+)\s*$)");
            QRegularExpressionMatch counterMatch = counterParseRegex.match(content);
            if (!counterMatch.hasMatch()) {
                addSyntaxError("Некорректный формат выражения счетчика. Ожидается: 'переменная = начало до конец шаг шаг'", blockId, allErrors);
            } else {
                validateExpressionSyntax(counterMatch.captured(2), blockId, allErrors, false);
                validateExpressionSyntax(counterMatch.captured(3), blockId, allErrors, false);
                validateExpressionSyntax(counterMatch.captured(4), blockId, allErrors, false);
            }
        }

        // Рекурсивная проверка вложенных блоков
        if (block.contains("trueBranch")) {
            QVariantList subBlocks = block["trueBranch"].value<QVariantList>();
            QVariantList subErrors = checkAlgorithmSyntax(subBlocks);
            for (const QVariant& err : subErrors) {
                allErrors.append(err);
            }
        }
        if (block.contains("falseBranch")) {
            QVariantList subBlocks = block["falseBranch"].value<QVariantList>();
            QVariantList subErrors = checkAlgorithmSyntax(subBlocks);
            for (const QVariant& err : subErrors) {
                allErrors.append(err);
            }
        }
        if (block.contains("loopBody")) {
            QVariantList subBlocks = block["loopBody"].value<QVariantList>();
            QVariantList subErrors = checkAlgorithmSyntax(subBlocks);
            for (const QVariant& err : subErrors) {
                allErrors.append(err);
            }
        }
    }

    return allErrors;
}
